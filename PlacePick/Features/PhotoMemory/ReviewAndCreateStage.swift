import SwiftUI
import SwiftData
import MapKit
import StoreKit

/// Stage 4 (Review) and Stage 5 (Create). Nothing is saved until the user taps Create —
/// see MEMORY_CREATION.md Stage 4/5. Each resolved group becomes one Visit; Places are
/// created or matched to existing ones exactly like manual Capture (createPlace dedups by
/// Apple Maps identifier, per DATA_MODEL.md §17.1). Place is chosen back in Stage 2
/// (ReviewGroupsStage); Collection can still be corrected here, since realizing "wrong
/// Collection" is often only obvious once everything is laid out together at Review.
struct ReviewAndCreateStage: View {
    @Binding var draft: PhotoImportDraft
    let onCreated: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var collectionPickerGroupID: UUID?

    private struct GroupPickerTarget: Identifiable {
        let groupID: UUID
        var id: UUID { groupID }
    }

    private var resolvedGroups: [PhotoImportGroup] {
        draft.proposedGroups.compactMap { group in
            if case .resolved = group.status { return group }
            return nil
        }
    }

    var body: some View {
        List {
            ForEach(resolvedGroups) { group in
                if case .resolved(let mapItem) = group.status {
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(mapItem.name ?? "Unnamed Place")
                                    .font(.headline)
                                Text("\(group.photos.count) photo\(group.photos.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let start = group.proposedStartTime {
                                Text(start, format: .dateTime.month(.abbreviated).day())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
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
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
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
        .safeAreaInset(edge: .bottom) {
            Button {
                createMemories()
            } label: {
                if isCreating {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isCreating || resolvedGroups.isEmpty)
            .padding()
            .background(.bar)
        }
        .alert("Some Memories couldn't be saved", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: { Text(errorMessage ?? "") })
    }

    /// Stage 5 — Create. Reuses the same Place resolution and dedup rules as manual
    /// Capture. Each group's own chosen Collection is used for its Place — createPlace
    /// only applies it when the Place is newly created; an existing matched Place keeps
    /// its current Collection untouched.
    private func createMemories() {
        isCreating = true
        let placeRepository = PlaceRepository(modelContext: modelContext)
        let placeCreationService = PlaceCreationService(repository: placeRepository)
        let visitRepository = VisitRepository(modelContext: modelContext)

        var failureCount = 0

        for group in resolvedGroups {
            guard case .resolved(let mapItem) = group.status,
                  let collection = group.collection else { continue }

            do {
                let result = try placeCreationService.createPlace(
                    from: mapItem,
                    relationship: PlaceRelationshipDraft(collection: collection)
                )
                let place: Place
                switch result {
                case .created(let created): place = created
                case .existing(let existing): place = existing
                }

                let visit = Visit(
                    place: place,
                    startedAt: group.proposedStartTime ?? .now,
                    endedAt: group.proposedEndTime ?? .now
                )
                modelContext.insert(visit)

                for (index, photo) in group.photos.enumerated() {
                    // storedImageReference mirrors localAssetIdentifier: PlacePick never
                    // copies photo bytes into its own storage, so there is no separate
                    // managed file to reference — display always looks up the asset from
                    // Photos directly (see PhotoAssetThumbnailView).
                    let visitPhoto = VisitPhoto(
                        visit: visit,
                        localAssetIdentifier: photo.localAssetIdentifier,
                        storedImageReference: photo.localAssetIdentifier,
                        capturedAt: photo.capturedAt,
                        latitude: photo.latitude,
                        longitude: photo.longitude,
                        sortOrder: index
                    )
                    modelContext.insert(visitPhoto)
                }
            } catch {
                failureCount += 1
            }
        }

        visitRepository.save()
        isCreating = false

        if failureCount > 0 {
            errorMessage = "\(failureCount) group\(failureCount == 1 ? "" : "s") couldn't be resolved to a Place."
        }
        if failureCount < resolvedGroups.count {
            Haptics.success()
            if ReviewRequestTrigger.recordSuccessfulSaveAndShouldRequestReview() {
                requestReview()
            }
            onCreated()
        }
    }
}
