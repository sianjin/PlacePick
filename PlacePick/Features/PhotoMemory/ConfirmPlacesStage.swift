import SwiftUI
import MapKit

/// Stage 3 — Confirm Places. For each group, PlacePick suggests a Place; the user accepts
/// or chooses another. Every Memory must be associated with exactly one Place before
/// continuing. See MEMORY_CREATION.md Stage 3 and DATA_MODEL.md §13 "Place Resolution".
struct ConfirmPlacesStage: View {
    @Binding var draft: PhotoImportDraft
    let onContinue: () -> Void

    @State private var suggestionsByGroupID: [UUID: [MKMapItem]] = [:]
    @State private var isSearchingGroupID: UUID?
    @State private var searchTarget: SearchTarget?

    private struct SearchTarget: Identifiable {
        let groupID: UUID
        var id: UUID { groupID }
    }

    private var resolvableGroups: [PhotoImportGroup] {
        draft.proposedGroups.filter { if case .skipped = $0.status { return false }; return true }
    }

    var body: some View {
        List {
            ForEach(resolvableGroups) { group in
                Section {
                    groupRow(group)
                } header: {
                    Text("\(group.photos.count) photo\(group.photos.count == 1 ? "" : "s")")
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Confirm Places")
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
        .sheet(item: $searchTarget) { target in
            ManualPlaceSearchSheet { mapItem in
                resolve(groupID: target.groupID, with: mapItem)
            }
        }
    }

    private var allGroupsResolved: Bool {
        !resolvableGroups.isEmpty && resolvableGroups.allSatisfy {
            if case .resolved = $0.status { return true }
            return false
        }
    }

    @ViewBuilder
    private func groupRow(_ group: PhotoImportGroup) -> some View {
        switch group.status {
        case .resolved(let mapItem):
            HStack {
                Label(mapItem.name ?? "Unnamed Place", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Button("Change") { searchTarget = SearchTarget(groupID: group.id) }
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
    }
}

/// Manual Apple Maps search, reused from the same search pattern as AddPlaceScreen —
/// the user may always search instead of accepting a suggestion (§ Automation Boundary:
/// automation proposes, the user confirms).
private struct ManualPlaceSearchSheet: View {
    let onSelect: (MKMapItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = MapSearchService()
    @State private var query = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search for a place", text: $query)
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
