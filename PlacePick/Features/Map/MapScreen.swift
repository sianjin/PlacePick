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
    @State private var poiPreviewMapItem: MKMapItem?
    @State private var poiSaveMapItem: MKMapItem?
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
            if #available(iOS 18.0, *) {
                POICapableMapView(
                    cameraPosition: $cameraPosition,
                    currentSpan: $currentSpan,
                    selectedPlace: $selectedPlace,
                    visiblePlaces: visiblePlaces,
                    visitsByPlaceID: visitsByPlaceID,
                    recommendationEngine: recommendationEngine,
                    lastViewport: lastViewport,
                    onFeatureTapped: { feature in handleMapFeatureSelection(feature) }
                )
            } else {
                PlacesOnlyMapView(
                    cameraPosition: $cameraPosition,
                    currentSpan: $currentSpan,
                    selectedPlace: $selectedPlace,
                    visiblePlaces: visiblePlaces,
                    visitsByPlaceID: visitsByPlaceID,
                    recommendationEngine: recommendationEngine,
                    lastViewport: lastViewport
                )
            }

            CollectionBar(
                collections: collections,
                selectedCollection: $selectedCollection,
                onManage: { isPresentingManageCollections = true }
            )
            .padding(.top, 8)

            if let poiPreviewMapItem {
                VStack {
                    Spacer()
                    POIPreviewCard(
                        mapItem: poiPreviewMapItem,
                        onSave: {
                            poiSaveMapItem = poiPreviewMapItem
                            self.poiPreviewMapItem = nil
                        },
                        onDismiss: {
                            self.poiPreviewMapItem = nil
                        }
                    )
                    .padding(.bottom, 88)
                }
            }
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
        .sheet(isPresented: Binding(
            get: { poiSaveMapItem != nil },
            set: { if !$0 { poiSaveMapItem = nil } }
        )) {
            if let mapItem = poiSaveMapItem {
                NavigationStack {
                    PersonalInfoForm(
                        mapItem: mapItem,
                        onCancel: { poiSaveMapItem = nil },
                        onSave: { draft in savePOI(mapItem: mapItem, relationship: draft) }
                    )
                    .navigationTitle("Add Place")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
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

    /// Tapping a native Apple Maps POI (iOS 18+ only — see POICapableMapView) resolves an
    /// MKMapItem and, if it isn't already saved (§10.3 Duplicate Identity match), shows
    /// POIPreviewCard as a fast Save entry point instead of routing through AddPlaceScreen's
    /// search list. Tapping a Place we already saved opens its detail sheet directly.
    @available(iOS 18.0, *)
    private func handleMapFeatureSelection(_ feature: MapFeature) {
        Task {
            let request = MKMapItemRequest(feature: feature)
            guard let mapItem = try? await request.mapItem else { return }

            let repository = PlaceRepository(modelContext: modelContext)
            if let existing = repository.findNearbyMatch(
                name: mapItem.name ?? "",
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude
            ) {
                selectedPlace = existing
                return
            }

            poiPreviewMapItem = mapItem
        }
    }

    private func savePOI(mapItem: MKMapItem, relationship: PlaceRelationshipDraft) {
        let repository = PlaceRepository(modelContext: modelContext)
        let creationService = PlaceCreationService(
            repository: repository,
            visitRepository: VisitRepository(modelContext: modelContext)
        )

        do {
            let result = try creationService.createPlace(from: mapItem, relationship: relationship)
            switch result {
            case .created(let place):
                Haptics.success()
                poiSaveMapItem = nil
                selectedPlace = place
            case .existing(let place):
                poiSaveMapItem = nil
                selectedPlace = place
            }
        } catch {
            poiSaveMapItem = nil
        }
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

/// iOS 17 fallback: identical to the app's original Map, tap-to-select only works for
/// Places the user already saved. Native Apple Maps POI tap-selection needs
/// `mapFeatureSelectionAccessory` (iOS 18+), which has no confirmed-reliable iOS 17
/// equivalent — see POICapableMapView.
private struct PlacesOnlyMapView: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var currentSpan: MKCoordinateSpan
    @Binding var selectedPlace: Place?
    let visiblePlaces: [Place]
    let visitsByPlaceID: [UUID: [Visit]]
    let recommendationEngine: RecommendationEngine
    let lastViewport: LastViewportStore

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedPlace) {
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
    }
}

/// iOS 18+: adds tap-to-select on native Apple Maps POIs via `MapFeature` selection plus
/// `mapFeatureSelectionAccessory`, alongside the existing saved-Place selection.
@available(iOS 18.0, *)
private struct POICapableMapView: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var currentSpan: MKCoordinateSpan
    @Binding var selectedPlace: Place?
    let visiblePlaces: [Place]
    let visitsByPlaceID: [UUID: [Visit]]
    let recommendationEngine: RecommendationEngine
    let lastViewport: LastViewportStore
    let onFeatureTapped: (MapFeature) -> Void

    @State private var selectedFeature: MapFeature?

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedFeature) {
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
                        .onTapGesture { selectedPlace = place }
                }
            }
            UserAnnotation()
        }
        .mapFeatureSelectionAccessory(.callout)
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
        .onChange(of: selectedFeature) { _, newValue in
            guard let newValue else { return }
            onFeatureTapped(newValue)
            selectedFeature = nil
        }
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
