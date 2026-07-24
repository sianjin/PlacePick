import SwiftUI

/// Stage 2 — Review Memory Groups. Groups remain temporary until confirmed; the user may
/// merge, split, move photos, or remove photos. See MEMORY_CREATION.md Stage 2.
struct ReviewGroupsStage: View {
    @Binding var draft: PhotoImportDraft
    let onContinue: () -> Void

    @State private var selectedGroupIDs: Set<UUID> = []
    @State private var isMoveTargetPickerPresented = false
    @State private var movingPhoto: (photo: PhotoImportCandidate, from: UUID)?

    var body: some View {
        List {
            ForEach(draft.proposedGroups) { group in
                Section {
                    groupHeader(group)
                    photoGrid(for: group)
                } header: {
                    HStack {
                        Text(timeRangeLabel(for: group))
                        Spacer()
                        if selectedGroupIDs.contains(group.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Continue") { onContinue() }
                    .disabled(draft.proposedGroups.isEmpty)
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
    }

    private func groupHeader(_ group: PhotoImportGroup) -> some View {
        HStack {
            Text("\(group.photos.count) photo\(group.photos.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                toggleSelection(group.id)
            } label: {
                Text(selectedGroupIDs.contains(group.id) ? "Deselect" : "Select")
                    .font(.subheadline)
            }

            if selectedGroupIDs.count == 2, selectedGroupIDs.contains(group.id) {
                Button("Merge") { mergeSelectedGroups() }
                    .font(.subheadline.weight(.semibold))
            }

            Menu {
                if group.photos.count > 1 {
                    Button("Split Group") { split(group) }
                }
                Button("Remove Group", role: .destructive) { remove(group) }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func photoGrid(for group: PhotoImportGroup) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 6) {
            ForEach(group.photos) { photo in
                PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: "photo")
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contextMenu {
                        Button("Move to Another Group") {
                            movingPhoto = (photo, group.id)
                            isMoveTargetPickerPresented = true
                        }
                        Button("Remove Photo", role: .destructive) {
                            removePhoto(photo, from: group.id)
                        }
                    }
            }
        }
    }

    private func timeRangeLabel(for group: PhotoImportGroup) -> String {
        guard let start = group.proposedStartTime, let end = group.proposedEndTime else { return "" }
        if start == end {
            return start.formatted(date: .omitted, time: .shortened)
        }
        return "\(start.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
    }

    private func toggleSelection(_ id: UUID) {
        if selectedGroupIDs.contains(id) {
            selectedGroupIDs.remove(id)
        } else {
            if selectedGroupIDs.count >= 2 {
                selectedGroupIDs.removeAll()
            }
            selectedGroupIDs.insert(id)
        }
    }

    private func mergeSelectedGroups() {
        let targets = draft.proposedGroups.filter { selectedGroupIDs.contains($0.id) }
        guard targets.count == 2 else { return }

        let mergedPhotos = (targets[0].photos + targets[1].photos).sorted { $0.capturedAt < $1.capturedAt }
        let merged = PhotoImportGroup(photos: mergedPhotos)

        draft.proposedGroups.removeAll { selectedGroupIDs.contains($0.id) }
        draft.proposedGroups.append(merged)
        sortGroups()
        selectedGroupIDs.removeAll()
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
        selectedGroupIDs.remove(group.id)
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
}
