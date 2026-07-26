import SwiftUI
import SwiftData
import MapKit

/// Stage 2 — Review Groups & Confirm Places. Combines what were three separate screens
/// (Review Memory Groups, Confirm Places, and choosing a Collection) into one: each group
/// shows its own photos, merge/split/remove controls, its place suggestion/search, AND its
/// Collection together. Splitting these across screens meant the user lost sight of which
/// photos/place a group had by the time they were asked to pick its Collection — showing
/// everything together removes that disconnect entirely. See MEMORY_CREATION.md Stage 2/3
/// and DATA_MODEL.md §12.3, §13.
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
    @State private var searchTarget: SearchTarget?
    @State private var collectionPickerGroupID: UUID?
    @State private var draggingPhotoID: String?
    @State private var justResolvedGroupID: UUID?

    private struct SearchTarget: Identifiable {
        let groupID: UUID
        var id: UUID { groupID }
    }

    private struct GroupPickerTarget: Identifiable {
        let groupID: UUID
        var id: UUID { groupID }
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
        List {
            ForEach(resolvableGroups) { group in
                Section {
                    groupHeader(group)
                    photoGrid(for: group)
                    placeResolution(for: group)
                } header: {
                    Text(timeRangeLabel(for: group))
                }
            }
        }
        .listStyle(.plain)
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
            }
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
        .sheet(item: $searchTarget) { target in
            ManualPlaceSearchSheet(
                nearbyCoordinate: draft.proposedGroups.first(where: { $0.id == target.groupID })?.approximateCoordinate,
                nearbySuggestions: suggestionsByGroupID[target.groupID] ?? []
            ) { mapItem in
                resolve(groupID: target.groupID, with: mapItem)
            }
        }
        .sheet(item: Binding(
            get: { collectionPickerGroupID.map { GroupPickerTarget(groupID: $0) } },
            set: { collectionPickerGroupID = $0?.groupID }
        )) { target in
            CollectionPickerSheet(selection: Binding(
                get: { draft.proposedGroups.first(where: { $0.id == target.groupID })?.collection },
                set: { newValue in
                    guard let index = draft.proposedGroups.firstIndex(where: { $0.id == target.groupID }) else { return }
                    draft.proposedGroups[index].collection = newValue
                }
            ))
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
                    .contextMenu {
                        Button("Move to Another Group") {
                            movingPhoto = (photo, group.id)
                            isMoveTargetPickerPresented = true
                        }
                        Button("Remove Photo", role: .destructive) {
                            removePhoto(photo, from: group.id)
                        }
                    }
                    .draggable(photo.id) {
                        PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: "photo")
                            .frame(width: 80, height: 80)
                            .onAppear { draggingPhotoID = photo.id }
                    }
                    .dropDestination(for: String.self) { items, _ in
                        draggingPhotoID = nil
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
                        return true
                    }
            }
        }
    }

    @ViewBuilder
    private func placeResolution(for group: PhotoImportGroup) -> some View {
        switch group.status {
        case .resolved(let mapItem):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(mapItem.name ?? "Unnamed Place", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Change") { searchTarget = SearchTarget(groupID: group.id) }
                        .font(.subheadline)
                }

                Button {
                    guard justResolvedGroupID != group.id else { return }
                    collectionPickerGroupID = group.id
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
                        }
                    }
                } else {
                    Text("No nearby suggestions")
                        .foregroundStyle(.secondary)
                }

                Button("Search for a Place") { searchTarget = SearchTarget(groupID: group.id) }
                    .font(.subheadline)
            }

        case .skipped:
            EmptyView()
        }
    }

    private func timeRangeLabel(for group: PhotoImportGroup) -> String {
        guard let start = group.proposedStartTime, let end = group.proposedEndTime else { return "" }
        if start == end {
            return start.formatted(date: .omitted, time: .shortened)
        }
        return "\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
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
        searchTarget = nil

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

/// Manual Apple Maps search, reused from the same search pattern as AddPlaceScreen —
/// the user may always search instead of accepting a suggestion (§ Automation Boundary:
/// automation proposes, the user confirms). Offers two ways to pick a place: typing in
/// the search bar, or tapping a pin directly on the mini-map — mirroring the same choice
/// Photos.app itself offers on its per-photo location map.
private struct ManualPlaceSearchSheet: View {
    let nearbyCoordinate: CLLocationCoordinate2D?
    let nearbySuggestions: [MKMapItem]
    let onSelect: (MKMapItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = MapSearchService()
    @State private var query = ""
    @State private var errorMessage: String?
    @State private var cameraPosition: MapCameraPosition = .automatic

    /// Landmarks and other large, well-known place categories: when one of these sits
    /// within the minimum pin separation of a smaller nearby POI (e.g. a museum's own gift
    /// shop or café), it should be the one whose pin survives thinning, since it's almost
    /// always the place the user actually means to pick.
    private static let prominentCategories: Set<MKPointOfInterestCategory> = [
        .museum, .nationalPark, .park, .university,
        .airport, .amusementPark, .aquarium, .zoo, .stadium, .theater,
    ]

    private func isProminent(_ item: MKMapItem) -> Bool {
        guard let category = item.pointOfInterestCategory else { return false }
        return Self.prominentCategories.contains(category)
    }

    /// Suggestions that are within ~40m of another suggestion already kept are dropped —
    /// at typical zoom their pins would overlap on screen, making it too easy to tap the
    /// wrong one (especially when the touch that starts a pinch-to-zoom lands near a pin).
    /// Prominent places (museums, landmarks, parks, ...) are considered first so a small
    /// POI inside/next to a landmark never wins the slot instead of the landmark itself.
    private var thinnedSuggestions: [MKMapItem] {
        let minimumSeparationMeters: CLLocationDistance = 40
        let ordered = nearbySuggestions.enumerated().sorted { lhs, rhs in
            let lhsProminent = isProminent(lhs.element)
            let rhsProminent = isProminent(rhs.element)
            if lhsProminent != rhsProminent { return lhsProminent }
            return lhs.offset < rhs.offset
        }.map(\.element)

        var kept: [MKMapItem] = []
        for item in ordered {
            let tooClose = kept.contains { existing in
                CLLocation(latitude: existing.placemark.coordinate.latitude, longitude: existing.placemark.coordinate.longitude)
                    .distance(from: CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude))
                    < minimumSeparationMeters
            }
            if !tooClose { kept.append(item) }
        }
        return kept
    }

    @MapContentBuilder
    private func placePin(for item: MKMapItem, isProminent: Bool) -> some MapContent {
        Annotation(item.name ?? "Place", coordinate: item.placemark.coordinate) {
            Button {
                onSelect(item)
            } label: {
                Image(systemName: isProminent ? "star.circle.fill" : "mappin.circle.fill")
                    .font(isProminent ? .largeTitle : .title)
                    .foregroundStyle(.white, isProminent ? Color.orange : Color.accentColor)
                    .background(Circle().fill(.white).padding(isProminent ? 4 : 3))
            }
            .contentShape(Circle())
            .frame(width: isProminent ? 56 : 44, height: isProminent ? 56 : 44)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search for a place", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: query) { _, newValue in
                        searchService.updateQuery(newValue)
                    }

                if let nearbyCoordinate {
                    Map(position: $cameraPosition) {
                        // Ordinary pins draw first, prominent ones (museums, landmarks, ...)
                        // draw last/on top so a landmark's pin is never hidden behind a
                        // smaller nearby POI's pin.
                        ForEach(thinnedSuggestions.filter { !isProminent($0) }, id: \.self) { item in
                            placePin(for: item, isProminent: false)
                        }
                        ForEach(thinnedSuggestions.filter { isProminent($0) }, id: \.self) { item in
                            placePin(for: item, isProminent: true)
                        }
                    }
                    .frame(height: 360)
                    .onAppear {
                        cameraPosition = .region(
                            MKCoordinateRegion(center: nearbyCoordinate, latitudinalMeters: 400, longitudinalMeters: 400)
                        )
                        searchService.updateRegion(around: nearbyCoordinate)
                    }

                    Text("Tap a pin on the map, or search below")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                List(searchService.completions, id: \.self) { completion in
                    Button {
                        Task { await resolve(completion) }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(completion.title).foregroundStyle(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("We couldn't find that place", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: { Text(errorMessage ?? "") })
        }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        do {
            let mapItem = try await searchService.resolve(completion)
            onSelect(mapItem)
        } catch {
            errorMessage = "Try another search."
        }
    }
}
