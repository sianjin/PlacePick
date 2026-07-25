import Testing
import Foundation
@testable import PlacePick

struct RecommendationEngineTests {
    let engine = DefaultRecommendationEngine()
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let testCollection = PlaceCollection(name: "Test Collection", icon: "mappin", order: 0)

    private func makePlace(
        isFavorite: Bool = false,
        emotion: PlaceEmotion? = nil,
        createdAt: Date
    ) -> (place: Place, visits: [Visit]) {
        let place = Place(
            appleMapIdentifier: "test-id",
            name: "Test Place",
            latitude: 0,
            longitude: 0,
            collection: testCollection,
            isFavorite: isFavorite,
            createdAt: createdAt
        )
        // Empty visits means no Emotion was ever recorded, same meaning as the old
        // `Place.emotion == nil`.
        let visits: [Visit] = emotion.map { [Visit(place: place, emotion: $0)] } ?? []
        return (place, visits)
    }

    @Test func favoriteWithNoEmotionScoresHighest() {
        let (place, visits) = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let (other, otherVisits) = makePlace(isFavorite: false, emotion: .happy, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: place, visits: visits, now: now).value > engine.importance(for: other, visits: otherVisits, now: now).value)
    }

    @Test func noEmotionScoresHigherThanRecordedEmotion() {
        let (unresolved, unresolvedVisits) = makePlace(emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let (resolved, resolvedVisits) = makePlace(emotion: .neutral, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: unresolved, visits: unresolvedVisits, now: now).value > engine.importance(for: resolved, visits: resolvedVisits, now: now).value)
    }

    @Test func nilAndNeutralProduceDifferentScores() {
        let (nilPlace, nilVisits) = makePlace(emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let (neutralPlace, neutralVisits) = makePlace(emotion: .neutral, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: nilPlace, visits: nilVisits, now: now).value != engine.importance(for: neutralPlace, visits: neutralVisits, now: now).value)
    }

    @Test func recentlySavedReceivesSmallBoost() {
        let (recent, recentVisits) = makePlace(emotion: .happy, createdAt: now.addingTimeInterval(-1 * 86400))
        let (old, oldVisits) = makePlace(emotion: .happy, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: recent, visits: recentVisits, now: now).value > engine.importance(for: old, visits: oldVisits, now: now).value)
    }

    @Test func scoreIsDeterministicForSameFacts() {
        let (place, visits) = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))

        let first = engine.importance(for: place, visits: visits, now: now).value
        let second = engine.importance(for: place, visits: visits, now: now).value

        #expect(first == second)
    }

    @Test func scoreDoesNotDependOnOtherPlaces() {
        let (place, visits) = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))

        let scoreAlone = engine.importance(for: place, visits: visits, now: now).value

        // Simulate other places existing by constructing them; the engine must never
        // take them as input, so the score for `place` must be unaffected.
        _ = (0..<50).map { _ in makePlace(isFavorite: true, emotion: nil, createdAt: now) }

        let scoreWithOthersPresent = engine.importance(for: place, visits: visits, now: now).value

        #expect(scoreAlone == scoreWithOthersPresent)
    }

    @Test func scoreStaysWithinNormalizedRange() {
        let (mostImportant, mostImportantVisits) = makePlace(isFavorite: true, emotion: nil, createdAt: now)
        let (leastImportant, leastImportantVisits) = makePlace(isFavorite: false, emotion: .amazed, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: mostImportant, visits: mostImportantVisits, now: now).value <= 1.0)
        #expect(engine.importance(for: leastImportant, visits: leastImportantVisits, now: now).value >= 0.0)
    }

    @Test func mostRecentVisitDrivesScoreWhenMultipleExist() {
        let place = Place(appleMapIdentifier: "test-id", name: "Test Place", latitude: 0, longitude: 0, collection: testCollection, createdAt: now.addingTimeInterval(-100 * 86400))
        let older = Visit(place: place, startedAt: now.addingTimeInterval(-50 * 86400), emotion: nil)
        let mostRecent = Visit(place: place, startedAt: now.addingTimeInterval(-1 * 86400), emotion: .happy)

        // Most recent Visit has an emotion recorded, so the Place should score as
        // "resolved" (-20) even though an older Visit had no emotion (+30).
        let onlyOlder = engine.importance(for: place, visits: [older], now: now).value
        let both = engine.importance(for: place, visits: [older, mostRecent], now: now).value

        #expect(both < onlyOlder)
    }
}
