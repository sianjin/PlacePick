import SwiftUI
import SwiftData
import MapKit
import UIKit

struct PlaceDetailSheet: View {
    @Bindable var place: Place

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingNote = false
    @State private var noteDraft = ""
    @State private var isPresentingCollectionPicker = false
    @State private var isPresentingReplacePlace = false
    @State private var isPresentingDeleteConfirmation = false
    @State private var isPresentingOpenExternally = false
    @State private var existingTargetPlace: Place?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                            get: { place.emotion },
                            set: { newValue in
                                place.emotion = newValue
                                place.modifiedAt = .now
                                try? modelContext.save()
                            }
                        ))

                        Spacer()

                        Button {
                            isPresentingOpenExternally = true
                        } label: {
                            Image(systemName: "arrow.up.forward.square")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            noteDraft = place.note
                            isEditingNote = true
                        } label: {
                            Text(place.note.isEmpty ? "Add a note" : place.note)
                                .foregroundStyle(place.note.isEmpty ? .secondary : .primary)
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
                        Button("Replace Place") { isPresentingReplacePlace = true }
                        Button("Delete", role: .destructive) { isPresentingDeleteConfirmation = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $isEditingNote) {
                NoteEditor(text: $noteDraft) {
                    place.note = noteDraft
                    place.modifiedAt = .now
                    try? modelContext.save()
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

