import SwiftUI
import SwiftData
import MapKit
import UIKit

struct PlaceDetailSheet: View {
    @Bindable var place: Place

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var visit: Visit?
    @State private var isEditingNote = false
    @State private var noteDraft = ""
    @State private var isPresentingCollectionPicker = false
    @State private var isPresentingReplacePlace = false
    @State private var isPresentingDeleteConfirmation = false
    @State private var isPresentingOpenExternally = false
    @State private var isPresentingMemoryDetail = false
    @State private var isPresentingAddPhoto = false
    @State private var existingTargetPlace: Place?

    private var visitRepository: VisitRepository {
        VisitRepository(modelContext: modelContext)
    }

    private var coverPhoto: VisitPhoto? {
        guard let visit else { return nil }
        return VisitPhotoRepository(modelContext: modelContext).fetchPhotos(for: visit).first
    }

    /// Lazily creates the Place's single Visit on first edit, per the compatibility shim
    /// described in VisitRepository — avoids creating an empty Visit just from viewing.
    private func activeVisit() -> Visit {
        if let visit { return visit }
        let created = visitRepository.findOrCreateActiveVisit(for: place)
        visit = created
        return created
    }

    private var currentEmotion: PlaceEmotion? {
        visit?.emotion
    }

    private var currentNote: String {
        visit?.note ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let visit, let coverPhoto {
                        Button {
                            isPresentingMemoryDetail = true
                        } label: {
                            PhotoAssetThumbnailView(localAssetIdentifier: coverPhoto.localAssetIdentifier, fallbackIcon: place.collection.icon)
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $isPresentingMemoryDetail) {
                            MemoryDetailScreen(visit: visit)
                        }
                    } else {
                        Button {
                            isPresentingAddPhoto = true
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                Text("Add Photo")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .foregroundStyle(Color.accentColor)
                            .background(Color.accentColor.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $isPresentingAddPhoto) {
                            AddPhotoToPlaceSheet(place: place) { savedVisit in
                                visit = savedVisit
                            }
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.title2.weight(.semibold))

                            Button {
                                isPresentingCollectionPicker = true
                            } label: {
                                Label(place.collection.name, systemImage: place.collection.icon)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }

                    HStack(spacing: 24) {
                        Button {
                            place.isFavorite.toggle()
                            place.modifiedAt = .now
                            try? modelContext.save()
                        } label: {
                            Image(systemName: place.isFavorite ? "star.fill" : "star")
                                .foregroundStyle(place.isFavorite ? .orange : .secondary)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        EmotionPicker(emotion: Binding(
                            get: { currentEmotion },
                            set: { newValue in
                                let visit = activeVisit()
                                visit.emotion = newValue
                                visit.modifiedAt = .now
                                visitRepository.save()
                            }
                        ))

                        Spacer()

                        Button {
                            isPresentingOpenExternally = true
                        } label: {
                            Image(systemName: "location.north.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white, Color.accentColor)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            noteDraft = currentNote
                            isEditingNote = true
                        } label: {
                            Text(currentNote.isEmpty ? "Add a note" : currentNote)
                                .foregroundStyle(currentNote.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ShareLink(
                            item: TransferablePlaceIdentity(identity: place.sharedIdentity),
                            preview: SharePreview(place.name, image: sharePreviewBadgeImage(icon: place.collection.icon))
                        ) {
                            Label("Share Place", systemImage: "square.and.arrow.up")
                        }
                        Button("Delete", role: .destructive) { isPresentingDeleteConfirmation = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $isEditingNote) {
                NoteEditor(text: $noteDraft) {
                    let visit = activeVisit()
                    visit.note = noteDraft
                    visit.modifiedAt = .now
                    visitRepository.save()
                    isEditingNote = false
                }
            }
            .sheet(isPresented: $isPresentingCollectionPicker) {
                CollectionPickerSheet(selection: Binding(
                    get: { place.collection },
                    set: { newValue in
                        guard let newValue else { return }
                        place.collection = newValue
                        place.modifiedAt = .now
                        try? modelContext.save()
                    }
                ))
            }
            .sheet(isPresented: $isPresentingReplacePlace) {
                ReplacePlaceScreen(place: place) { existingTarget in
                    isPresentingReplacePlace = false
                    existingTargetPlace = existingTarget
                }
            }
            .sheet(item: $existingTargetPlace) { target in
                PlaceDetailSheet(place: target)
            }
            .confirmationDialog(
                "Delete this place?",
                isPresented: $isPresentingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    let repository = PlaceRepository(modelContext: modelContext)
                    repository.softDelete(place)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Open in",
                isPresented: $isPresentingOpenExternally,
                titleVisibility: .visible
            ) {
                Button("Apple Maps") { openInAppleMaps() }
                Button("Google Maps") { openInGoogleMaps() }
                Button("Cancel", role: .cancel) {}
            }
        }
        .onAppear {
            visit = visitRepository.findActiveVisit(for: place)
        }
    }

    private func openInAppleMaps() {
        let coordinate = place.coordinate
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = place.name
        mapItem.openInMaps()
    }

    private func openInGoogleMaps() {
        let coordinate = place.coordinate
        guard let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(coordinate.latitude),\(coordinate.longitude)") else { return }
        UIApplication.shared.open(url)
    }
}

private struct NoteEditor: View {
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

