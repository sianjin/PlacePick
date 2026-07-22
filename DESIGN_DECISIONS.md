# PlacePick — DESIGN_DECISIONS.md

Version: 4.0

This document records the major product decisions behind PlacePick.

It explains **why** each decision was made so future implementation and product evolution remain consistent.

---

# Decision 001 — Apple Maps Owns the World

Apple Maps is responsible for:

- Place identity
- Search
- Navigation
- Business information
- Coordinates

PlacePick does not duplicate these responsibilities.

Instead, it builds a personal memory layer on top of Apple Maps.

---

# Decision 002 — PlacePick Owns Personal Memory

PlacePick stores only information Apple Maps cannot know.

Examples:

- Collection
- Favorite
- Emotion
- Personal note
- Memory photo

This keeps the product focused and intentionally small.

---

# Decision 003 — One Map, Not Many Screens

The map is the primary interface.

Most actions begin and end on the map.

Avoid turning PlacePick into a multi-page application.

---

# Decision 004 — Search Exists Only During Capture

Global search is intentionally excluded from MVP.

Search exists only when:

- Creating a Place
- Replacing a Place

Outside those flows, users explore through the map.

---

# Decision 005 — Collections Are User-Owned

The original Category model has been replaced with Collections.

Categories imply that the application knows the correct classification of a place.

Collections recognize that organization belongs to the user.

For example, the same café may belong to:

- Coffee
- Date
- Weekend
- Japan 2027

depending entirely on the user's own thinking.

Therefore:

- Collections are user-defined.
- Collections are not objective place types.
- Collections organize memories, not places.

---

# Decision 006 — One Place Belongs to One Collection

Each Place belongs to exactly one Collection.

Supporting multiple Collections introduces significantly more complexity while providing limited value for the MVP.

One Collection keeps:

- browsing simple
- filtering predictable
- data synchronization straightforward

---

# Decision 007 — Collections Are First-Class Objects

Collections are independent entities.

Conceptually:

```swift
Collection
    id
    name
    icon
    order

Place
    collectionID
```

A Place references a Collection.

It never stores Collection information directly.

---

# Decision 008 — Suggested Collections Are Not System Rules

PlacePick may provide suggested Collections during onboarding.

Examples:

- Food
- Coffee
- Travel

These exist only as conveniences.

Users remain free to:

- rename them
- delete them
- replace them completely

---

# Decision 009 — Recommendation Is Independent

Recommendation determines only visual prominence.

Recommendation never changes:

- Collection
- Place identity
- Favorite
- Emotion
- Note

Recommendation is a rendering decision.

Collections are an organizational decision.

These systems remain completely independent.

---

# Decision 010 — Identity and Relationship Are Separate

A Place contains two fundamentally different kinds of data.

Identity:

- Apple Maps identifier
- Name
- Coordinates

Relationship:

- Collection
- Favorite
- Emotion
- Note
- Memory photo

Changing one must not unexpectedly modify the other.

---

# Decision 011 — Replace Place Preserves Relationship

Replace Place exists to correct an incorrect Apple Maps selection.

Replacing identity preserves:

- Collection
- Favorite
- Emotion
- Note
- Memory photo

Only Apple Maps identity changes.

---

# Decision 012 — Apple Already Knows the Objective Facts

Whenever Apple Maps already knows the answer, PlacePick should not ask again.

Examples:

Do not ask users to manually type:

- place name
- coordinates
- address

Instead, ask only for information Apple cannot know.

---

# Decision 013 — The Product Should Feel Personal

The application should consistently reinforce one idea:

> This is your map.

Not:

> This is a database of places.

Every major interaction should strengthen personal ownership.

---

# Decision 014 — Current Location Provides Map Context

PlacePick displays the user's current location because saved Places are meaningful partly in relation to where the user is now.

The location indicator helps users discover nearby saved Places without introducing a separate Nearby page.

PlacePick uses MapKit's native user-location presentation and requests only When In Use authorization.

Current location is map context, not personal Place data.

Therefore, PlacePick does not:

- store location history
- track the user in the background
- attach current location to saved Places
- force the map to remain centered on the user
- make recommendation directly dependent on live location

Recommendation continues to operate relative to the current viewport.

---

# Final Principles

> Apple Maps organizes the world.

> PlacePick organizes personal memories.

> Collections organize the user's map.

> Recommendation organizes visual attention.

> Identity belongs to Apple.

> Relationship belongs to the user.