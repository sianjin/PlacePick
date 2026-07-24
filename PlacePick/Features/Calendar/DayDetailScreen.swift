import SwiftUI
import SwiftData

/// A chronological journal of one day's Memories. See DAY_DETAIL.md — presents Memory
/// Cards in capture order; multiple visits to the same Place remain separate, never merged.
struct DayDetailScreen: View {
    let day: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVisit: Visit?

    private var visitRepository: VisitRepository {
        VisitRepository(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(visitRepository.fetchVisits(on: day)) { visit in
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
        }
    }
}

/// The fundamental building block of PlacePick, per DAY_DETAIL.md — same card used in
/// Day Detail and (eventually) other Memory-listing surfaces.
struct MemoryCard: View {
    let visit: Visit

    @Environment(\.modelContext) private var modelContext

    private var coverPhotoIdentifier: String? {
        VisitPhotoRepository(modelContext: modelContext).fetchPhotos(for: visit).first?.localAssetIdentifier
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotoAssetThumbnailView(localAssetIdentifier: coverPhotoIdentifier, fallbackIcon: visit.place.collection.icon)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(visit.place.name)
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

            Text(visit.startedAt, format: .dateTime.hour().minute())
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
