# PlacePick — MVP.md

Version: 5.0  
Status: Root Specification

---

# 1. Status and Authority

This document is the root product specification for PlacePick.

Every other product and implementation document derives from this one, including:

- `MANIFESTO.md`
- `COLLECTIONS.md`
- `UI_STRUCTURE.md`
- `DATA_MODEL.md`
- `PLACE_CREATION.md`
- `IMPORT_PIPELINE.md`
- `RECOMMENDATION_MODEL.md`
- `DESIGN_PRINCIPLES.md`
- `DESIGN_LANGUAGE.md`
- `CLAUDE.md`

When another document conflicts with this document, this document takes priority.

Supporting documents may define more detailed behavior, but they must not change the product model or principles established here.

---

# 2. Product Definition

> **PlacePick is a portable personal map.**

PlacePick helps users:

- Capture meaningful Places
- Organize them in a personal map
- Remember why they mattered
- Rediscover them naturally
- Share them without giving up ownership
- Open them in external map applications when needed

PlacePick is not another public map database.

It is the user's own layer of relationships, memories, and organization built around real-world Places.

---

# 3. Product Positioning

Apple Maps helps users understand and navigate the world.

PlacePick helps users build a personal map of Places that matter to them.

Apple Maps provides:

- Place search
- Place identity
- Coordinates
- Navigation
- Business information
- Directions

PlacePick provides:

- Personal organization
- Favorite
- Emotion
- Note
- Memory Photo
- Rediscovery
- Portable sharing

The product should always feel like:

> **This is my map of the world.**

---

# 4. Why PlacePick Exists

People discover meaningful Places through many sources:

- Apple Maps
- Google Maps
- Instagram
- Xiaohongshu
- Reddit
- TikTok
- YouTube
- Messages
- Friends
- Notes
- Real-world discovery

The problem is not that people cannot find Places.

The problem is that saved Places become scattered, forgotten, or disconnected from personal meaning.

PlacePick gives meaningful Places a permanent home.

---

# 5. Product Loop

The PlacePick product loop is:

```text
Discover or Receive
        ↓
Capture
        ↓
Resolve through Apple Maps
        ↓
Save
        ↓
Organize
        ↓
Rediscover
        ↓
Share or Open Externally
```

In product terms:

1. Discover or receive a meaningful Place.
2. Capture it with minimal friction.
3. Resolve its real-world identity through Apple Maps.
4. Save it into the user's personal map.
5. Organize it in one Collection.
6. Rediscover it through the map.
7. Share it or open it in an external map application.

Every MVP feature should strengthen this loop.

---

# 6. Core Product Model

## 6.1 Place

A Place represents one real-world location.

Every Place contains two conceptually separate layers:

```text
Place
├── Identity
└── Personal Relationship
```

These layers must never be conflated.

## 6.2 Place Identity

Place Identity answers:

> What real-world Place is this?

For the MVP, Place Identity is resolved through Apple Maps.

It includes:

- Apple Maps identifier, when available
- Place name
- Latitude
- Longitude
- Necessary MapKit-derived identity metadata

Users do not freely edit Place Identity.

If the wrong Apple Maps result was selected, the identity must be corrected through the Replace Place flow.

## 6.3 Personal Relationship

Personal Relationship answers:

> What does this Place mean to me?

It includes:

- Collection membership
- Favorite
- Emotion
- Note
- Memory Photo

Relationship data belongs to the user.

It is editable independently from Place Identity.

Changing relationship data must not change Place Identity.

Replacing Place Identity must preserve relationship data.

## 6.4 Collection

A Collection is the user's personal organizational view.

Collections do not objectively classify the world.

Examples may include:

- Food
- Coffee
- Family
- Date
- Beaches
- Photography
- Japan 2027
- Weekend Trips

Different users may organize the same Place differently.

Each Place belongs to exactly one Collection.

This keeps:

- Browsing simple
- Filtering predictable
- The map understandable
- Import behavior deterministic
- Data synchronization manageable

PlacePick does not support assigning one Place to multiple Collections in the MVP.

## 6.5 Memory

Memory is the personal layer attached to a Place.

It may include:

- One Note
- One optional Memory Photo
- One optional Emotion

Supported Emotion states are:

- No emoji — no personal experience recorded
- 😐 — Okay
- 😊 — Loved it
- 🤩 — Unforgettable

No emoji is not the same as neutral.

There is no separate visited field.

A Place may be saved before the user has visited it.

## 6.6 Favorite

Favorite marks a Place the user wants to keep especially visible.

Favorite is personal relationship data.

It must never be imported from another user's map or overwritten during merge.

---

# 7. Ownership and Portability

## 7.1 Places Belong to the World

Real-world Places do not belong to PlacePick.

For the MVP, Apple Maps provides the canonical identity used to resolve them.

PlacePick stores the user's relationship with those Places.

## 7.2 Place Identity Is Portable

Place Identity may move between users.

A user may:

- Share one Place
- Receive one Place
- Share one Collection
- Receive one Collection
- Import Places from external content

The receiving user may add the same real-world Place to their own map.

## 7.3 Personal Memory Is Not Portable by Default

Personal Memory belongs to one user.

The following are never automatically transferred or merged:

- Note
- Emotion
- Favorite
- Memory Photo
- Existing Collection membership

Receiving a Place transfers its identity, not the sender's personal memory.

## 7.4 Collections Have One Owner

A Collection belongs to exactly one owner.

Its metadata is personal:

- Name
- Icon
- Order

Sharing a Collection never creates shared ownership.

Importing a Collection creates a local copy or adds Places into an existing local Collection.

There is no ongoing relationship between sender and receiver.

## 7.5 Sharing Expands a Map

> **Sharing expands your map. It never rewrites it.**

Import may add new Place identities.

Import must never silently overwrite:

- Existing Notes
- Existing Emotions
- Existing Favorites
- Existing Memory Photos
- Existing Collection assignments
- Existing Collection metadata

---

# 8. Core Experience

## 8.1 Map

The map is the persistent home of PlacePick.

The map displays the user's saved Places over an Apple MapKit base map.

The MVP map supports:

- Pan
- Zoom
- Rotation
- Saved Place annotations
- Collection filtering
- Clustering
- Recommendation-based prominence
- Native current-location presentation
- Apple Maps attribution

Major flows should return naturally to the map.

PlacePick should not become a multi-page application with a separate browsing hierarchy.

## 8.2 Collection Bar

A lightweight Collection Bar appears over the map.

Conceptually:

```text
All   Food   Coffee   Beaches   Japan 2027   …
```

`All` is a map view, not a stored Collection.

Selecting one Collection changes which saved Places are visible.

It does not:

- Modify Place data
- Change recommendation scores
- Reassign Places
- Change Collection ownership

The Collection Bar follows the user's Collection order.

## 8.3 Current Location

PlacePick may display the user's current location using native MapKit presentation.

Current location provides map context.

It is not saved Place data.

PlacePick does not:

- Request background tracking
- Store location history
- Attach movement history to Places
- Require location permission
- Force the map to remain centered on the user
- Use live location as personal memory
- Make recommendation directly dependent on live GPS location

If permission is denied, the map remains fully usable.

## 8.4 Place Detail

Place Detail represents the user's relationship with a Place.

It may include:

- Memory Photo
- Place name
- Collection
- Favorite
- Emotion
- Note
- Open in Apple Maps
- Open in Google Maps
- Replace Place
- Delete

It intentionally does not become a business listing.

Place Detail excludes:

- Public reviews
- Business photos
- Business hours
- Phone number
- Website
- Full business information
- Navigation instructions
- Permanent social-media source data

Those functions belong to external map applications.

---

# 9. Capture

## 9.1 Capture Definition

Capture is the process of bringing a meaningful Place into PlacePick.

MVP capture paths include:

- Manual Add
- Share into PlacePick
- Receive a Place
- Receive a Collection

All capture paths must eventually resolve to a reliable Apple Maps Place Identity.

## 9.2 Manual Add

Manual Add flow:

```text
Map
  ↓
Tap "+"
  ↓
Apple Maps Search
  ↓
Select one MapKit result
  ↓
Choose Collection
  ↓
Optionally add personal relationship data
  ↓
Save
  ↓
Return to Map
```

Search exists to resolve Place Identity during capture.

There is no global public-place search on the main map in the MVP.

## 9.3 Apple Maps Resolution

A Place can only be created after the user selects a valid MapKit result.

Users cannot create Place Identity from:

- Free text
- Arbitrary coordinates
- A manually typed name
- Unresolved imported text
- An unconfirmed social-media phrase

Automation may suggest search text.

Only Apple Maps resolution and user confirmation may create a Place.

## 9.4 Default Relationship Values

A newly created Place has:

```text
Favorite      = false
Emotion       = nil
Note          = empty
Memory Photo  = none
```

Collection has no silent default.

The user must choose one Collection before saving.

## 9.5 Share Into PlacePick

Content shared from another app may pre-fill Apple Maps Search.

The import pipeline may use:

- Shared title
- Selected text
- Shared caption
- URL metadata
- Deterministic lightweight extraction

The imported text is only a search suggestion.

It must never create a Place directly.

The user must confirm one MapKit result.

---

# 10. Place Sharing and Import

## 10.1 Receiving a New Place

When the received Place is not already saved:

```text
Receive Place
    ↓
Resolve Place Identity
    ↓
Choose Collection
    ↓
Save
```

The receiving user chooses the Collection.

The sender's Collection is not automatically applied.

The new local relationship begins with:

```text
Favorite      = false
Emotion       = nil
Note          = empty
Memory Photo  = none
```

The sender's personal memory is not copied.

## 10.2 Receiving an Existing Place

When the same Place Identity is already saved:

```text
Already Saved
Open Place
```

PlacePick does not create another copy.

It does not merge or overwrite:

- Note
- Emotion
- Favorite
- Memory Photo
- Collection membership

The existing local Place remains authoritative.

## 10.3 Duplicate Identity

The primary duplicate signal is the Apple Maps identifier.

Fallback signals may include:

- Very close coordinates
- Same normalized name within a small distance

PlacePick must never silently create multiple copies of the same resolved real-world Place in the MVP.

---

# 11. Collection Sharing and Import

## 11.1 Collection Sharing Model

Sharing a Collection transfers:

- A Collection snapshot
- The Place identities contained in that snapshot
- The shared Collection name and icon as import metadata

It does not transfer:

- Ownership
- Synchronization
- Permissions
- Collaboration
- Shared editing
- Live updates
- Sender memory data

The imported result belongs entirely to the receiver.

## 11.2 Import as New Collection

When the user chooses Import as New Collection:

- A new local Collection is created
- The received name may be used as the initial name
- The received icon may be used as the initial icon
- The new Collection receives a new local identifier
- The receiver may rename, re-icon, reorder, or delete it
- Only Places not already saved are added to it

The received metadata is only an initial suggestion.

It does not remain connected to the sender.

## 11.3 Merge into Existing Collection

When the user chooses Merge into Existing Collection:

- The receiver selects one existing local Collection
- Collection name is preserved
- Collection icon is preserved
- Collection order is preserved
- Only new Place identities are added

Collection metadata is never merged.

The existing local Collection remains authoritative.

## 11.4 Existing Places During Collection Import

If an imported Place already exists in the receiver's map:

- Keep the existing Place
- Keep its existing Collection
- Keep its existing Note
- Keep its existing Emotion
- Keep its existing Favorite
- Keep its existing Memory Photo
- Do not create a duplicate
- Do not move it automatically

The imported Place is counted as already saved.

Example summary:

```text
12 new Places added
3 already saved
```

This may result in the imported Collection containing fewer Places than the sender's Collection.

That is intentional.

The receiver's existing organization takes priority.

## 11.5 Existing Collection Choice

PlacePick must not automatically decide that two Collections are equivalent.

Collections may have:

- The same name but different icons
- Different names but similar purpose
- Similar names but different meaning
- The same icon but unrelated meaning

When importing, the user decides between:

```text
Import as New Collection
Merge into Existing Collection
```

If merging, the user explicitly chooses the destination Collection.

## 11.6 No Collection Synchronization

After import:

- The sender may change their Collection
- The receiver may change their Collection
- Neither side receives the other's changes

Import is a one-time transfer.

It behaves like copying, not subscribing.

---

# 12. Collection Management

Users may:

- Create Collections
- Rename Collections
- Change Collection icons
- Reorder Collections
- Delete Collections

There is no `Other` Collection.

If a Place does not fit an existing Collection, the user creates a meaningful new Collection.

A Collection containing Places cannot be deleted without first moving those Places to another Collection.

Every Place must always belong to exactly one Collection.

---

# 13. Replace Place

Replace Place corrects an incorrect Apple Maps identity.

It updates:

- Apple Maps identifier
- Place name
- Coordinates
- Necessary MapKit-derived identity metadata

It preserves:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Replace Place is not ordinary editing.

It must be explicit and controlled.

If the replacement identity already exists as another saved Place:

- Do not merge automatically
- Do not create a duplicate
- Open the existing Place
- Preserve the current Place until the user explicitly changes or deletes it

---

# 14. Rediscovery and Recommendation

Recommendation helps users rediscover Places they have already saved.

The Recommendation Engine computes a continuous Importance Score.

The map renderer decides how that importance is expressed visually.

Recommendation may affect:

- Symbol prominence
- Label visibility
- Display priority
- Cluster release priority

Recommendation must never:

- Hide a saved Place
- Change Collection membership
- Modify Place Identity
- Modify personal relationship data
- Move the map
- Participate in import decisions
- Participate in merge decisions
- Rank Places through a fixed Top-N quota

Recommendation behavior is defined in `RECOMMENDATION_MODEL.md`.

---

# 15. External Maps

PlacePick does not perform navigation.

Users may open a Place in:

- Apple Maps
- Google Maps

External map applications handle:

- Directions
- Navigation
- Business details
- Hours
- Reviews
- Contact information
- Public business photos

PlacePick hands the Place back when the user needs those functions.

---

# 16. Product Boundaries

## 16.1 What Apple Maps Owns

For the MVP, Apple Maps owns:

- Place resolution
- Search results
- Name
- Coordinates
- Business identity
- Navigation
- Directions
- Public business information

## 16.2 What PlacePick Owns

PlacePick owns:

- Personal map organization
- Collections
- Favorite
- Emotion
- Note
- Memory Photo
- Capture workflow
- Rediscovery
- Portable Place sharing
- Local Collection import decisions

## 16.3 What PlacePick Does Not Build

The MVP intentionally excludes:

- In-app navigation
- Public-place browsing
- Public reviews
- Business photos
- Business hours database
- Route planning
- Travel itinerary planning
- AI trip planning
- Social feeds
- Public profiles
- Followers
- Likes
- Comments
- Collaborative Collections
- Shared ownership
- Roles and permissions
- Live Collection synchronization
- Automatic memory merge
- Automatic Collection equivalence detection
- Automatic movement of existing Places during import
- Multi-owner Collections
- Multiple saved copies of the same resolved Place
- Global search on the main map
- Bottom tab navigation
- A large multi-page information architecture

If another application already solves a public map function well, PlacePick should not recreate it.

---

# 17. Product Invariants

The following rules are mandatory.

## 17.1 Identity and Relationship Are Separate

Changing relationship data must not change Place Identity.

Replacing Place Identity must preserve relationship data.

## 17.2 One Place, One Collection

Every Place belongs to exactly one Collection.

## 17.3 One Resolved Identity, One Local Place

The MVP does not support multiple saved copies of the same resolved real-world Place.

## 17.4 Memory Never Merges

Note, Emotion, Favorite, and Memory Photo are never merged from another user's map.

## 17.5 Existing Organization Wins

An existing Place keeps its existing Collection during import.

## 17.6 Collection Metadata Never Merges

Existing Collection name, icon, and order remain unchanged during merge.

## 17.7 Import Never Creates Collaboration

Import creates a local result with one owner.

## 17.8 Sharing Never Rewrites

Sharing may add new Places.

It never silently modifies existing personal data.

## 17.9 Optional Values Carry Meaning

`nil` is a valid semantic state.

A new Place must preserve:

```text
emotion == nil
```

until the user explicitly records an Emotion.

## 17.10 Recommendation Never Reorganizes

Recommendation changes presentation only.

---

# 18. Product Principles

## Places Belong to the World

PlacePick does not own real-world Places.

Apple Maps provides the canonical identity used by the MVP.

## Users Own Relationships

The personal meaning attached to a Place belongs to the user.

## Place Identity Is Portable

A Place may move between users without transferring personal memory.

## Personal Memory Never Merges

Memory remains local to its owner.

## Collections Are Personal Views

Collections organize the user's map.

They do not classify the world.

## Sharing Expands a Map

Sharing adds possibilities.

It never rewrites existing memories or organization.

## The Map Is the Home

Major flows begin from or return to the map.

## Import Removes Typing, Not Judgment

Automation may suggest.

The user confirms.

## Importance Is Absolute

Presentation may adapt to context.

Recommendation meaning must remain stable.

## Simplicity Wins

Before adding a feature, ask:

> Does this help users capture, remember, rediscover, or safely share meaningful Places?

If not, it does not belong in the MVP.

---

# 19. MVP Success Criteria

The MVP succeeds when:

1. Users can save a real Place in seconds.
2. Capture from another app is faster than manually copying information.
3. Every saved Place has reliable Apple Maps identity.
4. Every Place belongs to one user-controlled Collection.
5. The map feels personal rather than public or administrative.
6. Users can rediscover saved Places naturally.
7. Receiving an already-saved Place feels safe and predictable.
8. Sharing a Place never overwrites an existing memory.
9. Importing a Collection never creates collaboration or synchronization.
10. Existing Place relationships remain intact during import.
11. Existing Collection metadata remains intact during merge.
12. Users can expand their map without surrendering their own organization.
13. Recommendation improves visibility without reorganizing the map.
14. External map applications remain responsible for navigation and public business information.

Users should naturally think:

> Apple Maps gets me there.

> **PlacePick reminds me why I wanted to go.**

And:

> **This feels like my own map—not the app's map.**

---

# 20. Product Promise

> **Every meaningful Place deserves a permanent home.**

PlacePick gives Places that home without taking ownership away from the user.

Place Identity can travel.

Personal memory stays personal.

Collections remain owned by the person who uses them.

Sharing expands the map.

It never rewrites it.
