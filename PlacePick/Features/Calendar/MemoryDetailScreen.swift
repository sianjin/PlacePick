import SwiftUI
import SwiftData
import PhotosUI

/// The heart of PlacePick — every browsing path eventually leads here. See
/// MEMORY_DETAIL.md: photos first, then place, emotion, note, and time, following the
/// natural order of human recall rather than storage order.
struct MemoryDetailScreen: View {
    @Bindable var visit: Visit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingNote = false
    @State private var noteDraft = ""
    @State private var photos: [VisitPhoto] = []
    @State private var selectedPhotoID: VisitPhoto.ID?
    @State private var isPresentingLastPhotoConfirmation = false
    @State private var isPresentingDeleteMemoryConfirmation = false
    @State private var addPhotosSelection: [PhotosPickerItem] = []
    @State private var isPresentingAddPhotosPicker = false
    @State private var isAddingPhotos = false
    @State private var addPhotosErrorMessage: String?
    @State private var isPresentingReorderPhotos = false
    @State private var placeTimeZone: TimeZone?

    private var visitRepository: VisitRepository {
        VisitRepository(modelContext: modelContext)
    }

    private var visitPhotoRepository: VisitPhotoRepository {
        VisitPhotoRepository(modelContext: modelContext)
    }

    private func reloadPhotos() {
        photos = visitPhotoRepository.fetchPhotos(for: visit)
        if !photos.contains(where: { $0.id == selectedPhotoID }) {
            selectedPhotoID = photos.first?.id
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoCarousel

                    VStack(alignment: .leading, spacing: 12) {
                        Text(visit.place?.name ?? "")
                            .font(.title2.weight(.semibold))

                        EmotionPicker(emotion: Binding(
                            get: { visit.emotion },
                            set: { newValue in
                                visit.emotion = newValue
                                visit.modifiedAt = .now
                                visitRepository.save()
                            }
                        ))

                        if !visit.note.isEmpty {
                            Text(visit.note)
                                .font(.body)
                        }

                        Button {
                            noteDraft = visit.note
                            isEditingNote = true
                        } label: {
                            Text(visit.note.isEmpty ? "Add a note" : "Edit note")
                                .font(.subheadline)
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)

                        // Shows the time as it truly was at this Place (e.g. NYC local time),
                        // not reformatted into whatever time zone this device is currently in.
                        Text(visit.startedAt, format: Date.FormatStyle(
                            date: .abbreviated, time: .shortened, timeZone: placeTimeZone ?? .current
                        ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
    Menu {
                        Button {
                            isPresentingAddPhotosPicker = true
                        } label: {
                            Label("Add Photos", systemImage: "photo.badge.plus")
                        }
                        .disabled(isAddingPhotos)
                        Button {
                            isPresentingReorderPhotos = true
                        } label: {
                            Label("Reorder Photos", systemImage: "arrow.up.arrow.down")
                        }
                        .disabled(photos.count < 2)
                        Button("Delete Memory", role: .destructive) {
                            isPresentingDeleteMemoryConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $isEditingNote) {
                MemoryNoteEditor(text: $noteDraft) {
                    visit.note = noteDraft
                    visit.modifiedAt = .now
                    visitRepository.save()
                    isEditingNote = false
                }
            }
            .sheet(isPresented: $isPresentingReorderPhotos) {
                ReorderPhotosSheet(photos: photos) { reordered in
                    visitPhotoRepository.reorder(reordered)
                    reloadPhotos()
                }
            }
            .photosPicker(
                isPresented: $isPresentingAddPhotosPicker,
                selection: $addPhotosSelection,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: addPhotosSelection) { _, newValue in
                guard !newValue.isEmpty else { return }
                Task { await addPhotos(newValue) }
            }
            .alert("Couldn't Read Photo Details", isPresented: .constant(addPhotosErrorMessage != nil), actions: {
                Button("OK") {
                    addPhotosErrorMessage = nil
                    addPhotosSelection = []
                }
            }, message: { Text(addPhotosErrorMessage ?? "") })
            .confirmationDialog(
                "This is the last photo in this Memory. Deleting it will also delete the Memory.",
                isPresented: $isPresentingLastPhotoConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Memory", role: .destructive) { deleteVisit() }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Delete this Memory?",
                isPresented: $isPresentingDeleteMemoryConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Memory", role: .destructive) { deleteVisit() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .onAppear { reloadPhotos() }
        .task(id: visit.place?.id) {
            guard let place = visit.place else { return }
            placeTimeZone = PlaceTimeZoneResolver.cached(for: place.coordinate)
            placeTimeZone = await PlaceTimeZoneResolver.resolve(for: place.coordinate)
        }
    }

    /// Photos first, swipeable, per MEMORY_DETAIL.md — falls back to a single icon
    /// placeholder when no VisitPhotos exist yet (manually-added Places have none). The
    /// delete button lives in an .overlay on the whole carousel rather than inside each
    /// TabView page — per-page overlays were unreliable, likely due to TabView's paging
    /// content compositing each page independently. DATA_MODEL.md §22.3 requires forcing
    /// a choice when this would be the Visit's last Photo.
    @ViewBuilder
    private var photoCarousel: some View {
        if photos.isEmpty {
            PhotoAssetThumbnailView(localAssetIdentifier: nil, fallbackIcon: visit.place?.displayIcon ?? "mappin.circle")
                .frame(height: 320)
        } else {
            TabView(selection: $selectedPhotoID) {
                ForEach(photos) { photo in
                    PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: visit.place?.displayIcon ?? "mappin.circle")
                        .tag(Optional(photo.id))
                }
            }
            .frame(height: 320)
            .tabViewStyle(.page)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    requestDeletionOfSelectedPhoto()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, Color.black.opacity(0.5))
                }
                .padding(.trailing, 12)
                .padding(.bottom, 28)
            }
        }
    }

    private func requestDeletionOfSelectedPhoto() {
        guard let selectedPhotoID, let photo = photos.first(where: { $0.id == selectedPhotoID }) else { return }

        if photos.count == 1 {
            isPresentingLastPhotoConfirmation = true
        } else {
            visitPhotoRepository.softDelete(photo)
            reloadPhotos()
        }
    }

    private func addPhotos(_ items: [PhotosPickerItem]) async {
        isAddingPhotos = true
        defer {
            isAddingPhotos = false
            addPhotosSelection = []
        }

        let candidates = await PhotoLibraryService.loadCandidates(for: items)
        guard !candidates.isEmpty else {
            addPhotosErrorMessage = "PlacePick couldn't read the date for the selected photos. Photos need capture-date metadata (most camera photos have this; some screenshots or edited images may not)."
            return
        }

        visitPhotoRepository.attach(candidates, to: visit)
        reloadPhotos()
    }

    private func deleteVisit() {
        visitRepository.softDelete(visit)
        Haptics.delete()
        dismiss()
    }
}

/// Drag-to-reorder grid — dragging a photo to the first position is how the user sets it
/// as the cover photo (PlaceDetailSheet.coverPhoto is simply the first Photo by sortOrder),
/// so there is no separate "set as cover" action.
private struct ReorderPhotosSheet: View {
    let photos: [VisitPhoto]
    let onSave: ([VisitPhoto]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var ordered: [VisitPhoto]
    @State private var draggingPhotoID: VisitPhoto.ID?
    @State private var targetedPhotoID: VisitPhoto.ID?

    init(photos: [VisitPhoto], onSave: @escaping ([VisitPhoto]) -> Void) {
        self.photos = photos
        self.onSave = onSave
        _ordered = State(initialValue: photos)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                    ForEach(ordered) { photo in
                        PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: "photo")
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(alignment: .topLeading) {
                                if photo.id == ordered.first?.id {
                                    Text("Cover")
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.black.opacity(0.6), in: Capsule())
                                        .foregroundStyle(.white)
                                        .padding(4)
                                }
                            }
                            .opacity(draggingPhotoID == photo.id ? 0.5 : 1)
                            .scaleEffect(targetedPhotoID == photo.id ? 1.05 : 1)
                            .overlay {
                                if targetedPhotoID == photo.id {
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.accentColor, lineWidth: 3)
                                }
                            }
                            .animation(.easeOut(duration: 0.15), value: targetedPhotoID)
                            // Each cell needs a distinct identity for .draggable's preview to
                            // reflect the actual photo under the finger — without it, SwiftUI
                            // can reuse/conflate cells that share the same view structure,
                            // making every drag preview show whichever photo rendered first.
                            .id(photo.id)
                            .draggable(photo.id.uuidString) {
                                PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: "photo")
                                    .frame(width: 80, height: 80)
                                    .id(photo.id)
                                    .onAppear { draggingPhotoID = photo.id }
                            }
                            // isTargeted suppresses SwiftUI's default drop-target chrome (a
                            // green "+" and placeholder square), which reads as "insert a
                            // new photo" — misleading here since reordering never adds one.
                            // A highlight on the existing thumbnail communicates "swap
                            // position" instead.
                            .dropDestination(for: String.self) { items, _ in
                                draggingPhotoID = nil
                                targetedPhotoID = nil
                                guard let draggedIDString = items.first,
                                      let draggedID = UUID(uuidString: draggedIDString),
                                      let sourceIndex = ordered.firstIndex(where: { $0.id == draggedID }),
                                      let destinationIndex = ordered.firstIndex(where: { $0.id == photo.id }) else { return false }
                                withAnimation {
                                    ordered.move(
                                        fromOffsets: IndexSet(integer: sourceIndex),
                                        toOffset: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex
                                    )
                                }
                                return true
                            } isTargeted: { isTargeted in
                                targetedPhotoID = isTargeted ? photo.id : nil
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Reorder Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(ordered)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct MemoryNoteEditor: View {
    @Binding var text: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .padding()
                .navigationTitle("Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: onSave)
                    }
                }
        }
    }
}
