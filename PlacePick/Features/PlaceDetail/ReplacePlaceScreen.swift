import SwiftUI
import SwiftData
import MapKit

/// Reuses the same MapKit search experience as Add Place, per PLACE_CREATION.md §8.2 / §7.4:
/// "Do not create a second search implementation."
struct ReplacePlaceScreen: View {
    let place: Place
    /// Called with the pre-existing target Place if the new selection already belongs to
    /// another saved Place, or nil once the flow is dismissed with no replacement conflict.
    let onFinished: (Place?) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchService = MapSearchService()
    @State private var query: String = ""
    @State private var pendingMapItem: MKMapItem?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search for the correct place", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onChange(of: query) { _, newValue in
                        searchService.updateQuery(newValue)
                    }

                List(searchService.completions, id: \.self) { completion in
                    Button {
                        Task { await resolve(completion) }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(completion.title).foregroundStyle(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Replace Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onFinished(nil) }
                }
            }
            .confirmationDialog(
                confirmationTitle,
                isPresented: Binding(
                    get: { pendingMapItem != nil },
                    set: { if !$0 { pendingMapItem = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Replace") { confirmReplace() }
                Button("Cancel", role: .cancel) { pendingMapItem = nil }
            } message: {
                Text("Your note, emotion, favorite, and memory photo will be kept.")
            }
            .alert("We couldn't replace this place", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
        }
    }

    private var confirmationTitle: String {
        "Replace this place with \"\(pendingMapItem?.name ?? "")\"?"
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        do {
            pendingMapItem = try await searchService.resolve(completion)
        } catch {
            errorMessage = "We couldn't find that place. Try another search."
        }
    }

    private func confirmReplace() {
        guard let mapItem = pendingMapItem else { return }
        let repository = PlaceRepository(modelContext: modelContext)
        let creationService = PlaceCreationService(repository: repository)

        do {
            let result = try creationService.replaceIdentity(for: place, with: mapItem)
            switch result {
            case .replaced:
                onFinished(nil)
            case .existingTarget(let existing):
                onFinished(existing)
            }
        } catch {
            errorMessage = "We couldn't resolve that place. Try another search."
        }
    }
}
