import Foundation

struct ImportanceScore {
    let value: Double
}

protocol RecommendationEngine {
    /// activeVisit is the Place's current Visit per the single-Visit compatibility shim
    /// (VisitRepository) — nil means no Emotion has ever been recorded, same meaning as
    /// the old `Place.emotion == nil`. Multi-Visit scoring is a later step.
    func importance(for place: Place, activeVisit: Visit?, now: Date) -> ImportanceScore
}

/// Deterministic, explainable, per-Place scorer. Must never depend on other Places,
/// map density, or viewport — see RECOMMENDATION_MODEL.md §3.
struct DefaultRecommendationEngine: RecommendationEngine {
    private let recentlySavedWindow: TimeInterval = 14 * 24 * 60 * 60 // 14 days

    private let minimumRawScore: Double = -20
    private let maximumRawScore: Double = 75

    func importance(for place: Place, activeVisit: Visit?, now: Date) -> ImportanceScore {
        var raw: Double = 0

        if place.isFavorite {
            raw += 40
        }

        if activeVisit?.emotion == nil {
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
