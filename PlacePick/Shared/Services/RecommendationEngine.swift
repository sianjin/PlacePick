import Foundation

struct ImportanceScore {
    let value: Double
}

protocol RecommendationEngine {
    func importance(for place: Place, now: Date) -> ImportanceScore
}

/// Deterministic, explainable, per-Place scorer. Must never depend on other Places,
/// map density, or viewport — see RECOMMENDATION_MODEL.md §3.
struct DefaultRecommendationEngine: RecommendationEngine {
    private let recentlySavedWindow: TimeInterval = 14 * 24 * 60 * 60 // 14 days

    private let minimumRawScore: Double = -20
    private let maximumRawScore: Double = 75

    func importance(for place: Place, now: Date) -> ImportanceScore {
        var raw: Double = 0

        if place.isFavorite {
            raw += 40
        }

        if place.emotion == nil {
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
