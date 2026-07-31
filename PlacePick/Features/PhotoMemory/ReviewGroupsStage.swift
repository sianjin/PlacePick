import SwiftUI
import SwiftData
import MapKit
import PhotosUI

/// Stage 2 — Review Groups & Confirm Places. Combines what were three separate screens
/// (Review Memory Groups, Confirm Places, and choosing a Collection) into one: each group
/// shows its own photos, merge/split/remove controls, its place suggestion/search, AND its
/// Collection together. Splitting these across screens meant the user lost sight of which
/// photos/place a group had by the time they were asked to pick its Collection — showing
/// everything together removes that disconnect entirely. See MEMORY_CREATION.md Stage 2
/// (which folded in the former separate Confirm Places stage) and DATA_MODEL.md §12.3, §13.
struct ReviewGroupsStage: View {
    @Binding var draft: PhotoImportDraft
    let onContinue: () -> Void

    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]

    @State private var isMoveTargetPickerPresented = false
    @State private var movingPhoto: (photo: PhotoImportCandidate, from: UUID)?
    @State private var mergeSourceGroupID: UUID?
    @State private var isMergeTargetPickerPresented = false
    @State private var suggestionsByGroupID: [UUID: [MKMapItem]] = [:]
    @State private var isSearchingGroupID: UUID?
    @State private var activeSheet: ActiveSheet?
    @State private var draggingPhotoID: String?
    @State private var targetedPhotoID: String?
    @State private var justResolvedGroupID: UUID?
    @State private var timeZoneByGroupID: [UUID: TimeZone] = [:]
    @State private var addPhotosGroupID: UUID?
    @State private var addPhotosTargetGroupID: UUID?
    @State private var addPhotosSelection: [PhotosPickerItem] = []
    @State private var isLoadingAddedPhotos = false

    /// Place search and Collection picking are two different sheets that can both be
    /// triggered from the same group row. Two independent `.sheet(item:)` modifiers on one
    /// view is a known SwiftUI footgun — presentation/dismissal timing between them isn't
    /// reliable, which was causing the Collection sheet to auto-open right after a place
    /// was resolved via the search sheet. A single sheet with one Identifiable enum removes
    /// the ambiguity entirely.
    private enum ActiveSheet: Identifiable {
        case search(groupID: UUID)
        case collection(groupID: UUID)

        var id: String {
            switch self {
            case .search(let groupID): "search-\(groupID)"
            case .collection(let groupID): "collection-\(groupID)"
            }
        }
    }

    private var resolvableGroups: [PhotoImportGroup] {
        draft.proposedGroups.filter { if case .skipped = $0.status { return false }; return true }
    }

    private var allGroupsResolved: Bool {
        !resolvableGroups.isEmpty && resolvableGroups.allSatisfy {
            guard case .resolved = $0.status else { return false }
            return $0.collection != nil
        }
    }

    var body: some View {
        // A plain List here silently breaks drag-to-reorder: SwiftUI's .dropDestination
        // inside a List's row/section content never fires on iOS (Apple Feedback
        // FB12980427 — the drag starts but the drop is swallowed). ScrollView + LazyVStack
        // avoids the conflict entirely, same as MemoryDetailScreen's ReorderPhotosSheet,
        // which uses the identical drag mechanism successfully outside of a List.
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(resolvableGroups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(timeRangeLabel(for: group))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        groupHeader(group)
                        photoGrid(for: group)
                        placeResolution(for: group)
                    }
                    Divider()
                }
            }
            .padding()
        }
        .navigationTitle("New Memory")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Continue") { onContinue() }
                    .disabled(!allGroupsResolved)
            }
        }
        .task {
            for group in draft.proposedGroups {
                await loadSuggestions(for: group)
                await loadTimeZone(for: group)
            }
        }
        .photosPicker(
            isPresented: Binding(
                get: { addPhotosGroupID != nil },
                set: { if !$0 { addPhotosGroupID = nil } }
            ),
            selection: $addPhotosSelection,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: addPhotosSelection) { _, newValue in
            guard !newValue.isEmpty, let groupID = addPhotosTargetGroupID else { return }
            Task { await addPhotos(newValue, to: groupID) }
        }
        .confirmationDialog(
            "Move Photo To",
            isPresented: $isMoveTargetPickerPresented,
            titleVisibility: .visible
        ) {
            ForEach(draft.proposedGroups) { target in
                if target.id != movingPhoto?.from {
                    Button(timeRangeLabel(for: target)) {
                        movePhoto(to: target.id)
                    }
                }
            }
            Button("New Group") { movePhoto(to: nil) }
            Button("Cancel", role: .cancel) { movingPhoto = nil }
        }
        .confirmationDialog(
            "Merge Into",
            isPresented: $isMergeTargetPickerPresented,
            titleVisibility: .visible
        ) {
            ForEach(draft.proposedGroups) { target in
                if target.id != mergeSourceGroupID {
                    Button(timeRangeLabel(for: target)) {
                        merge(mergeSourceGroupID, into: target.id)
                    }
                }
            }
            Button("Cancel", role: .cancel) { mergeSourceGroupID = nil }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .search(let groupID):
                ManualPlaceSearchSheet(
                    nearbyCoordinate: draft.proposedGroups.first(where: { $0.id == groupID })?.approximateCoordinate,
                    nearbySuggestions: suggestionsByGroupID[groupID] ?? []
                ) { mapItem in
                    resolve(groupID: groupID, with: mapItem)
                }
            case .collection(let groupID):
                CollectionPickerSheet(selection: Binding(
                    get: { draft.proposedGroups.first(where: { $0.id == groupID })?.collection },
                    set: { newValue in
                        guard let index = draft.proposedGroups.firstIndex(where: { $0.id == groupID }) else { return }
                        draft.proposedGroups[index].collection = newValue
                    }
                ))
            }
        }
        .onAppear {
            guard let firstCollection = collections.first else { return }
            for index in draft.proposedGroups.indices where draft.proposedGroups[index].collection == nil {
                draft.proposedGroups[index].collection = firstCollection
            }
        }
    }

    private func groupHeader(_ group: PhotoImportGroup) -> some View {
        HStack {
            Text("\(group.photos.count) photo\(group.photos.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Menu {
                if draft.proposedGroups.count > 1 {
                    Button("Merge Into…") {
                        mergeSourceGroupID = group.id
                        isMergeTargetPickerPresented = true
                    }
                }
                if group.photos.count > 1 {
                    Button("Split Group") { split(group) }
                }
                Button("Remove Group", role: .destructive) { remove(group) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    /// The first photo becomes the group's (and later the Visit's) cover photo — see
    /// PlaceDetailSheet.coverPhoto, which is simply the first Photo by sortOrder — so
    /// dragging a photo to the front here is how the user picks the cover before the
    /// Visit even exists, the same gesture as MemoryDetailScreen's ReorderPhotosSheet.
    private func photoGrid(for group: PhotoImportGroup) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
            ForEach(group.photos) { photo in
                PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: "photo")
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(alignment: .topLeading) {
                        if photo.id == group.photos.first?.id, group.photos.count > 1 {
                            Text("Cover")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.black.opacity(0.6), in: Capsule())
                                .foregroundStyle(.white)
                                .padding(4)
                        }
                    }
                    .opacity(draggingPhotoID == photo.id ? 0.5 : 1)
                    .scaleEffect(targetedPhotoID == photo.id ? 1.05 : 1)
                    .overlay {
                        if targetedPhotoID == photo.id {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.accentColor, lineWidth: 3)
                        }
                    }
                    .animation(.easeOut(duration: 0.15), value: targetedPhotoID)
                    .contextMenu {
                        Button("Move to Another Group") {
                            movingPhoto = (photo, group.id)
                            isMoveTargetPickerPresented = true
                        }
                        Button("Remove Photo", role: .destructive) {
                            removePhoto(photo, from: group.id)
                        }
                    }
                    // Each cell needs a distinct identity for .draggable's preview to reflect
                    // the actual photo under the finger — without it, SwiftUI can reuse/
                    // conflate cells that share the same view structure, making every drag
                    // preview show whichever photo happened to render first (the cover).
                    .id(photo.id)
                    .draggable(photo.id) {
                        PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: "photo")
                            .frame(width: 80, height: 80)
                            .id(photo.id)
                            .onAppear { draggingPhotoID = photo.id }
                    }
                    // isTargeted suppresses SwiftUI's default drop-target chrome (a green
                    // "+" and placeholder square, which reads as "insert a new photo" —
                    // misleading since reordering never adds one); a highlight on the
                    // existing thumbnail communicates "swap position" instead.
                    .dropDestination(for: String.self) { items, _ in
                        draggingPhotoID = nil
                        targetedPhotoID = nil
                        guard let draggedID = items.first,
                              let groupIndex = draft.proposedGroups.firstIndex(where: { $0.id == group.id }),
                              let sourceIndex = draft.proposedGroups[groupIndex].photos.firstIndex(where: { $0.id == draggedID }),
                              let destinationIndex = draft.proposedGroups[groupIndex].photos.firstIndex(where: { $0.id == photo.id }) else { return false }
                        withAnimation {
                            draft.proposedGroups[groupIndex].photos.move(
                                fromOffsets: IndexSet(integer: sourceIndex),
                                toOffset: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex
                            )
                        }
                        Haptics.selection()
                        return true
                    } isTargeted: { isTargeted in
                        targetedPhotoID = isTargeted ? photo.id : nil
                    }
            }

            Button {
                addPhotosTargetGroupID = group.id
                addPhotosGroupID = group.id
            } label: {
                if isLoadingAddedPhotos && addPhotosGroupID == group.id {
                    ProgressView()
                        .aspectRatio(1, contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "plus")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .disabled(isLoadingAddedPhotos)
        }
    }

    private func addPhotos(_ items: [PhotosPickerItem], to groupID: UUID) async {
        isLoadingAddedPhotos = true
        defer {
            isLoadingAddedPhotos = false
            addPhotosSelection = []
            addPhotosGroupID = nil
            addPhotosTargetGroupID = nil
        }

        let candidates = await PhotoLibraryService.loadCandidates(for: items)
        guard !candidates.isEmpty, let index = draft.proposedGroups.firstIndex(where: { $0.id == groupID }) else { return }

        let existingIDs = Set(draft.proposedGroups[index].photos.map(\.id))
        let newCandidates = candidates.filter { !existingIDs.contains($0.id) }
        guard !newCandidates.isEmpty else { return }

        draft.proposedGroups[index].photos.append(contentsOf: newCandidates)
        draft.proposedGroups[index].photos.sort { $0.capturedAt < $1.capturedAt }
        sortGroups()

        // New photos can shift the group's time range and approximate coordinate — refresh
        // suggestions/time zone so they reflect the widened group, same as initial load.
        if let refreshed = draft.proposedGroups.first(where: { $0.id == groupID }) {
            await loadSuggestions(for: refreshed)
            await loadTimeZone(for: refreshed)
        }
    }

    @ViewBuilder
    private func placeResolution(for group: PhotoImportGroup) -> some View {
        switch group.status {
        case .resolved(let mapItem):
            // Multiple plain Buttons sharing one List row need .buttonStyle(.plain) — without
            // it, List's default row-level tap handling can route a tap meant for one button
            // (e.g. "Change") to a sibling button in the same row (e.g. the Collection button).
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Label(mapItem.name ?? "Unnamed Place", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Change") { activeSheet = .search(groupID: group.id) }
                        .font(.subheadline)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                }

                Button {
                    guard justResolvedGroupID != group.id else { return }
                    activeSheet = .collection(groupID: group.id)
                } label: {
                    if let collection = group.collection {
                        Label(collection.name, systemImage: collection.icon)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Choose a Collection")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
            }

        case .unresolved:
            VStack(alignment: .leading, spacing: 8) {
                if isSearchingGroupID == group.id {
                    ProgressView().frame(maxWidth: .infinity)
                } else if let suggestions = suggestionsByGroupID[group.id], !suggestions.isEmpty {
                    ForEach(Array(suggestions.prefix(3)), id: \.self) { suggestion in
                        Button {
                            resolve(groupID: group.id, with: suggestion)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(suggestion.name ?? "Unnamed Place")
                                    .foregroundStyle(.primary)
                                if let locality = suggestion.placemark.locality {
                                    Text(locality)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            // Reserves a fixed, predictable tap region per suggestion and
                            // extends it to the label's full bounds (not just the glyph runs),
                            // so a tight stack of short-label buttons can't bleed hit-testing
                            // into a neighboring sibling button.
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("No nearby suggestions")
                        .foregroundStyle(.secondary)
                }

                Button("Search for a Place") { activeSheet = .search(groupID: group.id) }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
            }

        case .skipped:
            EmptyView()
        }
    }

    private func timeRangeLabel(for group: PhotoImportGroup) -> String {
        guard let start = group.proposedStartTime, let end = group.proposedEndTime else { return "" }
        let timeZone = timeZoneByGroupID[group.id] ?? .current
        let style = Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone)
        if start == end {
            return start.formatted(style)
        }
        return "\(start.formatted(style)) – \(end.formatted(style))"
    }

    private func merge(_ sourceID: UUID?, into targetID: UUID) {
        defer { mergeSourceGroupID = nil }
        guard let sourceID,
              let source = draft.proposedGroups.first(where: { $0.id == sourceID }),
              let targetIndex = draft.proposedGroups.firstIndex(where: { $0.id == targetID }) else { return }

        let mergedPhotos = (draft.proposedGroups[targetIndex].photos + source.photos).sorted { $0.capturedAt < $1.capturedAt }
        draft.proposedGroups[targetIndex].photos = mergedPhotos
        draft.proposedGroups.removeAll { $0.id == sourceID }
        sortGroups()
    }

    /// Splits a group at its temporal midpoint — a reasonable default the user can further
    /// adjust by moving individual photos afterward.
    private func split(_ group: PhotoImportGroup) {
        guard group.photos.count > 1 else { return }
        let sorted = group.photos.sorted { $0.capturedAt < $1.capturedAt }
        let midpoint = sorted.count / 2
        let first = PhotoImportGroup(photos: Array(sorted[..<midpoint]))
        let second = PhotoImportGroup(photos: Array(sorted[midpoint...]))

        guard let index = draft.proposedGroups.firstIndex(where: { $0.id == group.id }) else { return }
        draft.proposedGroups.remove(at: index)
        draft.proposedGroups.insert(contentsOf: [first, second], at: index)
        sortGroups()
    }

    private func remove(_ group: PhotoImportGroup) {
        draft.proposedGroups.removeAll { $0.id == group.id }
    }

    private func removePhoto(_ photo: PhotoImportCandidate, from groupID: UUID) {
        guard let index = draft.proposedGroups.firstIndex(where: { $0.id == groupID }) else { return }
        draft.proposedGroups[index].photos.removeAll { $0.id == photo.id }
        if draft.proposedGroups[index].photos.isEmpty {
            draft.proposedGroups.remove(at: index)
        }
    }

    private func movePhoto(to targetGroupID: UUID?) {
        defer { movingPhoto = nil }
        guard let movingPhoto else { return }

        guard let sourceIndex = draft.proposedGroups.firstIndex(where: { $0.id == movingPhoto.from }) else { return }
        draft.proposedGroups[sourceIndex].photos.removeAll { $0.id == movingPhoto.photo.id }
        let sourceEmptied = draft.proposedGroups[sourceIndex].photos.isEmpty

        if let targetGroupID, let targetIndex = draft.proposedGroups.firstIndex(where: { $0.id == targetGroupID }) {
            draft.proposedGroups[targetIndex].photos.append(movingPhoto.photo)
            draft.proposedGroups[targetIndex].photos.sort { $0.capturedAt < $1.capturedAt }
        } else {
            draft.proposedGroups.append(PhotoImportGroup(photos: [movingPhoto.photo]))
        }

        if sourceEmptied {
            draft.proposedGroups.removeAll { $0.id == movingPhoto.from }
        }
        sortGroups()
    }

    private func sortGroups() {
        draft.proposedGroups.sort { (($0.proposedStartTime ?? .distantPast)) < (($1.proposedStartTime ?? .distantPast)) }
    }

    /// Resolves the IANA time zone at the group's photo location so timeRangeLabel can show
    /// the true local time the photos were taken (e.g. NYC time), not this device's current
    /// time zone — same reasoning as PlaceTimeZoneResolver's other call sites.
    private func loadTimeZone(for group: PhotoImportGroup) async {
        guard let coordinate = group.approximateCoordinate else { return }
        if let cached = PlaceTimeZoneResolver.cached(for: coordinate) {
            timeZoneByGroupID[group.id] = cached
            return
        }
        timeZoneByGroupID[group.id] = await PlaceTimeZoneResolver.resolve(for: coordinate)
    }

    private func loadSuggestions(for group: PhotoImportGroup) async {
        guard case .unresolved = group.status, let coordinate = group.approximateCoordinate else { return }
        isSearchingGroupID = group.id
        let results = await NearbyPlaceSearchService.nearbyPlaces(around: coordinate)
        suggestionsByGroupID[group.id] = results
        if isSearchingGroupID == group.id {
            isSearchingGroupID = nil
        }
    }

    private func resolve(groupID: UUID, with mapItem: MKMapItem) {
        guard let index = draft.proposedGroups.firstIndex(where: { $0.id == groupID }) else { return }
        draft.proposedGroups[index].status = .resolved(mapItem)
        activeSheet = nil

        // Guards against a stray tap immediately opening the Collection picker the instant
        // it appears in the newly-resolved row, right under where the finger just tapped
        // a map pin or suggestion to resolve the place.
        justResolvedGroupID = groupID
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            if justResolvedGroupID == groupID {
                justResolvedGroupID = nil
            }
        }
    }
}
