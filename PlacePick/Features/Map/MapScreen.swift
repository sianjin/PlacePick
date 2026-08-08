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
            locationAuthorization.requestWhenInUseAuthorizationIfNeeded()
            resolveInitialViewport()
        }
        .task {
            // On a fresh install the local store is empty until CloudKit's initial import
            // lands, which can take several seconds — seeding immediately would insert a
            // default batch that then races/duplicates with the user's real synced
            // Collections (see CollectionRepository.seedSuggestedCollectionsIfNeeded).
            // Waiting here gives CloudKit a head start before we conclude "no Collections"
            // really means "new install" rather than "sync hasn't arrived yet."
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            let collectionRepository = CollectionRepository(modelContext: modelContext)
            collectionRepository.seedSuggestedCollectionsIfNeeded()
            collectionRepository.mergeDuplicateCollections()
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
    /// Boundary". MomentMap-originated Place/Collection shares already carry verified
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

        // A shared Maps or Yelp link (including short links like maps.app.goo.gl,
        // maps.apple.com/p/..., or yelp.to/...) carries no place name the Share Extension can
        // read without a network round-trip, so resolution happens here instead — see
        // IMPORT_PIPELINE.md "URL Resolution", MapsLinkResolver, and YelpLinkResolver. Some
        // senders (observed from Google Maps' share sheet) hand off the link as a plain-text
        // attachment rather than a public.url item, so sourceURL alone isn't reliable — a link
        // embedded in sharedText needs the same chance at resolution. Falls back to the
        // extension's weak text/title candidate (never raw domain text) if no recognized link
        // is found anywhere, or resolution fails or times out.
        if let linkURL = pendingImport.sourceURL ?? Self.firstMapsURL(in: pendingImport.sharedText) {
            // Yelp's share caption ("Check out Noodle Panda") already carries a clean name with
            // zero network cost, and is preferred over YelpLinkResolver's slug-derived name
            // regardless (see below) — so for a Yelp link, check it before ever starting a
            // network round-trip. This also sidesteps the redirect chain's real-device latency
            // (yelp.to → an app.adjust.com deferred-deep-link hop, which was measured taking
            // several seconds and occasionally missing the timeout entirely on a freshly
            // launched process — much slower than Maps' single-hop redirects).
            if YelpLinkResolver.isYelpHost(linkURL), let captionName = Self.yelpCaptionName(from: pendingImport.sharedText) {
                openAddPlaceFromPendingImport(searchText: captionName)
                return
            }

            Task {
                var resolved: MapsLinkCandidate?

                // Route directly to the matching resolver by host rather than trying
                // MapsLinkResolver first and falling through — trying both sequentially would
                // double network latency for every Yelp link (Maps' own HEAD request has to
                // fail/time out before Yelp's even starts).
                if YelpLinkResolver.isYelpHost(linkURL) {
                    resolved = await YelpLinkResolver.resolve(linkURL)
                } else {
                    resolved = await MapsLinkResolver.resolve(linkURL)
                }

                openAddPlaceFromPendingImport(searchText: resolved?.name ?? pendingImport.suggestedSearchText ?? "")
            }
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
    ///
    /// If AddPlaceScreen is already open (e.g. the user shared one place and, without
    /// saving/cancelling, shared a second), simply updating `addPlaceInitialQuery` is enough —
    /// AddPlaceScreen's own `.onChange(of: initialQuery)` resets its state to match. This used
    /// to force-dismiss and re-present the sheet to get a fresh instance, but `.sheet` doesn't
    /// guarantee tearing down view identity on a quick false→true toggle, so that trick could
    /// silently leave the *previous* share's query and selection on screen.
    private func openAddPlaceFromPendingImport(searchText: String) {
        selectedPlace = nil
        addPlaceInitialQuery = searchText
        isPresentingAddPlace = true
    }

    /// Some share sources (observed from Google Maps) hand off a link as a plain-text
    /// attachment instead of a public.url item, so PendingImport.sourceURL is nil even though
    /// a URL is right there in the shared text. NSDataDetector is Foundation's own link finder
    /// — reused here rather than a hand-rolled regex, and scoped to the first match only since
    /// a share payload is expected to carry at most one link.
    private static func firstMapsURL(in text: String?) -> URL? {
        guard let text, !text.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.matches(in: text, range: range).first?.url
    }

    /// Yelp's share sheet produces caption text of the form "Check out <Place Name>" alongside
    /// the yelp.to link. Strips that fixed prefix, and the URL itself if present (some senders
    /// append it to the same string) — only ever a search hint, never treated as verified.
    private static func yelpCaptionName(from sharedText: String?) -> String? {
        guard var text = sharedText, !text.isEmpty else { return nil }

        if let urlRange = text.range(of: #"https?://\S+"#, options: .regularExpression) {
            text.removeSubrange(urlRange)
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let prefix = "Check out "
        if text.hasPrefix(prefix) {
            text.removeFirst(prefix.count)
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        return text.isEmpty ? nil : text
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
