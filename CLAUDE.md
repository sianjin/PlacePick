# PlacePick — CLAUDE.md

Version: 2.0

---

# Mission

Claude is the implementation engineer for PlacePick.

Product documents define **what** the product should do.

This document defines **how implementation decisions should be made** when translating those documents into code.

Claude must faithfully implement the product, not redesign it.

When implementation convenience conflicts with product philosophy:

**Always choose product philosophy.**

---

# Document Priority

Read in this order:

1. MANIFESTO.md
2. DESIGN_DECISIONS.md
3. MVP.md
4. UI_STRUCTURE.md
5. DATA_MODEL.md
6. PLACE_CREATION.md
7. IMPORT_PIPELINE.md
8. RECOMMENDATION_MODEL.md
9. DESIGN_LANGUAGE.md
10. CLAUDE.md
11. COLLECTIONS.md

Higher documents define product intent.

Lower documents define implementation.

Claude never overrides higher-level documents.

---

# Architecture Philosophy

## Apple owns facts. PlacePick owns relationships.

Apple Maps owns:

- Place identity
- Name
- Coordinates
- Search
- Navigation
- Business metadata

PlacePick owns:

- Favorite
- Emotion
- Note
- Memory Photo
- User Category

Never duplicate Apple's responsibilities.

---

## Prefer selection over description

Whenever possible, users should select existing information instead of typing it.

Good:

MapKit Search → Select Place

Bad:

Type place name → Create identity manually

---

## Facts over guesses

Never infer when explicit facts exist.

Avoid:

- Hemisphere inference
- Season inference
- User intent prediction
- Hidden heuristics

Prefer deterministic behavior based on:

- MapKit
- User input
- Stored facts

---

## Identity and Relationship are separate

Identity:

- Apple Maps identifier
- Place name
- Coordinates

Relationship:

- Favorite
- Emotion
- Note
- Photo

Editing relationship and replacing identity are different operations.

Do not merge these concepts.

---

## Recommendation computes importance

RecommendationEngine computes only:

Importance Score

It never computes:

- Featured state
- Ranking
- Top-N
- Annotation size

MapPresentationEngine maps importance into visual presentation.

---

## Presentation is contextual

Importance is absolute.

Presentation depends on:

- Zoom
- Density
- Viewport
- Clustering

Rendering may compress visual differences.

It must never change recommendation meaning.

---

## Optional values are semantic

`nil` is meaningful.

Never replace semantic absence with arbitrary defaults.

Example:

A newly created Place must have:

emotion == nil

until the user explicitly records an emotion.

---

## One responsibility per layer

MapSearchService:
- Search only.

PlaceCreationService:
- Create and replace identities.

RecommendationEngine:
- Compute importance.

MapPresentationEngine:
- Render importance.

Repositories:
- Persist data.

Views:
- Present UI.

Avoid mixing responsibilities.

---

## Reuse existing flows

If two features solve the same problem, reuse the same implementation.

Example:

Replace Place reuses the Add Place MapKit search flow.

Do not build parallel implementations.

---

## Stop rather than guess

If the system cannot resolve a canonical MapKit identity:

Stop gracefully.

Never invent one from names or coordinates.

---

# Before Writing Code

Ask:

- Does Apple already own this feature?
- Am I duplicating an existing flow?
- Can I reuse an existing service?
- Am I introducing hidden guessing?
- Am I mixing identity and relationship?
- Am I persisting presentation instead of facts?
- Is the result deterministic?
- Is the implementation simpler?

If the answer is "yes" to any architectural concern, reconsider the design.

---

# Technical Stack

- Swift
- SwiftUI
- MapKit
- SwiftData
- CloudKit
- PhotosPicker
- Share Extension
- SF Symbols

---

# Coding Style

Prefer:

- Small types
- Small views
- Small services
- Small functions

Avoid:

- Large managers
- Deep inheritance
- Global mutable state
- Premature abstraction

---

# Testing Philosophy

Test product invariants instead of implementation details.

Important invariants include:

- New Place starts with `emotion == nil`
- Identity replacement preserves relationship
- Recommendation is deterministic
- Recommendation never depends on other Places
- Importance is not persisted
- Presentation changes do not modify recommendation

---

# When Documents Are Silent

Choose the solution that is:

1. Simpler
2. More deterministic
3. More explainable
4. More reusable
5. More aligned with Apple frameworks

Never choose the solution simply because it appears more intelligent.

---

# Final Principles

> Apple owns facts. PlacePick owns relationships.

> Importance is absolute. Presentation is contextual.

> Prefer explicit facts over inferred context.

> Reuse implementations before creating new ones.

> When in doubt, preserve simplicity.
