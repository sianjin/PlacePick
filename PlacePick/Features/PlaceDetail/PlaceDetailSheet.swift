import SwiftUI
import SwiftData
import MapKit
import UIKit

struct PlaceDetailSheet: View {
    @Bindable var place: Place

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var visits: [Visit] = []
    @State private var isPresentingCollectionPicker = false
    @State private var isPresentingReplacePlace = false
    @State private var isPresentingDeleteConfirmation = false
    @State private var isPresentingOpenExternally = false
    @State private var selectedMemory: Visit?
    @State private var isPresentingAddMemory = false
    @State private var existingTargetPlace: Place?

    private var visitRepository: VisitRepository {
        VisitRepository(modelContext: modelContext)
    }

    private func reloadVisits() {
        visits = visitRepository.fetchVisits(for: place)
    }

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
                                Label(place.collection?.name ?? "", systemImage: place.displayIcon)
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
                        .sensoryFeedback(.selection, trigger: place.isFavorite)

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

                    memoriesSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ShareLink(
                            item: TransferablePlaceIdentity(identity: place.sharedIdentity),
                            preview: SharePreview(place.name, image: sharePreviewBadgeImage(icon: place.displayIcon))
                        ) {
                            Label("Share Place", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            isPresentingReplacePlace = true
                        } label: {
                            Label("Change Place", systemImage: "mappin.and.ellipse")
                        }
                        Button("Delete", role: .destructive) { isPresentingDeleteConfirmation = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedMemory) { memory in
                MemoryDetailScreen(visit: memory)
                    .onDisappear { reloadVisits() }
            }
            .sheet(isPresented: $isPresentingAddMemory) {
                AddPhotoToPlaceSheet(place: place) { _ in
                    reloadVisits()
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
                    Haptics.delete()
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
            reloadVisits()
        }
    }

    /// DATA_MODEL.md §20 Place Detail Projection — a Place renders its full list of
    /// Memories (Visits), each with its own photo, emotion, and note, plus a repeatable
    /// Add Memory action. Replaces the earlier single-Visit cover-photo block.
    @ViewBuilder
    private var memoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // "N Memories" rather than a bare "Memories" heading — this count is the
                // whole point of Place Detail (one Place accumulating many Visits over
                // time), a structural difference from Day One/Apple Journal's flat
                // chronological stream, where no single screen shows how many times
                // you've returned somewhere. Making the count visible at a glance, not
                // something you have to scroll and tally yourself, is the concrete
                // payoff of that difference.
                Text(visits.isEmpty ? "Memories" : "\(visits.count) \(visits.count == 1 ? "Memory" : "Memories")")
                    .font(.headline)
                Spacer()
                Button {
                    isPresentingAddMemory = true
                } label: {
                    Label("Add Memory", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }

            if visits.isEmpty {
                Button {
                    isPresentingAddMemory = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                        Text("Add your first Memory")
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
            } else {
                VStack(spacing: 10) {
                    ForEach(visits) { visit in
                        Button {
                            selectedMemory = visit
                        } label: {
                            MemoryRow(visit: visit, fallbackIcon: place.displayIcon)
                        }
                        .buttonStyle(.plain)
                    }
                }
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

private struct MemoryRow: View {
    let visit: Visit
    let fallbackIcon: String

    @Environment(\.modelContext) private var modelContext

    private var coverPhoto: VisitPhoto? {
        VisitPhotoRepository(modelContext: modelContext).fetchPhotos(for: visit).first
    }

    var body: some View {
        HStack(spacing: 12) {
            // Same emotion-tint ring language as the Calendar's day cells and
            // EmotionPicker's selected state — a visit's feeling should read consistently
            // wherever it appears, and MomentMap's per-visit Emotion (vs. Day One/Apple
            // Journal's plain freeform text) is a real structural difference worth making
            // visible here too, not just a tiny inline glyph next to the note.
            PhotoAssetThumbnailView(localAssetIdentifier: coverPhoto?.localAssetIdentifier, fallbackIcon: fallbackIcon)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: CardStyle.innerCornerRadius))
                .overlay {
                    if let emotion = visit.emotion {
                        RoundedRectangle(cornerRadius: CardStyle.innerCornerRadius)
                            .strokeBorder(emotion.tintColor, lineWidth: 2)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(visit.startedAt, format: .dateTime.month(.abbreviated).day().year())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    if let emotion = visit.emotion {
                        Text(emotion.symbolEmoji)
                    }
                    if !visit.note.isEmpty {
                        Text(visit.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: CardStyle.outerCornerRadius))
        .shadow(color: CardStyle.shadowColor, radius: CardStyle.shadowRadius, y: CardStyle.shadowYOffset)
    }
}

