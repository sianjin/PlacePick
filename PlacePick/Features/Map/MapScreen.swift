import SwiftUI
import SwiftData
import MapKit

struct MapScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [Place]
    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]

    @StateObject private var locationAuthorization = LocationAuthorizationService()
    @EnvironmentObject private var pendingImportCoordinator: PendingImportCoordinator

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCollection: PlaceCollection?
    @State private var selectedPlace: Place?
    @State private var isPresentingAddPlace = false
    @State private var isPresentingManageCollections = false
    @State private var addPlaceInitialQuery = ""

    private let recommendationEngine: RecommendationEngine = DefaultRecommendationEngine()
    private let lastViewport = LastViewportStore()

    private var visiblePlaces: [Place] {
        let active = places.filter { $0.deletedAt == nil }
        guard let selectedCollection else { return active }
        return active.filter { $0.collection.id == selectedCollection.id }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $selectedPlace) {
                ForEach(visiblePlaces) { place in
                    Annotation(place.name, coordinate: place.coordinate) {
                        PlaceMapMarker(
                            place: place,
                            importance: recommendationEngine.importance(for: place, now: .now)
                        )
                        .onTapGesture { selectedPlace = place }
                    }
                    .tag(place)
                }
                UserAnnotation()
            }
            .mapControls {
                MapCompass()
            }
            .ignoresSafeArea(edges: .top)
            .onMapCameraChange(frequency: .onEnd) { context in
                lastViewport.save(context.region)
            }

            CollectionBar(
                collections: collections,
                selectedCollection: $selectedCollection,
                onManage: { isPresentingManageCollections = true }
            )
            .padding(.top, 8)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                isPresentingAddPlace = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(isPresented: $isPresentingAddPlace) {
            AddPlaceScreen(initialQuery: addPlaceInitialQuery)
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailSheet(place: place)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isPresentingManageCollections) {
            ManageCollectionsSheet()
        }
        .task {
            CollectionRepository(modelContext: modelContext).seedSuggestedCollectionsIfNeeded()
            locationAuthorization.requestWhenInUseAuthorizationIfNeeded()
            resolveInitialViewport()
        }
        .onChange(of: pendingImportCoordinator.pendingImport) { _, newValue in
            guard newValue != nil else { return }
            openAddPlaceFromPendingImport()
        }
    }

    /// Every capture path — manual or shared — converges on the same AddPlaceScreen
    /// (IMPORT_PIPELINE.md "Import Boundary"). The suggested search text is only ever a
    /// starting point the user can edit or clear; it never bypasses MapKit selection.
    private func openAddPlaceFromPendingImport() {
        guard let pendingImport = pendingImportCoordinator.consumePendingImport() else { return }
        selectedPlace = nil
        addPlaceInitialQuery = pendingImport.suggestedSearchText ?? ""

        if isPresentingAddPlace {
            // Force a fresh AddPlaceScreen instance so the new initialQuery actually applies.
            isPresentingAddPlace = false
            DispatchQueue.main.async { isPresentingAddPlace = true }
        } else {
            isPresentingAddPlace = true
        }
    }

    /// Restores the last browsed region when one exists. Otherwise, if location is already
    /// authorized, centers on the user's current location once. Never overrides a viewport
    /// the user was intentionally browsing (§3.3 Initial Viewport).
    private func resolveInitialViewport() {
        if let savedRegion = lastViewport.load() {
            cameraPosition = .region(savedRegion)
        } else if locationAuthorization.authorizationStatus == .authorizedWhenInUse
            || locationAuthorization.authorizationStatus == .authorizedAlways {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }
}

/// Persists only the last browsed map region, never location history tied to the user
/// (Decision 014). Used solely to restore where the user left off browsing.
private struct LastViewportStore {
    private let key = "com.sianjin.PlacePick.lastViewportRegion"

    func save(_ region: MKCoordinateRegion) {
        let values: [Double] = [
            region.center.latitude, region.center.longitude,
            region.span.latitudeDelta, region.span.longitudeDelta
        ]
        UserDefaults.standard.set(values, forKey: key)
    }

    func load() -> MKCoordinateRegion? {
        guard let values = UserDefaults.standard.array(forKey: key) as? [Double], values.count == 4 else {
            return nil
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: values[0], longitude: values[1]),
            span: MKCoordinateSpan(latitudeDelta: values[2], longitudeDelta: values[3])
        )
    }
}

private struct PlaceMapMarker: View {
    let place: Place
    let importance: ImportanceScore

    private var symbolScale: CGFloat {
        1.0 + (importance.value * 0.4)
    }

    var body: some View {
        Image(systemName: place.collection.icon)
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .padding(8)
            .background(Circle().fill(place.isFavorite ? Color.orange : Color.accentColor))
            .scaleEffect(symbolScale)
    }
}

extension Place {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    MapScreen()
        .modelContainer(for: [Place.self, PlaceCollection.self], inMemory: true)
        .environmentObject(PendingImportCoordinator())
}
