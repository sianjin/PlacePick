# MomentMap Data Model

## 1. Purpose

This document defines the persistent data model for MomentMap.

MomentMap is a personal memory system organized through places. The same stored data must support two primary browsing modes:

- **Map** — browse memories spatially
- **Calendar / Timeline** — browse memories temporally

This document defines entity ownership, relationship boundaries, photo-based visit creation, place resolution, derived views, deletion rules, and synchronization invariants.

---

# 2. Core Model

```text
Collection
    │
    └── Place
            │
            └── Visit
                    │
                    └── VisitPhoto
```

The user-facing term is **Memory**.

The persistence-layer term is **Visit**.

```text
User-facing language: Memory
Data-model language: Visit
```

A Memory is emotional and personal. A Visit is the objective record representing one experience at one Place during one time period.

---

# 3. Core Definitions

## 3.1 Place

A `Place` represents one canonical real-world location.

Its identity comes from Apple Maps and remains stable across multiple Visits.

A Place answers:

> Where did this happen?

---

## 3.2 Visit

A `Visit` represents one experience at one Place during one continuous time period.

A Visit may contain:

- one or more Photos
- one Emotion
- one Note

A Visit answers:

> What happened here this time?

A Place may have many Visits:

```text
Place
├── Visit — July 18, 2026
├── Visit — December 24, 2027
└── Visit — May 3, 2028
```

Each Visit is displayed to the user as a Memory.

---

## 3.3 VisitPhoto

A `VisitPhoto` represents one Photo attached to one Visit.

It is an independent entity because each Photo may need its own:

- capture time
- ordering
- Photos-library identifier
- durable stored-image reference
- optional location metadata
- deletion state
- synchronization state

---

## 3.4 Collection

A `Collection` organizes Places by user-defined meaning.

Examples:

- Coffee
- Weekend Trips
- Japan
- Date Ideas

Collections organize Places. Calendar and Timeline organize Visits by time. These are orthogonal organization systems.

---

# 4. Product-Level Ownership

The central ownership distinction is:

```text
Place = long-term relationship
Visit = one specific experience
```

| Data | Owner |
|---|---|
| Apple Maps identity | Place |
| Place name | Place |
| Coordinates | Place |
| Collections | Place |
| Favorite | Place |
| Experience time | Visit, derived from Photos |
| Emotion | Visit |
| Visit Note | Visit |
| Photos | Visit |
| Photo capture time | VisitPhoto |
| Calendar grouping | Derived |
| Timeline ordering | Derived |
| Daily Travel Log | Derived |
| Shareable Day Overview | Derived |

---

# 5. Favorite and Emotion

## 5.1 Favorite

Favorite belongs to Place.

It means:

> This is a Place I continue to value or want to keep prominent.

Favorite expresses a long-term relationship. A disappointing Visit does not necessarily make the Place unimportant.

```text
Place.isFavorite
```

---

## 5.2 Emotion

Emotion belongs to Visit.

It means:

> This is how that particular experience felt.

The same Place may have different Emotions across different Visits:

```text
Summer 2026     amazed ("Unforgettable")
Winter 2027     neutral ("Okay")
Spring 2028     happy ("Loved it")
```

```text
Visit.emotion
```

Emotion must never be treated as a permanent rating of the Place.

---

# 6. Place Entity

## 6.1 Proposed Fields

```text
Place
├── id
├── appleMapsIdentifier
├── name
├── latitude
├── longitude
├── isFavorite
├── createdAt
├── modifiedAt
├── deletedAt
├── collection
└── visits
```

## 6.2 Field Definitions

### `id`

```swift
id: UUID
```

Stable internal identifier used for persistence, synchronization, relationships, and tombstones.

### `appleMapsIdentifier`

```swift
appleMapsIdentifier: String
```

Canonical Apple Maps identity. It is the primary external identity signal for duplicate prevention and Place replacement.

It is not freely editable.

### `name`

```swift
name: String
```

Canonical display name derived from the selected Apple Maps result.

It is not freely editable.

### `latitude`

```swift
latitude: Double
```

Canonical latitude derived from Apple Maps.

It is not freely editable.

### `longitude`

```swift
longitude: Double
```

Canonical longitude derived from Apple Maps.

It is not freely editable.

### `isFavorite`

```swift
isFavorite: Bool
```

Indicates whether the user continues to value or prioritize this Place.

Favorite belongs to Place, not Visit.

### Lifecycle fields

```swift
createdAt: Date
modifiedAt: Date
deletedAt: Date?
```

`deletedAt` is a tombstone timestamp. A non-nil value means the Place is logically deleted.

---

# 7. Visit Entity

## 7.1 Proposed Fields

```text
Visit
├── id
├── placeID
├── startedAt
├── endedAt
├── emotion
├── note
├── createdAt
├── modifiedAt
├── deletedAt
└── photos
```

## 7.2 Field Definitions

### `id`

```swift
id: UUID
```

Stable internal identifier.

### `placeID`

```swift
placeID: UUID
```

Every Visit belongs to exactly one Place.

A Visit cannot exist without a resolved Place. This is a hard invariant.

### `startedAt`

```swift
startedAt: Date
```

The earliest reliable capture time among the Visit's Photos.

Example:

```text
9:12
9:18
9:24
```

Then:

```text
startedAt = 9:12
```

Visit time is derived from Photo metadata. It is not normally entered manually.

### `endedAt`

```swift
endedAt: Date
```

The latest reliable capture time among the Visit's Photos.

For the same group:

```text
endedAt = 9:24
```

If a Visit contains one Photo:

```text
startedAt == endedAt
```

### `emotion`

```swift
emotion: PlaceEmotion?
```

Allowed values (Swift case → display label):

```text
nil
neutral   → "Okay"
happy     → "Loved it"
amazed    → "Unforgettable"
```

`nil` means no personal feeling has been recorded for this Visit.

It does not mean unvisited, and it does not describe the Place permanently.

### `note`

```swift
note: String?
```

A personal note about this specific Visit.

Examples:

```text
First time here with my parents.
```

```text
The winter view felt completely different.
```

### Lifecycle fields

```swift
createdAt: Date
modifiedAt: Date
deletedAt: Date?
```

`createdAt` records when the Visit record was created, not when the experience occurred.

Example:

```text
Visit happened: July 18, 2024
Imported into MomentMap: July 23, 2026
```

---

# 8. VisitPhoto Entity

## 8.1 Proposed Fields

```text
VisitPhoto
├── id
├── visitID
├── localAssetIdentifier
├── storedImageReference
├── capturedAt
├── latitude
├── longitude
├── sortOrder
├── createdAt
├── modifiedAt
└── deletedAt
```

## 8.2 Field Definitions

### `id`

```swift
id: UUID
```

Stable internal identifier.

### `visitID`

```swift
visitID: UUID
```

Every VisitPhoto belongs to exactly one Visit.

### `localAssetIdentifier`

```swift
localAssetIdentifier: String?
```

Optional Photos-library asset identifier.

It may help reconnect to the original asset on the current device, but it must not be the only durable reference because:

- the original Photo may be deleted
- another device may not expose the same local identifier
- synchronization may require MomentMap-managed storage

### `storedImageReference`

```swift
storedImageReference: String
```

Durable MomentMap-managed image reference.

The exact storage mechanism belongs in implementation and sync documentation.

**Not yet implemented — reference-only for MVP, durable copy deferred.** In the current
implementation this field is always a copy of `localAssetIdentifier`, not an independent
MomentMap-managed copy. This is a deliberate MVP tradeoff: a real durable copy would add
on-device storage growth and new implementation surface for a failure mode (original Photo
deleted, or viewing on a second device before it syncs) that is real but not yet common
enough to justify before MVP. Revisit if durability across deletion/multi-device becomes a
priority.

### `capturedAt`

```swift
capturedAt: Date
```

Reliable capture timestamp from Photo metadata.

MomentMap must not silently substitute import time, current time, or file creation time when reliable capture time is unavailable.

### `latitude` and `longitude`

```swift
latitude: Double?
longitude: Double?
```

Optional Photo-coordinate metadata.

Photo coordinates may:

- suggest candidate Places
- help cluster Photos
- narrow nearby Apple Maps searches

They do not establish canonical Place identity.

### `sortOrder`

```swift
sortOrder: Int
```

Stable user-visible ordering inside the Visit.

Default ordering follows `capturedAt`.

### Lifecycle fields

```swift
createdAt: Date
modifiedAt: Date
deletedAt: Date?
```

---

# 9. Photo Requirement

A Visit is photo-anchored.

```text
No Photo
    ↓
No Visit
```

A Visit must contain at least one Photo with reliable capture-time metadata.

This rule exists because:

- the Photo provides the temporal anchor
- the user does not need to manually enter time
- Calendar ordering remains trustworthy
- multiple Visits to the same Place remain distinguishable
- Travel Logs can be reconstructed automatically

A Place may still exist without any Visits.

For example:

```text
Saved for later
Favorite
Added to Collection
```

But a Visit cannot exist without at least one valid Photo.

---

# 10. Place-Level Content Without a Visit

Because Visits require Photos, non-visit information must remain separate.

Place-level fields may include:

- Favorite
- Collections

The MVP should avoid introducing a general Place Note unless there is a clear product need.

A Place Note and Visit Note have different meanings:

```text
Place Note
=
long-term information about the location
```

```text
Visit Note
=
personal meaning attached to one specific experience
```

If Place Note is introduced later, it must remain structurally separate from Visit Note.

---

# 11. Visit Boundaries

A Visit is not defined by one import action.

It is not defined by one selected batch.

A Visit is:

> One experience at one resolved Place during one continuous time period.

Therefore:

```text
One import session
may create
many Visits
```

Example:

```text
July 18, 2026

9:12   Blue Bottle
11:36  Golden Gate Bridge
13:48  Ferry Building
19:32  Nopa
```

This import creates four Visits attached to four Places.

---

# 12. Photo-First Import

Photo-first import is a separate input path into the same Place and Visit model.

## 12.1 Flow

```text
Select Photos
    ↓
Read capture times and coordinates
    ↓
Suggest Photo Groups
    ↓
User reviews boundaries
    ↓
Merge or split groups
    ↓
Suggest candidate Places
    ↓
User confirms one Place per group
    ↓
Create Visits
```

No Visit is written before final confirmation.

---

## 12.2 Photo Group

A Photo Group is a temporary import concept.

It is not a persistent Visit.

```text
PhotoImportGroup
├── photos
├── proposedStartTime
├── proposedEndTime
├── approximateCoordinate
├── suggestedPlaces
├── selectedPlace
└── status
```

The system may use:

- time gaps
- spatial distance
- Photo GPS
- chronological continuity

as grouping signals.

System grouping is only a proposal.

---

## 12.3 User Controls the Boundary

The user must be able to:

- accept a proposed group
- merge nearby groups
- split a group
- skip a group
- assign the group to a confirmed Place

Technical clustering does not always match human meaning.

Example:

```text
Hotel lobby
Hotel room
Hotel breakfast
```

The system may propose three groups. The user may decide they all belong to one Visit at:

```text
Hyatt Regency San Francisco
```

The reverse must also be possible. One system group around a shopping district may need to be split into several Visits.

---

# 13. Place Resolution

Photo metadata can suggest where something happened.

It cannot decide what Place the Visit belongs to.

The rule is:

> Location metadata narrows the search. The user confirms Place identity.

Each PhotoImportGroup must resolve to exactly one canonical Apple Maps Place before Visit creation.

The system should automatically provide the most likely Place candidate and nearby alternatives.

The user may:

- select the top suggested candidate
- choose another nearby candidate
- search Apple Maps
- merge the group with another group
- split the group
- skip the group

The user may not save a formal Visit anchored only to an approximate coordinate.

---

# 14. Unified Resolution Principle

The same Place-resolution rule applies across all creation paths.

## 14.1 Search-Based Creation

```text
Apple Maps Search
    ↓
User selects result
    ↓
Create or open Place
```

## 14.2 Social Import

```text
Imported text or link
    ↓
Extract search terms
    ↓
Suggest Apple Maps results
    ↓
User confirms Place
    ↓
Create or open Place
```

## 14.3 Photo-First Import

```text
Photo metadata
    ↓
Suggest nearby Apple Maps results
    ↓
User confirms Place
    ↓
Create Visit
```

All paths converge on the same canonical Place model.

---

# 15. Import Drafts

Import analysis uses temporary draft models.

Drafts are not confirmed user data.

## 15.1 PhotoImportDraft

```text
PhotoImportDraft
├── selectedPhotos
├── proposedGroups
├── createdAt
└── state
```

## 15.2 PhotoImportGroup

```text
PhotoImportGroup
├── id
├── photos
├── proposedStartTime
├── proposedEndTime
├── approximateLatitude
├── approximateLongitude
├── suggestedPlaceCandidates
├── selectedPlaceCandidate
└── status
```

Suggested statuses:

```text
unresolved
resolved
skipped
```

Only resolved groups are eligible for final import.

Drafts may remain in memory only for MVP unless resumable imports become a product requirement.

---

# 16. Place-First Visit Creation

Place-first creation begins from an already resolved Place.

```text
Open Place
    ↓
Add Memory
    ↓
Take or choose Photos
    ↓
Read Photo timestamps
    ↓
Review optional Emotion and Note
    ↓
Save Visit
```

Because the Place is already known, only Visit boundaries and Photos need confirmation.

If selected Photos clearly represent multiple time-separated Visits, the UI must not silently combine them.

The user should be asked to split or explicitly confirm the grouping.

---

# 17. Duplicate Rules

## 17.1 Place Duplicates

Primary signal:

```text
same appleMapsIdentifier
```

Supporting signals:

```text
very close coordinates
same normalized name within a small radius
```

A matching canonical Place should open the existing Place rather than create another record.

The MVP does not offer Save Another for the same real-world Place.

## 17.2 Visit Duplicates

Potential duplicate signals:

- same Place
- same VisitPhoto asset identifiers
- substantially overlapping Photo sets
- substantially overlapping time range

The system should prevent importing the same Photo into multiple active Visits unless a future explicit duplication feature is introduced.

## 17.3 VisitPhoto Ownership

A VisitPhoto belongs to one active Visit.

Moving a Photo between Visits should update its relationship rather than silently duplicate it.

---

# 18. Collection Model

## 18.1 Proposed Fields

```text
Collection
├── id
├── name
├── icon
├── order
├── modifiedAt
└── places
```

Unlike Place, Visit, and VisitPhoto, Collection has no `createdAt` or `deletedAt`. A
Collection can only be deleted once it contains no Places: deleting a non-empty Collection
requires the caller to supply a destination Collection, reassigns every member Place to it
first, then hard-deletes the now-empty Collection's row outright. Because a Collection can
never be removed while something still references it, there is no dangling-reference case
to guard against, so no tombstone is needed — deletion just happens immediately and for
real. See `CollectionRepository.delete(_:reassigningTo:)`.

A Place may belong to one or more Collections according to `COLLECTIONS.md`.

## 18.2 Collection Semantics

```text
Collection = semantic organization
Calendar = temporal organization
Map = spatial organization
```

These concepts must not be collapsed into one model.

---

# 19. Derived Views

The following are views, not persistent content entities.

## 19.1 Map

Map displays Places and may summarize their Visits.

Possible derived signals include:

- latest Visit
- Visit count
- recent Photos
- Favorite state
- recommendation Importance

## 19.2 Calendar

Calendar groups Visits by local calendar day.

```text
Calendar Day
    ↓
Visits where startedAt falls on that day
```

Calendar does not create duplicate records.

## 19.3 Timeline

Timeline sorts Visits chronologically.

```text
sort by startedAt
```

It may be displayed globally, by Place, by Collection, or by date range.

## 19.4 Daily Travel Log

Daily Travel Log is generated from Visits.

```text
Filter Visits by day
    ↓
Sort by startedAt
    ↓
Render map, Photos, Emotions, and Notes
```

It is not stored as a separate source of truth.

## 19.5 Shareable Day Overview

A shareable overview is a generated presentation of existing Visits.

It may include:

- date
- map or spatial overview
- Places
- Photos
- Notes
- Emotions
- timestamps

It must not duplicate user data.

---

# 20. Place Detail Projection

Place Detail renders one Place and its Visits.

```text
Place
├── Favorite
├── Collections
└── Memories
    ├── Visit A
    ├── Visit B
    └── Visit C
```

Each Visit may render:

```text
Date and time
Photos
Emotion
Visit Note
```

User-facing copy may say:

```text
Memories
Add Memory
```

The persistence model continues to use:

```text
Visit
```

---

# 21. Time and Time Zones

Photo capture times should preserve enough information to reconstruct the local experience time.

The implementation must consider:

- original capture timestamp
- original time zone when available
- device time zone
- travel across time zones
- local calendar-day grouping

The model must avoid permanently reinterpreting historical experiences in the user's current time zone.

Product invariant:

> A Visit should appear on the calendar day when it occurred locally.

---

# 22. Deletion Rules

## 22.1 Delete Place

Deleting a Place logically deletes:

- the Place
- its Visits
- their VisitPhotos
- Collection relationships

Use tombstones rather than immediate destructive deletion when synchronization requires conflict resolution.

## 22.2 Delete Visit

Deleting a Visit logically deletes:

- the Visit
- its VisitPhotos

It does not delete the Place.

## 22.3 Delete VisitPhoto

Deleting one VisitPhoto removes it from the Visit.

If this would leave the Visit with zero active Photos, the UI must require one of:

- add another valid Photo
- delete the Visit
- cancel the Photo deletion

An active Visit cannot persist with zero Photos.

---

# 23. Synchronization Requirements

All persistent user-created records should support:

```text
stable id
createdAt
modifiedAt
deletedAt
```

MomentMap should use:

- local-first persistence
- automatic cloud synchronization when available
- last-write-wins conflict handling
- tombstones for deletion propagation

Relationships must remain stable across devices.

Photo storage and cross-device asset availability require explicit implementation rules outside this document.

---

# 24. Data Invariants

## 24.1 Place Identity

A Place must have:

- internal stable ID
- canonical Apple Maps identity
- canonical name
- canonical coordinates

## 24.2 Visit Ownership

Every Visit belongs to exactly one Place.

## 24.3 Photo-Anchored Visit

Every active Visit contains at least one active VisitPhoto with reliable capture time.

## 24.4 Confirmed Place Resolution

A Photo-import group cannot become a Visit until the user confirms one canonical Place.

## 24.5 Emotion Ownership

Emotion belongs only to Visit.

## 24.6 Favorite Ownership

Favorite belongs only to Place.

## 24.7 No Duplicate Source of Truth

Calendar, Timeline, Travel Log, and Shareable Overview are derived from Visits.

They must not store duplicate copies of Visit content.

## 24.8 Import Is Not Persistence

Photo groups, candidate Places, and unresolved drafts are not official user data.

Only final user confirmation creates Places or Visits.

---

# 25. Canonical Relationship Diagram

```text
Collection
    │
    │ organizes
    ▼
Place
├── Apple Maps identity
├── Favorite
│
└── Visit
    ├── Photo-derived time range
    ├── Emotion
    ├── Note
    │
    └── VisitPhoto
        ├── Image reference
        ├── Capture time
        └── Optional coordinate
```

Derived projections:

```text
Places + Visits
    ├── Map
    ├── Calendar
    ├── Timeline
    ├── Daily Travel Log
    └── Shareable Overview
```

---

# 26. Summary

The MomentMap model is based on four distinctions:

```text
Place = where
Visit = one experience there
Photo = temporal evidence
Memory = the user-facing expression of a Visit
```

The product supports both major entry points without duplicating data:

```text
Map
    ↓
Browse Memories by place
```

```text
Calendar / Timeline
    ↓
Browse Memories by time
```

Photo-first import may analyze, cluster, and recommend.

It must not decide meaning on behalf of the user.

The final creation rule is:

```text
Photo Group
+
User-confirmed Place
=
Visit
```

This keeps the model accurate, understandable, and extensible while preserving MomentMap's central product idea:

> Remember life through places.
