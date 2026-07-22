# PlacePick — DATA_MODEL.md

Version: 4.0

This document defines the core data model invariants for PlacePick.

It focuses on persistent product concepts rather than implementation details.

---

# Core Principles

## Identity vs Relationship

A Place contains two conceptually separate layers.

### Identity (owned by Apple Maps)

- Apple Maps identifier
- Place name
- Coordinates
- MapKit-derived metadata

### Relationship (owned by the user)

- Collection
- Favorite
- Emotion
- Note
- Memory photo

Identity and Relationship must never be conflated.

Identity answers:

> What place is this?

Relationship answers:

> What does this place mean to me?

---

# Collection Model

Collections are user-defined.

A Collection represents how the user chooses to organize their personal map.

Collections are not required to match Apple Maps place types.

Examples:

- Food
- Beach
- Date
- Family
- Japan 2027
- Photography

Collections belong entirely to the user.

---

## Collection Structure

Conceptually:

```swift
struct Collection {

    let id: UUID

    var name: String

    var icon: String

    var order: Int
}
```

A Place stores only:

```swift
collectionID
```

rather than duplicating Collection information.

---

## Collection Rules

Every Place belongs to exactly one Collection.

Collections may be:

- created
- renamed
- reordered
- deleted

Collections may use any supported SF Symbol.

There is intentionally no "Other" Collection.

If a user needs a new organizational structure, they should create a new Collection.

---

# Emotion Model

Emotion is intentionally modeled as an optional value.

```swift
enum PlaceEmotion {
    case neutral
    case happy
    case amazed
}

var emotion: PlaceEmotion?
```

The four semantic states are:

| Stored value | Meaning | UI |
|---|---|---|
| `nil` | No personal experience recorded | No emoji |
| `.neutral` | Recorded: "It was okay." | 😐 |
| `.happy` | Recorded: "Loved it." | 😊 |
| `.amazed` | Recorded: "Unforgettable." | 🤩 |

There is no separate `visited` flag.

`nil` does **not** mean "neutral."

`nil` means only that the user has not recorded an emotion.

The user may:

- not have visited yet
- have visited but not logged an emotion

Those situations intentionally share the same state.

---

# Editing Rules

Directly editable:

- Collection
- Favorite
- Emotion
- Note
- Memory photo

Not freely editable:

- Place name
- Coordinates
- Apple Maps identifier

Changing identity must use the Replace Place flow.

---

# Engineering Invariants

These rules are mandatory.

## 1. Identity and Relationship are separate

Changing relationship data must never modify identity.

Changing identity must preserve relationship data.

---

## 2. Every Place belongs to one Collection

Every Place references exactly one Collection.

Multiple Collections per Place are intentionally unsupported.

---

## 3. Collections are independent

Collections do not affect:

- Recommendation score
- Place identity
- Apple Maps metadata

Collections exist only for user organization.

---

## 4. Optional carries meaning

`nil` is a valid semantic state.

Never replace semantic absence with an arbitrary default value.

---

## 5. New Place invariant

A newly created Place must satisfy:

```swift
emotion == nil
```

unless the user explicitly records an emotion.

---

## 6. Nil and Neutral are different

The following must remain distinct:

```text
nil
≠
.neutral
```

They produce different recommendation behavior.

---

## 7. UI invariant

The emotion picker must clearly represent:

- no recorded emotion
- 😐
- 😊
- 🤩

It must never silently default to 😐.

---

## 8. Persistence invariant

Loading and saving a Place must preserve `nil` exactly.

Serialization must never convert:

```text
nil → .neutral
```

or

```text
.neutral → nil
```

---

# Testing Requirements

Every implementation should include tests covering:

## Collection

- New Collections can be created.
- Collections can be renamed.
- Collections can be reordered.
- Collections can be deleted.
- Every Place belongs to exactly one Collection.
- Deleting a Collection requires Places to be reassigned before removal.

## Emotion

- New Place defaults to `emotion == nil`
- `nil` renders with no emoji
- 😐 renders only after explicit user selection
- Recommendation score for `nil` differs from `.neutral`
- Saving and reloading preserves `nil`
- Clearing an emotion restores `nil`

These behaviors are part of the product contract, not implementation details.

---

# Final Principles

> Apple Maps owns place identity.

> Users own relationships.

> Collections organize memories, not places.

> Optional values carry semantic meaning.