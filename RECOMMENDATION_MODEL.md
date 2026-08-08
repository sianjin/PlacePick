# MomentMap — RECOMMENDATION_MODEL.md

Version: 4.0
Status: Attention and Recommendation Specification

---

# Purpose

This document defines how MomentMap decides which saved Places deserve the user's attention.

Recommendation exists to help users rediscover meaningful Places they have already saved.

It answers one question:

> **Which Places deserve more attention right now?**

It does **not** answer:

- Which Place is objectively better.
- Which Place should be visited next.
- Which Place other users recommend.
- Which Place is currently popular.

Recommendation is entirely personal.

It interprets the user's existing relationship with Places.

---

# Relationship to Other Documents

This document should be read together with:

- MVP.md
- COLLECTIONS.md
- DATA_MODEL.md
- UI_STRUCTURE.md

Responsibilities are divided as follows.

MVP.md defines:

- Product philosophy
- User experience
- Core product concepts

COLLECTIONS.md defines:

- How users organize their Personal Map

DATA_MODEL.md defines:

- Place Identity
- Personal Relationship
- Persistence

This document defines:

- How Personal Relationships become Attention
- How Importance is computed
- The boundary between Recommendation and Presentation

UI_STRUCTURE.md defines:

- How Recommendation is visually expressed.

Recommendation never changes the underlying data model.

It only interprets it.

---

# Attention Model

Recommendation is an interpretation layer.

Conceptually:

```text
Place Identity
        │
        ▼
Personal Relationship
        │
        ▼
Recommendation Model
        │
        ▼
Importance
        │
        ▼
Presentation
```

Each layer has a different responsibility.

Place Identity answers:

> What Place is this?

Personal Relationship answers:

> What does this Place mean to me?

Recommendation answers:

> How much attention does this Place deserve now?

Presentation answers:

> How should that attention appear on the map?

These responsibilities should never overlap.

---

# Recommendation Principles

Recommendation should always remain:

- Personal
- Explainable
- Deterministic
- Lightweight
- Local-first
- Independent of other Places

Recommendation should never become:

- Social ranking
- AI prediction
- Popularity scoring
- Behavioral profiling

The product intentionally recommends from the user's own map rather than from the world's Places.

---

# Importance

Recommendation produces exactly one output:

> **Importance**

Importance represents:

> **How much attention this Place deserves from its owner at this moment.**

Importance is not:

- Quality
- Rating
- Popularity
- Search relevance
- Travel priority

A highly important Place is simply one that deserves to be rediscovered sooner.

---

# Recommendation Is Not Ranking

MomentMap does not rank Places against one another.

Importance is absolute.

It is not relative.

A Place's Importance depends only on:

- its own stored facts
- explicit application state

It never depends on:

- neighboring Places
- viewport competition
- Top-N selection
- percentile ranking
- global popularity

Adding another Place must never reduce the Importance of an existing Place.

Every Place is evaluated independently.

---

# Recommendation Is Relationship-Derived

Recommendation is derived entirely from the Personal Relationship layer.

Conceptually:

```text
Place Identity
        │
        └──────┐
               │
               ▼
Personal Relationship
        │
        ▼
Recommendation
```

Recommendation does not interpret:

- Place category
- Geographic region
- Restaurant vs Hotel
- Apple Maps metadata

Instead it interprets:

- Favorite
- Emotion
- Creation time
- Other explicit relationship signals

Identity determines what a Place is.

Relationship determines how important it becomes.

---

# Attention Semantics

Recommendation expresses attention rather than value.

For example:

A Favorite Place receives higher Importance not because it is objectively better than other Places.

It receives higher Importance because the user has explicitly said:

> "This Place matters more to me."

Likewise:

A Place without a recorded Emotion may receive higher Importance because it represents an unfinished personal experience.

Recommendation therefore models:

> Attention

rather than:

> Quality.

---

# Attention Signals

The MVP Recommendation Model uses only explicit user-owned signals.

Examples include:

- Favorite
- Emotion
- Recently saved

Future versions may introduce additional explicit signals.

Recommendation intentionally avoids inferring hidden intent from:

- current GPS location
- hemisphere
- season
- travel plans
- browsing history
- user personality

Every recommendation should be understandable from visible user data.

---

# Explainability

Every Importance contribution should be explainable.

Examples:

```text
Favorite

↓

This Place receives more attention because you explicitly marked it as a Favorite.
```

```text
No Emotion Recorded

↓

This Place receives more attention because you have not yet recorded a personal experience.
```

```text
Recently Saved

↓

This Place receives a temporary visibility boost because it was recently added.
```

Users should always be able to understand why a Place appears more prominent.

Recommendation should never depend on invisible heuristics that cannot be explained.

---

# Part 1 Summary

Recommendation is an interpretation layer.

It transforms Personal Relationships into Attention.

Attention becomes Importance.

Presentation decides how that Importance appears on the map.

Recommendation never changes the user's data.

It only helps users rediscover what already belongs to their Personal Map.

---

# Importance Model

Recommendation converts explicit Personal Relationships into a continuous Importance value.

Conceptually:

```text
Personal Relationship
        │
        ▼
Recommendation Model
        │
        ▼
Importance
```

Importance is always derived.

It is never edited directly.

It is never shared.

It is never synchronized.

If necessary, it can always be recomputed from authoritative user data.

---

# Derived Data

Importance belongs to the derived layer of the product.

It exists only to support rediscovery.

Authoritative data includes:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Derived data includes:

- Importance
- Annotation priority
- Suggested visual prominence

Deleting derived data must never lose product meaning.

Derived values should always be reproducible.

---

# MVP Signals

The MVP intentionally uses only explicit, user-owned signals.

| Signal | Initial Weight |
|---------|---------------:|
| Favorite | +40 |
| No Emotion Recorded | +30 |
| Emotion Recorded | -20 |
| Recently Saved | +5 |

These values are initial defaults.

They are product tuning parameters rather than product principles.

Future versions may adjust individual weights without changing the overall recommendation model.

---

# Signal Philosophy

Every recommendation signal should satisfy three principles.

## Explicit

Signals should originate from deliberate user actions.

Examples:

- marking Favorite
- recording Emotion
- saving a Place

Signals should not be inferred from hidden behavioral analysis.

---

## Stable

Recommendation should not fluctuate dramatically from hour to hour.

Signals should change only when meaningful user data changes.

Stable recommendations help users build trust in the product.

---

## Explainable

Every signal should have a clear explanation.

For example:

```text
Favorite

↓

This Place receives more attention because you explicitly marked it as important.
```

The product should never produce recommendations that cannot be explained to the user.

---

# Example MVP Formula

Conceptually:

```text
importance = 0

if favorite:
    importance += 40

if emotion == nil:
    importance += 30
else:
    importance -= 20

if recentlySaved:
    importance += 5
```

The exact implementation may evolve.

The conceptual structure should remain simple.

Recommendation should remain understandable without requiring machine learning.

---

# Continuous Importance

Recommendation produces a continuous value.

Conceptually:

```text
0.0
──────────────►
1.0
```

Recommendation intentionally avoids discrete labels such as:

- Featured
- Recommended
- Highlighted
- Top Pick

Those concepts belong to presentation rather than recommendation.

Continuous Importance provides a more flexible foundation for future rendering.

---

# Normalization

Raw signal contributions may be normalized before presentation.

For example:

```text
Raw Score

↓

Normalization

↓

Importance
```

Normalization exists only to produce a stable public output.

The exact mathematical implementation is an engineering detail.

The recommendation contract is simply:

Higher Importance means the Place deserves more attention.

---

# Runtime Computation

Importance should be computed when needed.

The product should persist only authoritative facts.

Examples:

Persist:

- Favorite
- Emotion
- CreatedAt

Do not persist:

- Raw Score
- Importance
- Annotation Size
- Label Visibility

Importance should always be reproducible.

---

# Determinism

Recommendation must be deterministic.

Given the same:

- Personal Relationship
- current time
- product version

Recommendation must always produce the same Importance.

Deterministic behavior makes recommendation:

- testable
- explainable
- predictable

---

# No Hidden Context

Recommendation intentionally ignores hidden contextual information.

Examples include:

- hemisphere
- current GPS position
- device locale
- weather
- season
- travel intent
- browsing history
- user personality

The MVP recommendation model relies only on explicit user-owned information.

Future versions may introduce additional explicit metadata, but should avoid opaque inference whenever possible.

---

# Performance

Recommendation should remain inexpensive enough to compute locally.

Requirements include:

- no network dependency
- no cloud service
- no machine learning model
- no server-side ranking
- no full-dataset sorting
- no percentile computation
- no cross-Place comparison

Every Place should be scoreable independently.

This allows recommendation to scale naturally as the user's Personal Map grows.

---

# Recommendation Independence

Recommendation evaluates one Place at a time.

Conceptually:

```text
Place A

↓

Importance A
```

```text
Place B

↓

Importance B
```

Each computation is independent.

Adding, deleting, or modifying another Place must never change the Importance of an unrelated Place.

Recommendation therefore scales linearly with the number of Places.

---

# Part 2 Summary

Recommendation transforms explicit Personal Relationships into continuous Importance.

Importance is derived rather than stored.

Every recommendation should be:

- explicit
- deterministic
- explainable
- inexpensive
- reproducible

Recommendation intentionally favors transparent user-owned signals over hidden behavioral inference.

---

# Presentation Boundary

Recommendation determines **Importance**.

Presentation determines **Visibility**.

These are separate responsibilities.

Conceptually:

```text
Personal Relationship
        │
        ▼
Recommendation
        │
        ▼
Importance
        │
        ▼
Presentation
        │
        ▼
Map
```

Recommendation never decides:

- symbol size
- label visibility
- clustering
- annotation overlap
- viewport layout

Those decisions belong entirely to Presentation.

---

# Recommendation vs Presentation

Recommendation answers:

> **How much attention does this Place deserve?**

Presentation answers:

> **How should that attention appear on the current map?**

These questions intentionally remain independent.

Importance should remain stable.

Presentation may change continuously.

---

# Presentation Inputs

Presentation receives:

- visible Places
- Importance
- current viewport
- zoom level
- annotation density
- cluster state

Conceptually:

```text
Visible Places
      │
      ▼

Importance
      │
      ▼

Presentation
      │
      ▼

Map
```

Presentation combines stable Importance with transient viewing context.

---

# Density Adaptation

Presentation may compress visual differences when many Places compete for space.

Examples include:

- reducing symbol-size variation
- showing fewer labels
- increasing clustering
- delaying annotation expansion

These adjustments improve readability.

They do not change Importance.

A Place remains equally important even when visual differences become smaller.

---

# Zoom Adaptation

Presentation may express Importance differently at different zoom levels.

At broad zoom levels:

- clustering is preferred
- labels are limited
- symbol-size differences are reduced

At neighborhood zoom levels:

- more labels may appear
- symbol-size differences become clearer
- clustering is reduced

Zoom changes presentation.

It never changes recommendation.

---

# No Hidden Reclassification

Presentation must never silently redefine Importance.

For example:

```text
Place A

Importance = High
```

remains:

```text
Importance = High
```

even if:

- additional Places enter the viewport
- the user zooms out
- clustering occurs

Presentation may temporarily reduce visual prominence.

It must never rewrite recommendation meaning.

---

# Recommendation and Availability

Recommendation changes attention.

It never changes availability.

Recommendation never:

- hides saved Places
- removes Places from search
- changes Collection membership
- modifies Favorites
- edits Emotion
- moves Places
- changes Place Identity

Every saved Place remains part of the Personal Map regardless of Importance.

---

# Engineering Invariants

Every implementation must preserve the following rules.

## Importance Is Derived

Importance is computed.

It is never stored as authoritative data.

Deleting cached recommendation data must never lose user information.

---

## Importance Is Stable

Given the same:

- Personal Relationship
- current time
- product version

Recommendation always produces the same Importance.

---

## Presentation Is Contextual

Presentation depends on:

- viewport
- zoom
- density

Recommendation does not.

---

## Recommendation Never Changes Data

Recommendation is read-only.

It never modifies:

- Place Identity
- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Recommendation interprets user data.

It never edits it.

---

## Presentation Never Changes Recommendation

Presentation may compress or expand visual differences.

It must never:

- recalculate Importance
- reinterpret Recommendation
- introduce hidden ranking

Recommendation remains the single source of truth for attention.

---

# Testing Requirements

Every implementation should include automated tests covering the following behaviors.

## Recommendation

- The same input always produces the same Importance.
- Recommendation depends only on explicit signals.
- Adding unrelated Places does not change existing Importance.
- Recommendation remains explainable.

---

## Presentation

- Different zoom levels preserve Recommendation.
- Density compression does not change Importance.
- Clustering does not change Recommendation.
- Label visibility does not affect Importance.

---

## Separation of Responsibilities

- Recommendation never edits persistent data.
- Presentation never recalculates Recommendation.
- Deleting cached presentation state never changes product meaning.
- Recommendation remains reproducible from authoritative data.

---

# Final Principles

> Recommendation interprets relationships.

> Importance represents attention.

> Presentation expresses attention.

> Recommendation is absolute.

> Presentation is contextual.

> Derived data should never become authoritative.

> Recommendation never rewrites the user's Personal Map.

> Presentation may simplify what the user sees, but never what the user's data means.