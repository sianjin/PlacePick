import Foundation

struct ImportanceScore {
    let value: Double
}

protocol RecommendationEngine {
    /// Scores off the Place's most recent Visit by startedAt — a Place may have many
    /// Visits (DATA_MODEL.md §3.2), but only the latest experience drives "does this
    /// still need attention" framing. An empty array means no Visit has ever been
    /// recorded, same meaning as the old `Place.emotion == nil`.
    func importance(for place: Place, visits: [Visit], now: Date) -> ImportanceScore
}

/// Deterministic, explainable, per-Place scorer. Must never depend on other Places,
/// map density, or viewport — see RECOMMENDATION_MODEL.md §3.
struct DefaultRecommendationEngine: RecommendationEngine {
    private let recentlySavedWindow: TimeInterval = 14 * 24 * 60 * 60 // 14 days

    private let minimumRawScore: Double = -20
    private let maximumRawScore: Double = 75

    func importance(for place: Place, visits: [Visit], now: Date) -> ImportanceScore {
        var raw: Double = 0

        if place.isFavorite {
            raw += 40
        }

        let mostRecentVisit = visits.max(by: { $0.startedAt < $1.startedAt })
        if mostRecentVisit?.emotion == nil {
            raw += 30
        } else {
            raw -= 20
        }

        if now.timeIntervalSince(place.createdAt) <= recentlySavedWindow {
            raw += 5
        }

        let clamped = min(max(raw, minimumRawScore), maximumRawScore)
        let normalized = (clamped - minimumRawScore) / (maximumRawScore - minimumRawScore)
        return ImportanceScore(value: normalized)
    }
}
