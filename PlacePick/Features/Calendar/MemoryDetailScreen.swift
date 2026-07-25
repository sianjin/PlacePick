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

                        Text(visit.startedAt, format: .dateTime.month().day().year().hour().minute())
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
        dismiss()
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
