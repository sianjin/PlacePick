import SwiftUI
import SwiftData

/// Receiving side of Place sharing for a Place that is not already saved. See MVP.md §10.1
/// "Receiving a New Place" — identity is already resolved by the sender, so this skips
/// straight to Collection selection rather than MapKit search. Only Collection is required;
/// Favorite, Emotion, Note, and Memory Photo always start blank — the sender's personal
/// memory is never copied. Callers must check §10.2 (already saved → open existing Place)
/// before presenting this sheet; it assumes the Place is new.
struct ReceivePlaceSheet: View {
    let identity: SharedPlaceIdentity
    let onFinished: (Place) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]

    @State private var selectedCollection: PlaceCollection?
    @State private var isPresentingCollectionPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(identity.name)
                        .font(.title3.weight(.semibold))
                }

                Section("Collection") {
                    Button {
                        isPresentingCollectionPicker = true
                    } label: {
                        if let selectedCollection {
                            Label(selectedCollection.name, systemImage: selectedCollection.icon)
                                .foregroundStyle(.primary)
                        } else {
                            Text("Choose a Collection")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Save Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedCollection == nil)
                }
            }
            .sheet(isPresented: $isPresentingCollectionPicker) {
                CollectionPickerSheet(selection: $selectedCollection)
            }
            .onAppear {
                if selectedCollection == nil {
                    selectedCollection = collections.first
                }
            }
        }
    }

    private func save() {
        guard let selectedCollection else { return }
        let service = PlaceCreationService(repository: PlaceRepository(modelContext: modelContext))
        let result = service.createPlace(from: identity, collection: selectedCollection)

        switch result {
        case .created(let place), .existing(let place):
            dismiss()
            onFinished(place)
        }
    }
}
