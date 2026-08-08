import SwiftUI
import SwiftData

/// Receiving side of Collection sharing. See MVP.md §11.5 "Existing Collection Choice" —
/// MomentMap never guesses that two Collections are equivalent; the user always chooses
/// explicitly between creating a new Collection or merging into one they picked themselves.
struct ReceiveCollectionSheet: View {
    let snapshot: SharedCollectionSnapshot
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]

    @State private var mergeDestination: PlaceCollection?
    @State private var isPresentingMergePicker = false
    @State private var result: CollectionImportResult?

    var body: some View {
        NavigationStack {
            if let result {
                summary(for: result)
            } else {
                choices
            }
        }
    }

    private var choices: some View {
        Form {
            Section {
                Label(snapshot.suggestedName, systemImage: snapshot.suggestedIcon)
                    .font(.title3.weight(.semibold))
                Text("\(snapshot.places.count) place\(snapshot.places.count == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Import as New Collection") {
                    let service = makeImportService()
                    result = service.importAsNewCollection(snapshot)
                }
            }

            Section {
                Button {
                    isPresentingMergePicker = true
                } label: {
                    if let mergeDestination {
                        Label("Merge into \(mergeDestination.name)", systemImage: mergeDestination.icon)
                    } else {
                        Text("Merge into Existing Collection")
                    }
                }
            }
        }
        .navigationTitle("Import Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .sheet(isPresented: $isPresentingMergePicker) {
            CollectionPickerSheet(selection: $mergeDestination)
                .onDisappear {
                    guard let mergeDestination else { return }
                    let service = makeImportService()
                    result = service.mergeIntoExistingCollection(snapshot, destination: mergeDestination)
                }
        }
    }

    /// Matches the exact summary format from MVP.md §11.4: "12 new Places added / 3 already
    /// saved" — fewer Places than the sender's Collection is expected, not an error.
    private func summary(for result: CollectionImportResult) -> some View {
        VStack(spacing: 16) {
            Image(systemName: result.collection.icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)

            Text(result.collection.name)
                .font(.title2.weight(.semibold))

            VStack(spacing: 4) {
                Text("\(result.newPlaceCount) new place\(result.newPlaceCount == 1 ? "" : "s") added")
                if result.alreadySavedCount > 0 {
                    Text("\(result.alreadySavedCount) already saved")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.body)

            Button("Done") {
                dismiss()
                onFinished()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func makeImportService() -> CollectionImportService {
        CollectionImportService(
            placeCreationService: PlaceCreationService(repository: PlaceRepository(modelContext: modelContext)),
            collectionRepository: CollectionRepository(modelContext: modelContext)
        )
    }
}
