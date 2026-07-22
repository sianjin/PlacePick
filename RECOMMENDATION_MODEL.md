# PlacePick — RECOMMENDATION_MODEL.md

Version: 3.0

---

## 1. Purpose

Recommendation helps users rediscover places they have already saved.

It answers:

> How important is this place to the user right now?

The recommendation model produces a continuous **Importance Score** for each saved Place.

It does not decide exactly how the Place should look on the map.

---

## 2. Core Principle

> Recommendation computes importance.  
> The map renderer decides presentation.

These are separate responsibilities.

The recommendation model must remain:

- Deterministic
- Explainable
- Lightweight
- Local-first
- Independent of other Places
- Independent of map density
- Independent of viewport ranking

---

## 3. Recommendation Is Not Ranking

PlacePick does not rank Places against one another.

A Place's Importance Score depends only on:

- Its own stored facts
- Explicit, stable application state

It does not depend on:

- How many other Places exist
- How many Places are visible
- The scores of neighboring Places
- Top-N selection
- Percentile ranking
- Relative competition

Adding another Place must not reduce the Importance Score of an existing Place.

---

## 4. Continuous Importance Score

The recommendation model returns a continuous numeric score.

Conceptually:

```text
Place facts
    ↓
Recommendation Model
    ↓
Importance Score
```

The model does not return:

- Normal
- Highlighted
- Featured
- Top Place
- Recommended Place

There are no fixed visual tiers in the recommendation layer.

---

## 5. MVP Signals

The MVP uses only explicit and explainable signals.

| Signal | Weight |
|---|---:|
| Favorite | +40 |
| No emotion recorded | +30 |
| Emotion recorded | -20 |
| Recently saved | +5 |

Season and hemisphere inference are not part of the MVP.

Map density, clustering, and viewport position are rendering concerns rather than recommendation signals.

---

## 6. Example MVP Formula

```text
importance = 0

if isFavorite:
    importance += 40

if emotion == nil:
    importance += 30
else:
    importance -= 20

if recentlySaved:
    importance += 5
```

The weights are initial defaults and may be tuned later.

The structure of the model should remain simple and explainable.

---

## 7. Score Range

The MVP score may be normalized to a stable range for rendering.

Recommended conceptual output:

```text
Importance Score: 0.0 ... 1.0
```

One possible normalization:

```text
rawScore = clamp(rawScore, minimumRawScore, maximumRawScore)

importance =
    (rawScore - minimumRawScore)
    /
    (maximumRawScore - minimumRawScore)
```

The exact normalization belongs to implementation details, but the public contract should expose a stable continuous value.

The renderer should not depend on hard-coded semantic thresholds such as:

```text
score >= 60 → featured
```

---

## 8. Explainability

Every score contribution must be explainable from visible user data.

Examples:

```text
Favorite
→ This place receives more importance because the user explicitly starred it.
```

```text
No emotion
→ This place receives more importance because the user has not yet recorded an experience.
```

```text
Recently saved
→ This place receives a small temporary visibility boost.
```

The model must not use invisible guesses about:

- Hemisphere
- Season
- Travel intent
- Device locale
- Current GPS region
- User personality
- Behavioral profiling

---

## 9. Runtime Computation

Importance is computed at runtime.

Do not persist:

- Raw recommendation score
- Normalized Importance Score
- Symbol size
- Label priority
- Cluster priority
- Visual tier

Persist only the facts needed to reproduce the score.

Examples of persisted facts:

- Favorite
- Emotion
- Created date
- Modified date

---

## 10. Map Renderer Responsibility

The Map Renderer receives:

- Visible Places
- Importance Scores
- Current viewport
- Zoom level
- Annotation density
- Cluster state

It maps Importance Scores into visual treatment.

Conceptually:

```text
Visible Places
+ Importance Scores
+ Viewport
+ Zoom
+ Density
    ↓
Map Renderer
    ↓
Symbol size
Label visibility
Display priority
Cluster behavior
```

The renderer may adapt presentation to prevent visual overload.

It must not change the underlying Importance Scores.

---

## 11. Density-Aware Presentation

When the map is sparse, importance differences may be expressed more clearly.

When the map is dense, the renderer may compress visual differences.

Examples:

- Reduce symbol-size spread
- Show fewer labels
- Increase clustering
- Use importance as annotation priority
- Prefer more important Places when cluster annotations are released

This is presentation adaptation, not recommendation ranking.

A Place remains equally important even when its visual treatment is compressed by density.

---

## 12. Zoom-Aware Presentation

At broad zoom levels:

- Prefer clustering
- Minimize symbol-size differences
- Show fewer labels
- Use Importance Score mainly for display priority

At neighborhood zoom levels:

- Allow clearer size differences
- Reveal more labels
- Reduce clustering
- Express Importance Score more directly

Zoom changes how importance is displayed, not how importance is computed.

---

## 13. No Fixed Featured Quota

The renderer does not need to guarantee:

- Exactly N featured Places
- A fixed top percentile
- A winner in every viewport

PlacePick is not a feed or leaderboard.

If many Places are important, they may all remain important.

The renderer's job is to keep the map readable without rewriting that meaning.

---

## 14. No Hidden Reclassification

The renderer must not silently redefine a Place's importance based on its neighbors.

For example:

```text
A Place does not become less important
because several other high-importance Places enter the viewport.
```

Only its visual expression may be compressed to preserve readability.

---

## 15. Recommendation and Availability

Recommendation changes prominence, not availability.

It never:

- Hides a saved Place
- Removes a Place from search
- Overrides user filters
- Changes the map position
- Modifies relationship data
- Deletes or demotes Favorites
- Reorders a user-authored collection

---

## 16. Season

Season-aware recommendation is out of scope for MVP.

PlacePick does not infer:

- Hemisphere
- Season from device locale
- Season from GPS position
- Season from map viewport
- Travel intent

Future seasonal behavior should require explicit metadata or explicit user input.

---

## 17. Performance

Recommendation must be inexpensive enough to recompute locally.

Requirements:

- No network dependency
- No machine learning model
- No server-side ranking
- No full-dataset sort
- No percentile computation
- No cross-Place comparison

Each Place should be scoreable independently.

The Map Renderer may process the visible set for layout and density management.

---

## 18. Suggested Architecture

```text
Place
  │
  ▼
RecommendationEngine
  │
  └── Importance Score
          │
          ▼
MapPresentationEngine
  │
  ├── Viewport
  ├── Zoom
  ├── Density
  └── Cluster State
          │
          ▼
Map Annotation Presentation
```

### RecommendationEngine

Responsible for:

- Reading explicit Place facts
- Computing raw importance
- Normalizing importance
- Returning a deterministic continuous score

Not responsible for:

- Annotation size
- Label visibility
- Clustering
- Viewport ranking
- Top-N selection

### MapPresentationEngine

Responsible for:

- Mapping importance into visual presentation
- Adapting to zoom and density
- Preserving readability
- Coordinating annotation and cluster priority

Not responsible for:

- Changing Importance Scores
- Interpreting Favorite or Emotion semantics
- Persisting recommendation state

---

## 19. Conceptual API

```swift
struct ImportanceScore {
    let value: Double
}

protocol RecommendationEngine {
    func importance(for place: Place, now: Date) -> ImportanceScore
}

protocol MapPresentationEngine {
    func presentation(
        for visiblePlaces: [VisiblePlace],
        viewport: MapViewport,
        zoomLevel: Double
    ) -> [PlacePresentation]
}
```

The exact implementation may differ, but the separation of responsibilities must remain.

---

## 20. MVP Success Criteria

The model succeeds when:

- The same Place receives the same Importance Score from the same facts
- Users can understand why a Place has higher importance
- Adding more Places does not alter existing scores
- The map remains readable at both low and high density
- Rendering adapts without changing recommendation meaning
- No hidden ranking system is introduced

---

## 21. Final Principles

> Importance is absolute. Presentation is contextual.

> Recommendation does not rank Places against one another.

> The renderer may compress visual differences, but it must not rewrite what the user's data means.

> Prefer explicit facts over inferred context.
