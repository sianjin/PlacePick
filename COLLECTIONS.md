# PlacePick — COLLECTIONS.md

Version: 2.0
Status: Product Specification

---

# Purpose

This document defines the Collection model used by PlacePick.

Collections are one of the core concepts of the product.

They define how users organize their own Personal Map.

This document focuses on:

- Collection philosophy
- Ownership
- Organization
- Lifecycle
- Import
- Merge behavior

Rendering, recommendation, persistence, and synchronization are defined separately.

This document should be read together with:

- MVP.md
- DATA_MODEL.md
- PLACE_CREATION.md

When another document conflicts with this one regarding Collection behavior, this document takes precedence.

---

# Core Philosophy

> Apple Maps organizes the world.

> **Users organize their own map.**

Apple Maps classifies places according to objective business information.

Examples:

- Restaurant
- Cafe
- Museum
- Hotel
- Grocery Store

Those classifications describe what a Place objectively is.

PlacePick is fundamentally different.

PlacePick does not organize the world.

It organizes the user's relationship with the world.

Collections therefore exist because every person naturally thinks about meaningful Places differently.

A Collection is not an objective category.

A Collection is a personal organizational view.

---

# What is a Collection?

A Collection is a user-owned grouping of Places.

It represents one way the user chooses to organize part of their Personal Map.

Examples include:

- Food
- Coffee
- Dessert
- Beaches
- Family
- Date
- Photography
- Weekend Trips
- Japan 2027

None of these Collections are objectively correct.

They simply reflect how one person thinks.

Different users may organize exactly the same Place in completely different ways.

For example, the same coffee shop could belong to:

User A

- Coffee

User B

- Date

User C

- Japan 2027

User D

- Work

All four organizations are equally valid.

Collections describe the owner.

They do not describe the Place.

---

# Why Collections Instead of Categories?

Traditional map applications organize Places using fixed Categories.

Examples include:

- Restaurant
- Hotel
- Museum
- Shopping
- Park

This approach works well for discovering public Places.

It works poorly for organizing personal memories.

People rarely think about meaningful Places using objective classifications.

Instead they naturally think in terms of:

Experiences

- Date
- Family
- Childhood

Activities

- Hiking
- Photography
- Fruit Picking

Trips

- Japan 2027
- Weekend Trips

Interests

- Coffee
- Sushi
- Architecture

Life is personal.

Collections should therefore also be personal.

For this reason PlacePick intentionally replaces Categories with Collections.

---

# Collection Ownership

## One Owner

Every Collection has exactly one owner.

A Collection is never jointly owned.

It is never a collaborative object.

It is part of one user's Personal Map.

Sharing a Collection never transfers ownership.

Importing a Collection always creates a Collection owned entirely by the receiving user.

Ownership is never ambiguous.

---

## Collection Metadata

Each Collection contains metadata owned by its owner.

Collection metadata includes:

- Name
- Icon
- Order

These properties belong to the Collection itself.

They do not belong to any Place.

Changing Collection metadata never changes:

- Place Identity
- Recommendation
- Importance
- Apple Maps information

Collection metadata is personal.

Two users may own Collections with:

- the same name
- different names
- the same icon
- different icons

without conflict.

---

# One Place, One Collection

Every Place belongs to exactly one Collection.

This is one of the core invariants of PlacePick.

The MVP intentionally does not support assigning one Place to multiple Collections.

Supporting multiple Collections would gradually turn the system into a tagging model rather than an organizational model.

Keeping one Collection per Place provides several advantages:

- predictable browsing
- simple filtering
- deterministic import behavior
- deterministic merge behavior
- simpler synchronization
- cleaner mental model

When users wish to organize Places differently, they should create a better Collection rather than assigning multiple Collections to the same Place.

---

# Collection Lifecycle

Collections are lightweight.

Users are encouraged to change them whenever their mental model changes.

Users may:

- Create Collections
- Rename Collections
- Change Collection Icons
- Reorder Collections
- Delete Collections

Collections are intended to evolve together with the user's Personal Map.

The product should never imply that Collections are permanent or fixed.

---

## Suggested Collections

When PlacePick is first installed, the app may provide a small set of suggested Collections.

Examples include:

- Food
- Coffee
- Dessert
- Museum
- Hotel
- Shopping

These Collections are examples only.

They are not recommended structures.

Users remain free to:

- Keep them
- Rename them
- Delete them
- Ignore them completely
- Create entirely different Collections

The app should never assume the suggested Collections are universally correct.

---

## Collection Icons

Every Collection has one SF Symbol chosen by the user.

Examples:

Coffee

→ cup.and.saucer

Photography

→ camera

Beach

→ beach.umbrella

Museum

→ building.columns

Family

→ figure.2.and.child.holdinghands

Icons improve recognition.

They do not change the meaning of a Collection.

Icons are never used by:

- Recommendation
- Ranking
- Importance
- Merge
- Import

They are purely visual.

---

## Collection Order

Collections appear in a user-defined order.

Users may reorder Collections at any time.

Example:

All

Coffee

Food

Weekend Trips

Japan 2027

Photography

Collection order reflects personal preference.

It is not determined by:

- Recommendation
- Number of Places
- Alphabetical order
- Creation date

The Collection Bar always follows the user's chosen order.

---

## No "Other" Collection

PlacePick intentionally does not provide an "Other" Collection.

If a Place does not fit an existing Collection, the correct solution is to create a meaningful new Collection.

An "Other" Collection gradually becomes an unorganized bucket that weakens the structure of the Personal Map.

Creating a new Collection is encouraged.

Collections should evolve together with the user's way of thinking.

---

# Collection Import

Collections may be shared between users.

Sharing a Collection transfers:

- A Collection snapshot
- The Place identities contained in that snapshot
- The Collection name and icon as import metadata

Sharing does **not** transfer:

- Ownership
- Collaboration
- Permissions
- Live synchronization
- Personal memories
- Collection authority

Import is a one-time transfer.

After import, the sender and receiver become completely independent.

Future changes made by either user never affect the other.

---

# Import Options

When receiving a Collection, the user has two choices:

```text
Import as New Collection

or

Merge into Existing Collection
```

PlacePick never decides automatically.

The receiver always chooses how the imported Places should fit into their Personal Map.

---

# Import as New Collection

Import as New Collection creates a brand new local Collection.

The imported Collection receives:

- a new local identifier
- one local owner
- independent metadata

The shared name and icon may be used as the initial values for convenience.

For example:

Sender

```text
Japan 2027
✈️
```

Receiver imports as new.

Result

```text
Japan 2027
✈️
```

Immediately after import, the receiver may freely:

- rename it
- change the icon
- reorder it
- delete it

The imported Collection is now completely independent.

There is no synchronization.

The sender cannot modify it.

The receiver owns it completely.

---

# Merge into Existing Collection

Instead of creating a new Collection, the receiver may choose an existing Collection.

Example:

Sender

```text
Japan 2027
```

Receiver

```text
Japan
```

The receiver may choose:

```text
Merge into

Japan
```

The receiver's Collection remains authoritative.

The sender's Collection never replaces it.

---

# Merge Philosophy

Collection Merge affects Places.

It does not merge Collection metadata.

Collection Merge exists only to expand the receiver's Personal Map.

It never reorganizes it.

This principle is fundamental.

> **Sharing expands a map. It never rewrites it.**

---

# What Gets Merged?

The following table defines merge behavior.

| Object | Merge Behavior |
|---------|----------------|
| Place Identity | ✅ Imported when new |
| Collection Membership | ✅ Only for newly imported Places |
| Collection Name | ❌ Never merged |
| Collection Icon | ❌ Never merged |
| Collection Order | ❌ Never merged |
| Note | ❌ Never merged |
| Emotion | ❌ Never merged |
| Favorite | ❌ Never merged |
| Memory Photo | ❌ Never merged |

Place Identity is portable.

Personal relationship is not.

---

# Existing Places

If an imported Place already exists inside the receiver's Personal Map:

The existing Place always wins.

PlacePick keeps:

- existing Collection
- existing Note
- existing Emotion
- existing Favorite
- existing Memory Photo

PlacePick never:

- creates another copy
- moves the Place
- overwrites memory
- changes Collection automatically

This rule applies regardless of which Collection is being imported.

Example:

Receiver

```text
Coffee

Blue Bottle
```

Sender

```text
Japan 2027

Blue Bottle
```

After merge:

Receiver

```text
Coffee

Blue Bottle
```

Blue Bottle remains in Coffee.

It is not moved into Japan 2027.

This behavior is intentional.

The receiver's organization always takes priority.

---

# Existing Collection Metadata

When merging into an existing Collection:

The existing Collection remains authoritative.

Its:

- Name
- Icon
- Order

never change automatically.

Example:

Receiver

```text
Japan

✈️
```

Sender

```text
Japan 2027

🇯🇵
```

After merge:

```text
Japan

✈️
```

The sender's metadata is ignored.

Only new Places are imported.

---

# Merge Summary

After import, PlacePick may display a summary.

Example:

```text
Collection Imported

12 new Places added

3 Places already saved
```

Already-saved Places are not counted as new imports.

No existing Place is modified.

No Collection is reorganized.

---

# Collection Independence

After import:

The sender may:

- rename the Collection
- add Places
- delete Places
- change icons

The receiver may independently:

- rename the Collection
- reorder it
- change icons
- move Places
- delete Places

Neither side receives future updates.

Import behaves like copying a document.

It does not behave like subscribing to one.

---

# Why Merge Does Not Move Existing Places

Suppose the receiver already has:

```text
Coffee

Blue Bottle
```

The sender shares:

```text
Japan 2027

Blue Bottle
```

Automatically moving Blue Bottle into Japan 2027 would silently rewrite the receiver's Personal Map.

That violates one of PlacePick's core principles.

Instead, PlacePick preserves the receiver's existing organization.

Collections represent how the owner thinks.

Only the owner should decide when that organization changes.

---

# Relationship to Recommendation

Collections and Recommendation solve two completely different problems.

Collections answer:

> **How does the user organize their Personal Map?**

Recommendation answers:

> **Which saved Places deserve more visual attention right now?**

These systems are intentionally independent.

Changing a Collection must never:

- change Recommendation
- change Importance Score
- change ranking
- change visual priority

Likewise, Recommendation must never:

- move Places between Collections
- rename Collections
- reorder Collections
- influence Collection ownership

Organization and rediscovery remain separate concerns.

---

# Relationship to Apple Maps

Apple Maps and PlacePick have different responsibilities.

Apple Maps owns objective Place information.

Examples include:

- Place Identity
- Coordinates
- Business information
- Search
- Navigation

PlacePick owns the user's relationship with Places.

Examples include:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Apple Maps answers:

> **What is this Place?**

PlacePick answers:

> **What does this Place mean to me?**

These responsibilities should never overlap.

---

# Relationship to Place Identity

Every Place consists of two conceptually separate layers.

```text
Place
├── Identity
└── Personal Relationship
```

Collection belongs to the Personal Relationship layer.

It is **not** part of Place Identity.

Changing Collection never changes:

- Apple Maps identifier
- Coordinates
- Place name
- Place Identity

Likewise, replacing Place Identity must preserve Collection whenever possible.

Collection represents the user's organization rather than the Place itself.

---

# Relationship to Memory

Collection is closely related to Memory, but they are not the same concept.

Memory answers:

> **What happened here?**

Collection answers:

> **Where does this Place belong in my Personal Map?**

Memory includes:

- Note
- Emotion
- Memory Photo

Collection is separate because organization and memory evolve independently.

For example:

A user may move a Place from:

```text
Weekend Trips
```

to

```text
Family
```

without changing any memories attached to that Place.

Likewise, users may edit Notes or Emotions without changing Collection.

---

# Engineering Invariants

The following rules are mandatory throughout the product.

## Ownership

- Every Collection has exactly one owner.
- Collection ownership is never shared.
- Import creates local ownership.

---

## Organization

- Every Place belongs to exactly one Collection.
- Collections are user-defined.
- Collections are independent from Apple Maps categories.
- Collection order is user-defined.

---

## Metadata

Collection metadata consists of:

- Name
- Icon
- Order

Metadata belongs to the owner.

Metadata never merges automatically.

---

## Import

Import may:

- create new Collections
- add new Places

Import never:

- create collaboration
- overwrite Collection metadata
- overwrite Memories
- move existing Places automatically

---

## Merge

Merge affects only Place membership for newly imported Places.

Merge never modifies:

- Collection metadata
- Existing Collection assignments
- Notes
- Emotions
- Favorites
- Memory Photos

---

## Recommendation

Recommendation never:

- changes Collection
- changes ownership
- changes organization

Recommendation only affects presentation.

---

# Design Principles

## Collections Describe the Owner

Collections are personal.

They describe how the owner thinks.

They do not describe the world.

---

## Collections Are Stable

Collections should evolve slowly.

Users should not feel the need to reorganize their map every week.

The product should encourage meaningful long-term organization rather than temporary grouping.

---

## Collections Are Lightweight

Creating a Collection should feel inexpensive.

Users should never hesitate to create a new Collection when it better reflects their mental model.

---

## Collections Never Become Tags

A Collection represents one primary organizational decision.

Supporting multiple Collections for one Place would gradually transform Collections into tags.

That is intentionally outside the MVP.

---

## Sharing Preserves Ownership

Sharing is designed to exchange Place Identity.

It is not designed to exchange ownership.

Every imported Collection immediately becomes part of the receiver's own Personal Map.

From that point onward, the receiver has complete control.

---

## Existing Organization Wins

When importing:

the receiver's organization always takes priority over the sender's organization.

This prevents sharing from unexpectedly rewriting a Personal Map.

It also ensures that every organizational change is an explicit decision made by the owner.

---

## Simplicity Over Flexibility

Many systems become more flexible by allowing:

- multiple Collections
- nested Collections
- automatic merging
- collaborative ownership

PlacePick intentionally avoids these features in the MVP.

A simpler organizational model is easier to understand, easier to maintain, and produces more predictable behavior.

---

# Final Principles

> **Collections organize the user's relationship with Places, not the Places themselves.**

> **Every Collection has exactly one owner.**

> **Collection metadata belongs to that owner.**

> **Place Identity may be shared.**

> **Personal memory remains personal.**

> **Sharing expands a Personal Map.**

> **It never rewrites one.**