import SwiftUI
import SwiftData
import MapKit

/// A chronological journal of one day's Memories. See DAY_DETAIL.md — presents Memory
/// Cards in capture order; multiple visits to the same Place remain separate, never merged.
struct DayDetailScreen: View {
    let day: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVisit: Visit?
    @State private var isShowingSavePrompt = false
    @State private var saveState: DaySaveState = .idle

    private var visitRepository: VisitRepository {
        VisitRepository(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            let visits = visitRepository.fetchVisits(on: day)

            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        DayMap(visits: visits, selectedVisit: $selectedVisit)

                        ForEach(visits) { visit in
                            Button {
                                selectedVisit = visit
                            } label: {
                                MemoryCard(visit: visit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }

                if isShowingSavePrompt {
                    DaySavePrompt(state: saveState) {
                        saveSnapshot(visits: visits)
                    }
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle(day.formatted(.dateTime.month(.wide).day().year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedVisit) { visit in
                MemoryDetailScreen(visit: visit)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
                saveState = .idle
                withAnimation { isShowingSavePrompt = true }
            }
        }
    }

    /// Renders Day Detail's own content — the map and Memory cards, no nav bar, no status
    /// bar — as a standalone image, then saves it to Photos. This is the trimmed
    /// alternative to the raw iOS screenshot the user just took, which always includes
    /// system chrome the app has no way to remove.
    ///
    /// ImageRenderer.uiImage is synchronous: it reads the view tree at the instant it's
    /// called. DaySnapshotContent's photo views are freshly constructed instances (not the
    /// live screen's already-resolved ones), so their async PHAsset/PHImageManager fetch
    /// hasn't completed yet if we render immediately — the snapshot would capture the
    /// fallback icon, not the real photo. So cover photos are resolved to actual UIImages
    /// first, then handed to the snapshot content already-loaded.
    private func saveSnapshot(visits: [Visit]) {
        saveState = .saving

        Task {
            let coverPhotosByVisitID = await loadCoverPhotos(for: visits)
            let mapImage = await DayMap.renderStaticSnapshot(for: visits)

            let renderer = ImageRenderer(content: DaySnapshotContent(day: day, visits: visits, coverPhotosByVisitID: coverPhotosByVisitID, mapImage: mapImage))
            renderer.scale = UIScreen.main.scale

            guard let image = renderer.uiImage else {
                saveState = .failed
                return
            }

            do {
                try await DaySnapshotSaver.save(image)
                saveState = .saved
                try? await Task.sleep(for: .seconds(2))
                withAnimation { isShowingSavePrompt = false }
            } catch {
                saveState = .failed
            }
        }
    }

    private func loadCoverPhotos(for visits: [Visit]) async -> [UUID: UIImage] {
        var result: [UUID: UIImage] = [:]
        let photoRepository = VisitPhotoRepository(modelContext: modelContext)
        for visit in visits {
            guard let identifier = photoRepository.fetchPhotos(for: visit).first?.localAssetIdentifier else { continue }
            if let image = await PhotoAssetLoader.loadImage(for: identifier) {
                result[visit.id] = image
            }
        }
        return result
    }
}

private enum DaySaveState {
    case idle
    case saving
    case saved
    case failed
}

private struct DaySavePrompt: View {
    let state: DaySaveState
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            switch state {
            case .idle:
                Button(action: onSave) {
                    Label("Save", systemImage: "photo.badge.arrow.down.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            case .saving:
                ProgressView()
                Text("Saving…")
                    .font(.subheadline)
            case .saved:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Saved to Photos")
                    .font(.subheadline)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Couldn't save")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 4)
    }
}

/// The trimmed content rendered to an image on Save — same map and cards as the live
/// screen, without NavigationStack chrome (title bar, Done button) or the system status
/// bar, neither of which ImageRenderer captures since it renders this view tree in
/// isolation rather than the screen.
private struct DaySnapshotContent: View {
    let day: Date
    let visits: [Visit]
    let coverPhotosByVisitID: [UUID: UIImage]
    let mapImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(day.formatted(.dateTime.month(.wide).day().year()))
                .font(.title2.weight(.semibold))

            if let mapImage {
                Image(uiImage: mapImage)
                    .resizable()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            ForEach(visits) { visit in
                MemoryCard(visit: visit, preloadedCoverPhoto: coverPhotosByVisitID[visit.id])
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .frame(width: UIScreen.main.bounds.width)
    }
}

/// Spatial summary of one day's Memories — DATA_MODEL.md §19.4 Daily Travel Log ("render
/// map, Photos, Emotions, and Notes"). Deliberately shows independent pins with no
/// connecting route: PlacePick only knows where Photos were taken, not how the user
/// traveled between them, and a drawn route would assert a journey the data can't support
/// (e.g. missed/unimported photos would silently produce a wrong or incomplete path).
private struct DayMap: View {
    let visits: [Visit]
    @Binding var selectedVisit: Visit?

    @State private var cameraPosition: MapCameraPosition = .automatic

    private var visitsWithPlace: [Visit] {
        visits.filter { $0.place != nil }
    }

    var body: some View {
        if !visitsWithPlace.isEmpty {
            Map(position: $cameraPosition) {
                ForEach(visitsWithPlace) { visit in
                    Annotation(visit.place!.name, coordinate: visit.place!.coordinate) {
                        Button {
                            selectedVisit = visit
                        } label: {
                            DayMapPin(visit: visit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear { cameraPosition = .region(Self.fittedRegion(for: visitsWithPlace)) }
        }
    }

    /// Shared by the live interactive map and the static Save-snapshot renderer, so both
    /// always frame the day's Visits identically.
    fileprivate static func fittedRegion(for visitsWithPlace: [Visit]) -> MKCoordinateRegion {
        let coordinates = visitsWithPlace.map { $0.place!.coordinate }
        guard let first = coordinates.first else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        }

        if coordinates.count == 1 {
            return MKCoordinateRegion(center: first, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }

        var minLatitude = first.latitude, maxLatitude = first.latitude
        var minLongitude = first.longitude, maxLongitude = first.longitude
        for coordinate in coordinates {
            minLatitude = min(minLatitude, coordinate.latitude)
            maxLatitude = max(maxLatitude, coordinate.latitude)
            minLongitude = min(minLongitude, coordinate.longitude)
            maxLongitude = max(maxLongitude, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLatitude - minLatitude) * 1.6, 0.01),
            longitudeDelta: max((maxLongitude - minLongitude) * 1.6, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    /// Static counterpart to the live map, for use in ImageRenderer snapshots — see
    /// DayDetailScreen.saveSnapshot. MKMapSnapshotter renders asynchronously ahead of time
    /// instead of relying on a live Map view being ready at the instant ImageRenderer reads
    /// the view tree.
    static func renderStaticSnapshot(for visits: [Visit]) async -> UIImage? {
        let visitsWithPlace = visits.filter { $0.place != nil }
        guard !visitsWithPlace.isEmpty else { return nil }

        let region = fittedRegion(for: visitsWithPlace)
        let pins = visitsWithPlace.map {
            DayMapSnapshotRenderer.Pin(coordinate: $0.place!.coordinate, symbolName: $0.place?.displayIcon ?? "mappin.circle")
        }
        let width = UIScreen.main.bounds.width - 32 // matches DaySnapshotContent's .padding()
        return await DayMapSnapshotRenderer.renderSnapshot(region: region, pins: pins, size: CGSize(width: width, height: 180))
    }
}

private struct DayMapPin: View {
    let visit: Visit

    var body: some View {
        Image(systemName: visit.place?.displayIcon ?? "mappin.circle")
            .font(.system(size: 12))
            .foregroundStyle(.white)
            .padding(6)
            .background(Circle().fill(Color.accentColor))
    }
}

/// The fundamental building block of PlacePick, per DAY_DETAIL.md — same card used in
/// Day Detail and (eventually) other Memory-listing surfaces.
struct MemoryCard: View {
    let visit: Visit
    /// When set, used instead of PhotoAssetThumbnailView's own async load — needed for
    /// ImageRenderer snapshots, which read the view tree synchronously and can't wait on
    /// an async PHAsset fetch. See DayDetailScreen.saveSnapshot.
    var preloadedCoverPhoto: UIImage? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var placeTimeZone: TimeZone?

    private var coverPhotoIdentifier: String? {
        VisitPhotoRepository(modelContext: modelContext).fetchPhotos(for: visit).first?.localAssetIdentifier
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let preloadedCoverPhoto {
                Image(uiImage: preloadedCoverPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: CardStyle.innerCornerRadius))
            } else {
                PhotoAssetThumbnailView(localAssetIdentifier: coverPhotoIdentifier, fallbackIcon: visit.place?.displayIcon ?? "mappin.circle")
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: CardStyle.innerCornerRadius))
            }

            Text(visit.place?.name ?? "")
                .font(.headline)
                .foregroundStyle(.primary)

            if let emotion = visit.emotion {
                Text("\(emotion.symbolEmoji) \(emotion.label)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !visit.note.isEmpty {
                Text(visit.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Shows the time as it truly was at this Place (e.g. NYC local time), not
            // reformatted into whatever time zone this device is currently in. Built as a
            // plain String rather than Text(_:format:) — SwiftUI's Text(_:format:) can fail
            // to re-render when only the FormatStyle's timeZone changes across a state
            // update while the Date itself does not, since it isn't part of what SwiftUI
            // diffs to invalidate Text.
            Text(visit.startedAt.formatted(Date.FormatStyle(time: .shortened, timeZone: placeTimeZone ?? .current)))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CardStyle.outerCornerRadius))
        .shadow(color: CardStyle.shadowColor, radius: CardStyle.shadowRadius, y: CardStyle.shadowYOffset)
        .task(id: visit.place?.id) {
            guard let place = visit.place else { return }
            placeTimeZone = PlaceTimeZoneResolver.cached(for: place.coordinate)
            placeTimeZone = await PlaceTimeZoneResolver.resolve(for: place.coordinate)
        }
    }
}

extension PlaceEmotion {
    var label: String {
        switch self {
        case .neutral: return "Okay"
        case .happy: return "Loved it"
        case .amazed: return "Unforgettable"
        }
    }
}

#Preview {
    DayDetailScreen(day: .now)
        .modelContainer(for: [Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self], inMemory: true)
}
