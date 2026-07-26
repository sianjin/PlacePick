import SwiftUI
import SwiftData
import MapKit

struct MapScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [Place]
    @Query(sort: \PlaceCollection.order) private var collections: [PlaceCollection]
    @Query private var visits: [Visit]

    @StateObject private var locationAuthorization = LocationAuthorizationService()
    @EnvironmentObject private var pendingImportCoordinator: PendingImportCoordinator

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCollection: PlaceCollection?
    @State private var selectedPlace: Place?
    @State private var isPresentingAddPlace = false
    @State private var isPresentingPhotoMemory = false
    @State private var isPresentingCaptureChoice = false
    @State private var isPresentingManageCollections = false
    @State private var addPlaceInitialQuery = ""
    @State private var receivedPlaceIdentity: SharedPlaceIdentity?
    @State private var receivedCollectionSnapshot: SharedCollectionSnapshot?
    @State private var currentSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

    private let recommendationEngine: RecommendationEngine = DefaultRecommendationEngine()
    private let lastViewport = LastViewportStore()

    private var visiblePlaces: [Place] {
        let active = places.filter { $0.deletedAt == nil }
        guard let selectedCollection else { return active }
        return active.filter { $0.collection?.id == selectedCollection.id }
    }

    /// One lookup per body evaluation rather than a fetch per marker. A Place may have
    /// many Visits (DATA_MODEL.md §3.2) — RecommendationEngine picks the relevant one.
    private var visitsByPlaceID: [UUID: [Visit]] {
        Dictionary(grouping: visits.filter { $0.deletedAt == nil && $0.place != nil }, by: { $0.place!.id })
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $selectedPlace) {
                let visitsByPlaceID = visitsByPlaceID
                ForEach(visiblePlaces) { place in
                    let importance = recommendationEngine.importance(
                        for: place,
                        visits: visitsByPlaceID[place.id] ?? [],
                        now: .now
                    )
                    Annotation(
                        MapLabelPresentation.shouldShowLabel(importance: importance, span: currentSpan) ? place.name : "",
                        coordinate: place.coordinate
                    ) {
                        PlaceMapMarker(place: place, importance: importance)
                    }
                    .tag(place)
                }
                UserAnnotation()
            }
            .mapControls {
                MapCompass()
            }
            .ignoresSafeArea(edges: .top)
            .onMapCameraChange(frequency: .continuous) { context in
                currentSpan = context.region.span
            }
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
                isPresentingCaptureChoice = true
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
        .confirmationDialog(
            "What would you like to save?",
            isPresented: $isPresentingCaptureChoice,
            titleVisibility: .visible
        ) {
            Button("A Place") { isPresentingAddPlace = true }
            Button("A Memory") { isPresentingPhotoMemory = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isPresentingAddPlace) {
            AddPlaceScreen(initialQuery: addPlaceInitialQuery)
        }
        .sheet(isPresented: $isPresentingPhotoMemory) {
            PhotoMemoryScreen()
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailSheet(place: place)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isPresentingManageCollections) {
            ManageCollectionsSheet()
        }
        .sheet(item: $receivedPlaceIdentity) { identity in
            ReceivePlaceSheet(identity: identity) { place in
                selectedPlace = place
            }
        }
        .sheet(item: $receivedCollectionSnapshot) { snapshot in
            ReceiveCollectionSheet(snapshot: snapshot) {}
        }
        .task {
            let collectionRepository = CollectionRepository(modelContext: modelContext)
            collectionRepository.seedSuggestedCollectionsIfNeeded()
            collectionRepository.mergeDuplicateCollections()
            locationAuthorization.requestWhenInUseAuthorizationIfNeeded()
            resolveInitialViewport()
        }
        .onChange(of: pendingImportCoordinator.pendingImport) { _, newValue in
            guard newValue != nil else { return }
            handlePendingImport()
        }
        .onChange(of: collections) { _, _ in
            // CloudKit sync is asynchronous and can keep merging in remote records for
            // seconds to minutes after launch — a single merge pass in .task above only
            // sees what's synced at that instant. Re-running on every change to the
            // Collections @Query catches duplicates that arrive later (e.g. a batch synced
            // down from another device right after this one already finished its own pass).
            CollectionRepository(modelContext: modelContext).mergeDuplicateCollections()
        }
    }

    /// Routes a received PendingImport to the correct entry point. Search-text imports
    /// (external content) converge on AddPlaceScreen per IMPORT_PIPELINE.md "Import
    /// Boundary". PlacePick-originated Place/Collection shares already carry verified
    /// identity, so they skip Candidate Resolution entirely — see MVP.md §10 and §11.
    private func handlePendingImport() {
        guard let pendingImport = pendingImportCoordinator.consumePendingImport() else { return }

        if let snapshot = pendingImport.sharedCollectionSnapshot {
            receivedCollectionSnapshot = snapshot
            return
        }

        if let identity = pendingImport.sharedPlaceIdentity {
            openReceivedPlace(identity)
            return
        }

        openAddPlaceFromPendingImport(searchText: pendingImport.suggestedSearchText ?? "")
    }

    /// §10.2 Receiving an Existing Place: dedup happens before any UI is shown — an
    /// already-saved Place opens directly with no Collection-choice step.
    private func openReceivedPlace(_ identity: SharedPlaceIdentity) {
        let service = PlaceCreationService(repository: PlaceRepository(modelContext: modelContext))
        if let existing = service.findExisting(matching: identity) {
            selectedPlace = existing
        } else {
            receivedPlaceIdentity = identity
        }
    }

    /// Every capture path — manual or shared — converges on the same AddPlaceScreen
    /// (IMPORT_PIPELINE.md "Import Boundary"). The suggested search text is only ever a
    /// starting point the user can edit or clear; it never bypasses MapKit selection.
    private func openAddPlaceFromPendingImport(searchText: String) {
        selectedPlace = nil
        addPlaceInitialQuery = searchText

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
            currentSpan = savedRegion.span
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
        Image(systemName: place.displayIcon)
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
        .modelContainer(for: [Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self], inMemory: true)
        .environmentObject(PendingImportCoordinator())
}
