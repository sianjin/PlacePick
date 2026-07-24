import SwiftUI
import SwiftData

/// The heart of PlacePick — every browsing path eventually leads here. See
/// MEMORY_DETAIL.md: photos first, then place, emotion, note, and time, following the
/// natural order of human recall rather than storage order.
struct MemoryDetailScreen: View {
    @Bindable var visit: Visit

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingNote = false
    @State private var noteDraft = ""

    private var visitRepository: VisitRepository {
        VisitRepository(modelContext: modelContext)
    }

    private var photos: [VisitPhoto] {
        VisitPhotoRepository(modelContext: modelContext).fetchPhotos(for: visit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoCarousel

                    VStack(alignment: .leading, spacing: 12) {
                        Text(visit.place.name)
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
            }
            .sheet(isPresented: $isEditingNote) {
                MemoryNoteEditor(text: $noteDraft) {
                    visit.note = noteDraft
                    visit.modifiedAt = .now
                    visitRepository.save()
                    isEditingNote = false
                }
            }
        }
    }

    /// Photos first, swipeable, per MEMORY_DETAIL.md — falls back to a single icon
    /// placeholder when no VisitPhotos exist yet (manually-added Places have none).
    @ViewBuilder
    private var photoCarousel: some View {
        let currentPhotos = photos
        if currentPhotos.isEmpty {
            PhotoAssetThumbnailView(localAssetIdentifier: nil, fallbackIcon: visit.place.collection.icon)
                .frame(height: 320)
        } else {
            TabView {
                ForEach(currentPhotos) { photo in
                    PhotoAssetThumbnailView(localAssetIdentifier: photo.localAssetIdentifier, fallbackIcon: visit.place.collection.icon)
                }
            }
            .frame(height: 320)
            .tabViewStyle(.page)
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
