# MomentMap — PLACE_CREATION.md

Version: 5.0

Status: Place Creation Architecture Specification

---

# Purpose

This document defines how a real-world Place becomes part of the user's Personal Map.

Creation establishes a verified Place identity before the user records any personal relationship.

It describes the product model for creating Places rather than the visual interface.

---

# Relationship to Other Documents

This document should be read together with:

- MVP.md
- DATA_MODEL.md
- IMPORT_PIPELINE.md
- UI_STRUCTURE.md

Responsibilities are divided as follows.

MVP.md defines:

- Product philosophy
- User experience
- Product scope

DATA_MODEL.md defines:

- Place Identity
- Personal Relationship
- Persistence

IMPORT_PIPELINE.md defines:

- How external content becomes a verified Place identity

UI_STRUCTURE.md defines:

- Capture Flow
- Place Detail
- Identity Maintenance

This document defines:

- How verified Place identity is established
- How a Place enters the standard Capture Flow
- The boundary between Place identity and Personal Relationship

---

# Creation Model

Creating a Place follows three conceptual stages.

```text
Verified Identity
        │
        ▼
Personal Relationship
        │
        ▼
Saved Place
```

This document focuses on the first stage.

Before a Place can become part of the user's Personal Map, its real-world identity must first be established.

Only after identity has been verified can the user record a personal relationship.

---

# Creation Principles

## Apple Maps Owns Identity

Every Place begins with a verified Apple Maps result.

Apple Maps provides the objective description of a Place, including:

- Place name
- Coordinates
- Apple Maps identifier
- MapKit-derived metadata

These values form the Place Identity.

Users do not manually edit them.

The objective world belongs to Apple Maps.

---

## Verified Identity Comes First

A Place cannot exist without a verified identity.

Users cannot create Places from:

- free text
- arbitrary map coordinates
- manually typed names
- imported content without Apple Maps confirmation

Every saved Place must correspond to one real-world Place.

This guarantees consistency across search, recommendation, synchronization, and future updates.

---

# Apple Maps Search

Creation begins with Apple Maps Search.

Users may search using:

- Place names
- Addresses
- Landmarks
- Businesses
- Geographic locations

Search results come directly from MapKit.

MomentMap never maintains its own Place database or search index.

Apple Maps remains the single source of truth for Place identity.

---

# Selecting a Place

A Place is created only after the user selects one Apple Maps search result.

Selecting a result establishes the Place Identity.

Conceptually:

```text
Search

↓

Apple Maps Results

↓

Verified Identity
```

At this point, the Place is identifiable but not yet part of the Personal Map.

No user relationship has been recorded.

---

# Duplicate Detection

Before continuing to relationship capture, MomentMap checks whether the selected Apple Maps identity already exists.

Useful signals include:

- Apple Maps identifier
- nearby coordinates
- normalized Place name

If no duplicate exists:

Continue to the standard Capture Flow.

If a duplicate exists:

Open the existing Place instead.

The MVP intentionally supports only one saved copy of each real-world Place.

---

# Identity Boundary

Place identity represents objective information about the real world.

It answers:

> Which Place is this?

It does not answer:

- Why the user saved it
- Whether the user likes it
- Which Collection it belongs to
- What memories it contains

Those belong to the Personal Relationship layer.

Identity must always be established before personal meaning can exist.

---

# Part 1 Summary

Place creation begins by establishing a verified Apple Maps identity.

Apple Maps defines what the Place is.

MomentMap does not duplicate or modify this information.

Only after identity has been verified can the user begin creating a Personal Relationship with the Place.

---

# Relationship Creation

Once a Place has a verified Apple Maps identity, the user begins creating a Personal Relationship.

Conceptually:

```text
Verified Identity
        │
        ▼
Personal Relationship
        │
        ▼
Saved Place
```

At this stage, the objective Place is already known.

The remaining information belongs entirely to the user.

---

# Users Own Relationships

Apple Maps describes the Place.

Users describe their relationship with the Place.

Relationship fields include:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

These fields answer questions Apple Maps cannot.

Examples include:

- Why did I save this Place?
- How did I feel about it?
- Which Collection does it belong to?
- What memories do I want to keep?

The Personal Relationship belongs entirely to the user.

---

# Collection Assignment

Every Place belongs to exactly one Collection.

Collection is required before saving.

The Collection picker displays Collections in the user's preferred order.

If the desired Collection does not exist, the user may create a new Collection without leaving the creation flow.

The newly created Collection becomes immediately available and is automatically selected.

Collection organizes the user's Personal Map.

It is not part of Place Identity.

---

# Optional Relationship Fields

Collection is the only required relationship field.

The following fields are optional:

- Favorite
- Emotion
- Note
- Memory Photo

Users may save a Place immediately after selecting a Collection.

Additional relationship information may be added later.

The creation experience should remain lightweight.

---

# Default Relationship

When a new Place is created:

```text
Favorite      = false
Emotion       = nil
Memory Photo  = none
Note          = empty
```

No assumptions are made about the user's experience.

A newly created Place is simply part of the Personal Map.

The relationship may evolve over time.

---

# Saving a Place

Saving creates the complete Place defined by the data model.

Conceptually:

```text
Verified Identity
        │
        ▼
Personal Relationship
        │
        ▼
Saved Place
```

A successful save creates both conceptual layers:

## Identity

Provided by Apple Maps:

- Apple Maps identifier
- Place name
- Coordinates
- MapKit metadata

## Personal Relationship

Provided by the user:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

These layers remain independent throughout the life of the Place.

---

# After Saving

Once saved, the Place immediately becomes part of the user's Personal Map.

Creation ends.

Subsequent product systems begin.

Conceptually:

```text
Saved Place
        │
        ▼
Recommendation
        │
        ▼
Presentation
```

Recommendation interprets the Personal Relationship.

Presentation determines how the Place appears on the map.

Creation plays no further role.

---

# Relationship Boundary

Relationship describes the user's connection to a Place.

It does not change:

- Place identity
- Place location
- Apple Maps metadata

Likewise, future updates to Apple Maps do not change:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Identity and Personal Relationship remain independent throughout the lifetime of the Place.

---

# Part 2 Summary

A verified Place becomes part of the Personal Map only after the user records a Personal Relationship.

Apple Maps defines what the Place is.

The user defines what the Place means.

Saving combines these two layers into a single Place.

From that point forward, the Place participates in recommendation, presentation, and every other product system.

---

# Identity Maintenance

Once a Place has been created, its Personal Relationship may evolve over time.

Occasionally, the Place Identity itself also needs correction.

Identity Maintenance defines how Place identity may change while preserving the user's Personal Relationship.

---

# Correcting Place Identity

Place identity is normally permanent.

However, users may occasionally select the wrong Apple Maps result during creation.

Examples include:

- the wrong restaurant branch
- the wrong hotel
- the wrong building
- a business with a similar name

These situations require correcting the Place Identity rather than creating a new Place.

---

# Replace Place

Replace Place allows the user to replace the Apple Maps identity while preserving the existing Personal Relationship.

Conceptually:

```text
Old Identity
        │
        ▼
Replace Identity
        │
        ▼
New Identity

Relationship
        │
        └──────────────► Preserved
```

Replacing a Place updates only the Identity layer.

It replaces:

- Apple Maps identifier
- Place name
- Coordinates
- MapKit-derived metadata

It preserves:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

The user's memories remain attached to the corrected Place.

---

# Relationship Preservation

Replace Place exists to correct objective information.

It does not reinterpret the user's intent.

Unless future product rules explicitly define otherwise, replacing a Place always preserves the existing Personal Relationship.

The user should never lose personal memories because an incorrect Place identity was selected.

---

# Import as an Entry Point

Import does not create a different kind of Place.

Whether a Place originates from:

- manual search
- Share Extension
- future import methods

every creation path converges at the same point:

```text
Verified Identity
        │
        ▼
Relationship Creation
        │
        ▼
Saved Place
```

After creation, the product no longer distinguishes how a Place entered the Personal Map.

---

# Cancellation

Users may leave the creation flow at any time before saving.

If creation is cancelled:

- no Place is created
- no Personal Relationship is recorded
- no partial Place exists in the Personal Map

Creation is atomic.

It either completes successfully or produces no Place.

---

# Failure Handling

Creation may occasionally be interrupted.

Examples include:

## No Apple Maps Results

The user may refine the search.

No unresolved Place is created.

---

## Duplicate Place

If the selected Apple Maps identity already exists:

Open the existing Place.

Do not create another copy.

---

## Network Unavailable

If Apple Maps cannot verify Place identity:

Creation cannot continue.

The existing Personal Map remains fully usable.

---

# Creation Invariants

The following rules should always remain true.

A Place must never exist without:

- verified Apple Maps identity
- one Collection

The system must never:

- create unresolved Places
- create duplicate identities
- partially save Personal Relationships
- separate Identity from Relationship after saving

These invariants keep Place creation consistent with the overall product model.

---

# Final Principles

> Apple Maps identifies Places.

> Users create Personal Relationships.

> Identity must exist before Relationship.

> Replace corrects identity without changing personal meaning.

> Every creation path produces the same Place model.

> The product remembers Places—not how they were created.