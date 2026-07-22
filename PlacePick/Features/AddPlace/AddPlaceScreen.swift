import SwiftUI
import SwiftData
import MapKit

struct AddPlaceScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchService = MapSearchService()
    @State private var query: String = ""
    @State private var selectedMapItem: MKMapItem?
    @State private var existingPlace: Place?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let selectedMapItem {
                    PersonalInfoForm(
                        mapItem: selectedMapItem,
                        onCancel: { self.selectedMapItem = nil },
                        onSave: { draft in save(mapItem: selectedMapItem, relationship: draft) }
                    )
                } else {
                    searchList
                }
            }
            .navigationTitle("Add Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("We couldn't save that place", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
            .sheet(item: $existingPlace) { place in
                PlaceDetailSheet(place: place)
            }
        }
    }

    private var searchList: some View {
        VStack(spacing: 0) {
            TextField("Search for a place", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: query) { _, newValue in
                    searchService.updateQuery(newValue)
                }

            if query.isEmpty {
                ContentUnavailableView(
                    "Find a place",
                    systemImage: "magnifyingglass",
                    description: Text("Search by name, address, or landmark.")
                )
            } else if searchService.completions.isEmpty {
                ContentUnavailableView(
                    "No results",
                    systemImage: "mappin.slash",
                    description: Text("Try another search.")
                )
            } else {
                List(searchService.completions, id: \.self) { completion in
                    Button {
                        Task { await resolve(completion) }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(completion.title)
                                .foregroundStyle(.primary)
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
        }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        do {
            selectedMapItem = try await searchService.resolve(completion)
        } catch {
            errorMessage = "We couldn't find that place. Try another search."
        }
    }

    private func save(mapItem: MKMapItem, relationship: PlaceRelationshipDraft) {
        let repository = PlaceRepository(modelContext: modelContext)
        let creationService = PlaceCreationService(repository: repository)

        do {
            let result = try creationService.createPlace(from: mapItem, relationship: relationship)
            switch result {
            case .created:
                dismiss()
            case .existing(let place):
                existingPlace = place
            }
        } catch {
            errorMessage = "We couldn't save that place. Try another search."
        }
    }
}
