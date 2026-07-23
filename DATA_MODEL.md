# PlacePick — DATA_MODEL.md

Version: 5.0
Status: Domain and Persistence Specification

---

# Purpose

This document defines the domain model used by the PlacePick data layer.

It describes the persistent objects, their relationships, and the invariants that every implementation must preserve.

This document intentionally focuses on product concepts rather than database schemas or implementation details.

It answers:

- What objects exist?
- What does each object represent?
- Which data is authoritative?
- Which data is editable?
- Which data is derived?
- Which relationships must always remain true?

---

# Relationship to Other Documents

This document should be read together with:

- MVP.md
- COLLECTIONS.md
- RECOMMENDATION_MODEL.md
- PLACE_CREATION.md

Responsibilities are divided as follows.

MVP.md defines:

- Product philosophy
- User experience
- Core concepts

COLLECTIONS.md defines:

- Collection philosophy
- Collection ownership
- Collection import
- Collection merge behavior

RECOMMENDATION_MODEL.md defines:

- Importance calculation

This document defines:

- Domain objects
- Data ownership
- Relationships between objects
- Persistence invariants
- Engineering invariants

It intentionally does not redefine Collection philosophy already established elsewhere.

---

# Modeling Principles

The PlacePick data model represents relationships rather than simply records.

Every stored object exists because it models part of the user's relationship with meaningful Places.

Whenever possible, product meaning should be represented directly rather than inferred from implementation details.

The model should remain:

- predictable
- portable
- deterministic
- implementation-independent

---

# Domain Overview

The PlacePick domain consists of four primary concepts.

```text
Collection

        │
        │ 1
        │
        │
        │ *
      Place
        │
        ├───────────────┐
        │               │
        ▼               ▼

Place Identity    Personal Relationship

        │
        ▼

Recommendation
(derived)
```

Collections organize Places.

Places represent real-world locations.

Every Place contains two conceptually separate layers:

- Identity
- Personal Relationship

Recommendation is computed from those layers.

It is never authoritative.

---

# Core Object Model

The central object in PlacePick is Place.

Conceptually:

```text
Place

├── Identity

├── Personal Relationship

└── Persistence Metadata
```

These three layers answer different questions.

Identity answers:

> What real-world Place is this?

Relationship answers:

> What does this Place mean to me?

Persistence Metadata answers:

> How is this Place stored and synchronized?

These layers should never be conflated.

---

# Place Identity

Place Identity represents the real-world Place.

For the MVP it is resolved through Apple Maps.

Conceptually it contains:

- Apple Maps identifier
- Place name
- Latitude
- Longitude
- Necessary MapKit-derived identity metadata

Identity is authoritative.

Users do not freely edit Place Identity.

If an incorrect Apple Maps result was selected, Place Identity is corrected through the Replace Place flow.

Changing Identity must preserve Personal Relationship whenever possible.

Identity is portable.

Identity may be shared between users.

Identity may participate in duplicate detection.

Identity is never derived from Recommendation.

---

# Personal Relationship

Personal Relationship represents everything the user records about a Place.

Conceptually it contains:

- Collection membership
- Favorite
- Emotion
- Note
- Memory Photo

Relationship belongs entirely to the user.

Relationship is editable.

Relationship is independent from Apple Maps.

Changing Relationship must never modify Place Identity.

Relationship is intentionally local.

Unless explicitly stated elsewhere, Relationship does not transfer between users.

Collection membership belongs to the Relationship layer rather than the Identity layer.

---

# Persistence Metadata

Persistence Metadata exists only to support storage and synchronization.

Examples include:

- Stable local identifier
- Creation timestamp
- Modification timestamp
- Deletion timestamp

Persistence Metadata is not part of product meaning.

Users never edit it directly.

Recommendation never depends on local identifiers.

Persistence Metadata should never appear in the user interface.

Its purpose is solely to support reliable persistence.

---

# Collection

Collection is a separate domain object.

Collection ownership and behavior are defined in COLLECTIONS.md.

This document defines only how Collections relate to Places.

Conceptually:

```text
Collection

├── Identity

└── Metadata
```

Collection Identity exists only to provide stable references.

Collection Metadata includes:

- Name
- Icon
- Order

Collection Metadata belongs entirely to the owner.

Merge behavior for Collection Metadata is defined in COLLECTIONS.md.

A Place stores only a reference to a Collection.

Conceptually:

```text
collectionID
```

rather than duplicating Collection information.

This guarantees a single authoritative Collection definition.

---

# Place–Collection Relationship

The relationship between Places and Collections is:

```text
Collection

1

↓

*

Place
```

Every Place belongs to exactly one Collection.

Every Collection may contain zero or more Places.

Multiple Collection membership is intentionally unsupported.

This invariant simplifies:

- browsing
- filtering
- synchronization
- import
- merge
- recommendation

Changing Collection changes only the user's organization.

It does not change:

- Place Identity
- Recommendation logic
- Apple Maps information

---

# Emotion Model

Emotion is intentionally modeled as an optional value.

Conceptually:

```swift
enum PlaceEmotion {

    case neutral

    case happy

    case amazed

}

var emotion: PlaceEmotion?
```

The four semantic states are:

| Stored Value | Meaning | UI |
|--------------|---------|----|
| `nil` | No personal experience recorded | No emoji |
| `.neutral` | "It was okay." | 😐 |
| `.happy` | "Loved it." | 😊 |
| `.amazed` | "Unforgettable." | 🤩 |

`nil` is not the same as `.neutral`.

No separate visited flag exists.

A Place may:

- not yet have been visited
- have been visited without recording Emotion

Those situations intentionally share the same state.

The data model preserves that ambiguity.

---

# Editable vs Authoritative Data

The data model intentionally separates user-editable information from authoritative identity.

Directly editable:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Authoritative:

- Apple Maps identifier
- Place name
- Coordinates
- Place Identity

Changing authoritative data always requires Replace Place.

Changing editable data never changes Place Identity.

---

# Part 1 Summary

The PlacePick domain model is built on three ideas.

1.

Every Place has an Identity.

2.

Every Place has a Personal Relationship.

3.

Persistence exists to support those concepts rather than define them.

Everything else in the data model—including sharing, import, merge, recommendation, and synchronization—builds on these three foundations.

---

# Ownership Representation

Ownership is a product concept defined in COLLECTIONS.md.

This document defines only how ownership is represented in the data model.

In the MVP:

Local storage implicitly represents ownership.

Every Collection stored in the local database is owned by the current user.

Every Personal Relationship belongs to the current user.

Ownership is therefore determined by storage location rather than an explicit owner identifier.

This keeps the MVP simple while remaining compatible with future multi-user features.

---

# Local Identity vs Shared Identity

PlacePick distinguishes between local objects and portable objects.

Local objects exist only inside one user's Personal Map.

Portable objects exist only during sharing.

They intentionally use different representations.

```text
Local Database

Collection
Place
Relationship

↓

Share

Collection Snapshot
Shared Place Identity
```

Local records are authoritative.

Shared objects are temporary.

Imported data always becomes new local records.

---

# Portable vs Local Data

Not every piece of information may leave the local database.

The following table defines portability.

| Data | Portable | Notes |
|--------|-----------|------|
| Place Identity | ✅ | Shared between users |
| Collection Snapshot | ✅ | Shared once |
| Collection Name | ✅ | Initial suggestion only |
| Collection Icon | ✅ | Initial suggestion only |
| Collection Membership | ⚠️ | Receiver chooses destination |
| Favorite | ❌ | Local only |
| Emotion | ❌ | Local only |
| Note | ❌ | Local only |
| Memory Photo | ❌ | Local only |
| Local IDs | ❌ | Never shared |
| Persistence Metadata | ❌ | Never shared |

The product intentionally shares Places rather than personal memories.

---

# Shared Place Identity

When a Place is shared, only its Identity is transferred.

Conceptually:

```swift
struct SharedPlaceIdentity {

    let appleMapsIdentifier: String?

    let name: String

    let latitude: Double

    let longitude: Double

}
```

This object contains only enough information to identify the Place.

It intentionally excludes:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

A shared Place never contains another person's memories.

---

# Shared Collection Snapshot

Sharing a Collection creates a snapshot.

Conceptually:

```swift
struct SharedCollectionSnapshot {

    let snapshotID: UUID

    let suggestedName: String

    let suggestedIcon: String

    let places: [SharedPlaceIdentity]

}
```

A Collection Snapshot represents:

> "These Places were grouped together by the sender."

It does not transfer:

- ownership
- permissions
- collaboration
- synchronization

After import, the snapshot no longer exists.

Only local Collections remain.

---

# Import Semantics

A Collection Snapshot may be imported in two ways.

```text
Import as New Collection

or

Merge into Existing Collection
```

The receiver always decides.

Import never changes existing data automatically.

---

# Import as New Collection

Import as New Collection creates:

- a new Collection
- new local identifiers
- new ownership

The imported Collection initially uses:

- shared name
- shared icon

for convenience.

Immediately after import:

the receiver owns the Collection completely.

Future changes made by the sender never affect it.

---

# Merge into Existing Collection

Instead of creating a new Collection, the receiver may merge into an existing Collection.

Only newly imported Places become members of that Collection.

Existing Places remain unchanged.

Collection metadata remains unchanged.

The receiver's organization is always authoritative.

---

# Existing Place Behavior

If an imported Place already exists locally:

The existing Place always wins.

The implementation preserves:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

The implementation never:

- duplicates the Place
- moves it automatically
- overwrites personal memories

Sharing expands a Personal Map.

It never rewrites one.

---

# Existing Collection Behavior

If the destination Collection already exists:

The Collection remains authoritative.

The following never change automatically:

- Name
- Icon
- Order

Only new Place membership may be added.

Collection metadata is never merged.

---

# Duplicate Resolution

Duplicate detection is based primarily on Place Identity.

The preferred order is:

1. Apple Maps identifier
2. Equivalent identity provided by MapKit
3. Fallback matching rules

Duplicate detection never considers:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Duplicate detection answers only:

> "Is this the same real-world Place?"

It never answers:

> "Are these the same memories?"

---

# Replace Place

Occasionally a user selects the wrong Apple Maps result.

Replace Place corrects Place Identity while preserving Personal Relationship.

Conceptually:

```text
Old Identity

↓

Replace

↓

New Identity

↓

Relationship preserved
```

The following remain unchanged whenever possible:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Replace Place updates the real-world reference.

It does not change what the Place means to the user.

---

# Relationship Preservation

The following rule applies throughout the product.

Whenever Place Identity changes:

Relationship should be preserved whenever possible.

Whenever Relationship changes:

Identity must never change.

This invariant is fundamental.

---

# Part 2 Summary

The PlacePick data model separates portable information from personal information.

Portable data exists to identify Places.

Personal data exists to describe the user's relationship with those Places.

Import creates new local ownership.

Merge preserves existing organization.

No sharing operation ever transfers personal memories or rewrites the receiver's Personal Map.


---

# Persistence Metadata

Persistence Metadata supports reliable storage and synchronization.

It is not part of the product domain.

Conceptually:

```swift
struct PersistenceMetadata {

    let id: UUID

    let createdAt: Date

    var modifiedAt: Date

    var deletedAt: Date?

}
```

These fields exist only to support:

- local persistence
- synchronization
- conflict resolution
- migration

They are never shown directly to users.

---

# Stable Local Identifiers

Every persistent object must have a stable local identifier.

Examples include:

- Place
- Collection

Local identifiers:

- never change
- survive application restarts
- survive synchronization
- are never reused

Local identifiers are implementation details.

They are intentionally different from Apple Maps identifiers.

---

# Creation and Modification

Every persistent object records:

- creation time
- most recent modification time

Creation time never changes.

Modification time updates whenever user-editable data changes.

Examples include:

- changing Collection
- editing Note
- changing Emotion
- toggling Favorite
- replacing Memory Photo

Updating synchronization metadata alone should not change the product meaning of a Place.

---

# Deletion Model

Deletion is represented using tombstones.

Conceptually:

```text
deletedAt == nil

↓

Active
```

```text
deletedAt != nil

↓

Deleted
```

Deleted records remain available internally until synchronization is complete.

This prevents deleted Places from being recreated during future merges or sync operations.

Deletion is therefore a synchronization concern rather than a user-visible concept.

---

# Synchronization Model

PlacePick follows a local-first architecture.

The local database is always immediately editable.

Cloud synchronization propagates changes asynchronously.

When iCloud is unavailable:

- all features continue to work
- data remains fully editable
- synchronization resumes automatically when available

The product should never require users to think about synchronization.

Synchronization supports the product.

It does not define the product.

---

# Conflict Resolution

Conflicts occur when the same object is modified independently before synchronization.

For the MVP:

Most editable fields use:

> Last Write Wins

based on:

```text
modifiedAt
```

This rule applies independently to each record.

Conflict resolution should remain deterministic.

Future versions may introduce field-level merge strategies where appropriate.

---

# Derived Data

Some values are computed rather than stored.

These values are derived.

Examples include:

- Importance Score
- Annotation size
- Visual prominence
- Recommendation ordering

Derived data is never authoritative.

If necessary, it can always be recomputed from authoritative data.

Authoritative examples include:

- Place Identity
- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Recommendation should never become the source of truth.

---

# Data Authority

Every piece of data should have exactly one authoritative source.

Examples:

| Data | Authority |
|------|-----------|
| Place Identity | Apple Maps |
| Collection Metadata | User |
| Personal Relationship | User |
| Persistence Metadata | Local database |
| Recommendation | Derived computation |

This principle prevents conflicting ownership and ambiguous updates.

---

# Engineering Invariants

The following rules are mandatory for every implementation.

## Identity

Identity and Personal Relationship are independent.

Changing one must not silently change the other.

---

## Relationship

Every Place belongs to exactly one Collection.

Relationship data belongs entirely to the user.

Relationship never participates in duplicate detection.

---

## Recommendation

Recommendation is derived.

Recommendation must never become persistent user data.

Deleting Recommendation must never lose user information.

---

## Import

Import creates new local ownership.

Import never overwrites:

- Note
- Emotion
- Favorite
- Memory Photo

Import never changes existing Collection organization automatically.

---

## Synchronization

Synchronization must preserve:

- stable identifiers
- timestamps
- semantic meaning

Synchronization must never silently change product behavior.

---

## Optional Values

Optional values carry semantic meaning.

For example:

```text
nil
≠
.neutral
```

Implementations must preserve this distinction exactly.

---

## Local Authority

The local Personal Map is always authoritative.

Sharing expands it.

Synchronization preserves it.

Neither operation should unexpectedly reorganize or rewrite it.

---

# Testing Requirements

Every implementation should include automated tests covering the following behaviors.

## Identity

- Identity survives Relationship edits.
- Replace Place preserves Relationship.
- Duplicate detection correctly identifies identical Places.

---

## Collection

- Places belong to exactly one Collection.
- Collections can be renamed.
- Collections can be reordered.
- Collections can be deleted only after Places are reassigned.

---

## Personal Relationship

- Favorite persists.
- Emotion preserves `nil`.
- Notes persist.
- Memory Photos persist.

---

## Import

- Import as New Collection creates new local identifiers.
- Merge into Existing Collection preserves Collection metadata.
- Existing Places preserve Relationship.
- Personal memories are never imported.

---

## Synchronization

- Stable identifiers remain unchanged.
- Tombstones synchronize correctly.
- Last Write Wins behaves deterministically.
- Offline edits synchronize correctly after reconnecting.

---

## Recommendation

- Recommendation can be regenerated entirely from authoritative data.
- Deleting cached recommendation data never changes product meaning.

---

# Final Principles

> The PlacePick data model represents relationships, not just records.

> Identity belongs to the world.

> Personal Relationship belongs to the user.

> Collections organize relationships rather than Places.

> Recommendation is derived, never authoritative.

> Synchronization supports the product rather than defining it.

> The local Personal Map is always the user's source of truth.