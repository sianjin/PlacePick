# MomentMap — IMPLEMENTATION_GUIDE.md

Version: 3.0

Engineering Principles for Implementing MomentMap

---

# Mission

This document defines how MomentMap should be implemented.

Product documents define **what** the product is.

This guide defines **how those decisions are translated into software**.

Implementation exists to preserve the product.

Never change the product model because implementation is easier.

Instead, improve the implementation.

---

# Document Priority

Read the project documents in the following order.

1. MANIFESTO.md
2. DESIGN_PRINCIPLES.md
3. DESIGN_LANGUAGE.md
4. MVP.md
5. DATA_MODEL.md
6. PLACE_CREATION.md
7. IMPORT_PIPELINE.md
8. RECOMMENDATION_MODEL.md
9. UI_STRUCTURE.md
10. COLLECTIONS.md
11. IMPLEMENTATION_GUIDE.md

Higher documents define intent.

Lower documents define implementation.

Implementation must never contradict higher-level documents.

---

# Architecture Overview

Every layer has exactly one responsibility.

```
World
    │
    ▼
Import
    │
    ▼
Identity
    │
    ▼
Relationship
    │
    ▼
Recommendation
    │
    ▼
Presentation
```

Each layer should remain independent.

Implementation should preserve these boundaries.

---

# Architecture Mapping

| Layer | Primary Document | Responsibility |
|--------|------------------|----------------|
| World | MANIFESTO.md | Product philosophy |
| Principles | DESIGN_PRINCIPLES.md | Product architecture |
| Language | DESIGN_LANGUAGE.md | User-facing terminology |
| Identity | PLACE_CREATION.md | Canonical Place identity |
| Relationship | DATA_MODEL.md | User relationship with Places |
| Import | IMPORT_PIPELINE.md | External content → Place |
| Recommendation | RECOMMENDATION_MODEL.md | Compute importance |
| Presentation | UI_STRUCTURE.md | User interface |

When implementation questions arise, consult the document responsible for that layer.

---

# Implementation Principles

## Preserve Layer Boundaries

Every layer performs exactly one responsibility.

Examples:

- Import imports.
- Creation creates.
- Recommendation recommends.
- Presentation renders.

Never merge responsibilities simply because it is convenient.

---

## Respect the Product Model

The architecture defines the software.

Implementation follows the architecture.

Do not redesign the product during implementation.

If implementation becomes difficult, improve the implementation—not the model.

---

## Reuse Before Creating

Prefer extending existing flows over creating parallel ones.

For example:

- Replace Place should reuse the same MapKit search flow as Add Place.
- Shared UI should reuse common components.

Every duplicate implementation increases long-term maintenance cost.

---

## Prefer Explicit Facts

Use explicit information whenever possible.

Never replace facts with hidden assumptions.

Prefer:

- Apple Maps identity
- User input
- Stored data

Avoid:

- Guessing
- Prediction
- Hidden heuristics

Deterministic behavior is preferred over clever behavior.

---

## Respect Ownership

Apple Maps owns:

- Place identity
- Search
- Coordinates
- Navigation
- Business metadata

MomentMap owns:

- Collections
- Favorites
- Emotions
- Notes
- Memory Photos

Do not duplicate Apple's responsibilities.

---

## Preserve Semantic Values

Absence can be meaningful.

For example:

```
emotion == nil
```

means:

The user has not recorded an emotion.

Do not replace semantic values with arbitrary defaults.

---

## Reuse Product Vocabulary

Never introduce new user-facing terminology.

Always reuse the canonical vocabulary defined in DESIGN_LANGUAGE.md.

Examples:

Use:

- Place
- Collection
- Favorite
- Emotion

Avoid:

- Item
- Category
- Bookmark
- Rating

Consistent language produces a consistent product.

---

# Before Writing Code

Before implementing any feature, ask:

- Which architectural layer owns this responsibility?
- Does an existing flow already solve this problem?
- Am I duplicating Apple Maps?
- Am I mixing two architectural layers?
- Am I introducing hidden assumptions?
- Am I preserving the product vocabulary?
- Is this implementation simpler?
- Is the behavior deterministic?

If the answer reveals an architectural conflict, redesign the implementation.

---

# Coding Style

Prefer:

- Small views
- Small services
- Small models
- Small functions
- Composition
- Value types

Avoid:

- Large managers
- Massive view models
- Deep inheritance
- Global mutable state
- Premature abstraction

Code should be easy to understand before it becomes easy to extend.

---

# Testing Philosophy

Test product invariants rather than implementation details.

Important invariants include:

- A new Place has no Emotion.
- Identity replacement preserves the Relationship.
- Recommendation is deterministic.
- Recommendation never depends on other Places.
- Presentation never changes stored data.
- Rendering never changes recommendation results.

Tests should protect architecture rather than implementation.

---

# Technical Stack

Current implementation stack:

- Swift
- SwiftUI
- MapKit
- SwiftData
- CloudKit
- PhotosPicker
- Share Extension
- SF Symbols

Future technologies may change.

The architecture should not.

---

# Final Principles

> Preserve the architecture.

> One responsibility per layer.

> Reuse before creating.

> Prefer explicit facts over hidden assumptions.

> Simplicity is easier to maintain than cleverness.