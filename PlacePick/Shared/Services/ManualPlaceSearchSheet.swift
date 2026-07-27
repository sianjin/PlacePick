import SwiftUI
import MapKit

/// Manual Apple Maps search, reused from the same search pattern as AddPlaceScreen —
/// the user may always search instead of accepting a suggestion (§ Automation Boundary:
/// automation proposes, the user confirms). Offers two ways to pick a place: typing in
/// the search bar, or tapping a pin directly on the mini-map — mirroring the same choice
/// Photos.app itself offers on its per-photo location map.
///
/// Shared by ReviewGroupsStage (Photo Memory place resolution) and ReplacePlaceScreen
/// (correcting an existing Place's identity) — per PLACE_CREATION.md §8.2 / §7.4:
/// "Do not create a second search implementation."
struct ManualPlaceSearchSheet: View {
    let nearbyCoordinate: CLLocationCoordinate2D?
    let nearbySuggestions: [MKMapItem]
    let onSelect: (MKMapItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = MapSearchService()
    @State private var query = ""
    @State private var errorMessage: String?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @FocusState private var isSearchFieldFocused: Bool

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
                    .focused($isSearchFieldFocused)
                    .onChange(of: query) { _, newValue in
                        searchService.updateQuery(newValue)
                    }

                // Collapsed while the keyboard is up so the search field and results stay
                // visible instead of being pushed off-screen by a tall map plus keyboard.
                if let nearbyCoordinate, !isSearchFieldFocused {
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
                        // Matches NearbyPlaceSearchService's 500m search radius so every
                        // fetched suggestion pin is visible without the user needing to
                        // zoom out first.
                        cameraPosition = .region(
                            MKCoordinateRegion(center: nearbyCoordinate, latitudinalMeters: 600, longitudinalMeters: 600)
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
