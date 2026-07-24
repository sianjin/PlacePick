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
    ) -> (place: Place, visit: Visit?) {
        let place = Place(
            appleMapIdentifier: "test-id",
            name: "Test Place",
            latitude: 0,
            longitude: 0,
            collection: testCollection,
            isFavorite: isFavorite,
            createdAt: createdAt
        )
        // Matches the single-Visit compatibility shim: nil visit means no Emotion
        // was ever recorded, same meaning as the old `Place.emotion == nil`.
        let visit: Visit? = emotion.map { Visit(place: place, emotion: $0) }
        return (place, visit)
    }

    @Test func favoriteWithNoEmotionScoresHighest() {
        let (place, visit) = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let (other, otherVisit) = makePlace(isFavorite: false, emotion: .happy, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: place, activeVisit: visit, now: now).value > engine.importance(for: other, activeVisit: otherVisit, now: now).value)
    }

    @Test func noEmotionScoresHigherThanRecordedEmotion() {
        let (unresolved, unresolvedVisit) = makePlace(emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let (resolved, resolvedVisit) = makePlace(emotion: .neutral, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: unresolved, activeVisit: unresolvedVisit, now: now).value > engine.importance(for: resolved, activeVisit: resolvedVisit, now: now).value)
    }

    @Test func nilAndNeutralProduceDifferentScores() {
        let (nilPlace, nilVisit) = makePlace(emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))
        let (neutralPlace, neutralVisit) = makePlace(emotion: .neutral, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: nilPlace, activeVisit: nilVisit, now: now).value != engine.importance(for: neutralPlace, activeVisit: neutralVisit, now: now).value)
    }

    @Test func recentlySavedReceivesSmallBoost() {
        let (recent, recentVisit) = makePlace(emotion: .happy, createdAt: now.addingTimeInterval(-1 * 86400))
        let (old, oldVisit) = makePlace(emotion: .happy, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: recent, activeVisit: recentVisit, now: now).value > engine.importance(for: old, activeVisit: oldVisit, now: now).value)
    }

    @Test func scoreIsDeterministicForSameFacts() {
        let (place, visit) = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))

        let first = engine.importance(for: place, activeVisit: visit, now: now).value
        let second = engine.importance(for: place, activeVisit: visit, now: now).value

        #expect(first == second)
    }

    @Test func scoreDoesNotDependOnOtherPlaces() {
        let (place, visit) = makePlace(isFavorite: true, emotion: nil, createdAt: now.addingTimeInterval(-100 * 86400))

        let scoreAlone = engine.importance(for: place, activeVisit: visit, now: now).value

        // Simulate other places existing by constructing them; the engine must never
        // take them as input, so the score for `place` must be unaffected.
        _ = (0..<50).map { _ in makePlace(isFavorite: true, emotion: nil, createdAt: now) }

        let scoreWithOthersPresent = engine.importance(for: place, activeVisit: visit, now: now).value

        #expect(scoreAlone == scoreWithOthersPresent)
    }

    @Test func scoreStaysWithinNormalizedRange() {
        let (mostImportant, mostImportantVisit) = makePlace(isFavorite: true, emotion: nil, createdAt: now)
        let (leastImportant, leastImportantVisit) = makePlace(isFavorite: false, emotion: .amazed, createdAt: now.addingTimeInterval(-100 * 86400))

        #expect(engine.importance(for: mostImportant, activeVisit: mostImportantVisit, now: now).value <= 1.0)
        #expect(engine.importance(for: leastImportant, activeVisit: leastImportantVisit, now: now).value >= 0.0)
    }
}
