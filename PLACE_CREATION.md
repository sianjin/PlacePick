# PlacePick — PLACE_CREATION.md

Version: 4.0

This document defines how Places are created in PlacePick.

It focuses on the creation workflow rather than UI implementation.

---

# Goal

Creating a Place should require the fewest possible decisions.

Apple Maps already knows the objective facts.

PlacePick should ask only for the personal information Apple cannot know.

---

# Creation Principles

## Apple Maps Owns Identity

Every Place begins with an Apple Maps search result.

Apple Maps provides:

- Place name
- Coordinates
- Apple Maps identifier
- MapKit-derived metadata

These values become the Place identity.

Users do not manually edit them.

---

## Users Own Relationships

After selecting a Place, the user provides only relationship data.

Relationship fields include:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

These describe the user's relationship with the Place rather than the Place itself.

---

# Creation Flow

```text
Map
 │
 ▼
Tap "+"
 │
 ▼
Apple Maps Search
 │
 ▼
Live MapKit Results
 │
 ▼
Select Place
 │
 ▼
Personal Information
 │
 ├── Collection
 ├── Favorite
 ├── Emotion
 ├── Note
 └── Memory Photo
 │
 ▼
Save
 │
 ▼
Return to Map
```

---

# MapKit Search

PlacePick always relies on MapKit to identify Places.

Users may search using:

- Place names
- Addresses
- Landmarks

Search results come directly from Apple Maps.

PlacePick never creates its own search index.

---

# Creating a Place

A Place can only be created after the user selects a valid MapKit result.

The user cannot create a Place from:

- Free text
- Arbitrary coordinates
- Manually typed names
- Imported text without MapKit confirmation

This guarantees every Place has a stable Apple Maps identity.

---

# Collection Assignment

Every Place belongs to exactly one Collection.

Before saving, the user selects one Collection.

The Collection picker displays Collections in the user's custom order.

If the desired Collection does not exist, the user may create one without leaving the creation flow.

The new Collection becomes immediately available and is automatically selected.

---

# Duplicate Detection

Before creating a new Place, PlacePick checks whether the selected Apple Maps identifier already exists.

If no duplicate exists:

→ Create the new Place.

If a duplicate exists:

→ Open the existing Place.

The MVP intentionally does not support multiple saved copies of the same real-world Place.

---

# Default Values

A newly created Place has:

```text
Favorite      = false
Emotion       = nil
Memory Photo  = none
Note          = empty
```

Collection has no default.

The user must explicitly choose one before saving.

---

# Save

Saving a Place creates two conceptual layers.

## Identity

Provided by Apple Maps:

- Apple Maps identifier
- Name
- Coordinates

## Relationship

Provided by the user:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

These layers remain independent throughout the life of the Place.

---

# Replace Place

Replace Place exists for situations where the wrong Apple Maps result was selected.

Examples:

- Wrong restaurant branch
- Wrong building
- Wrong business with a similar name

Replace Place updates only the identity layer.

It preserves:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

while replacing:

- Apple Maps identifier
- Name
- Coordinates

The user's relationship with the Place remains intact.

---

# Import Pipeline

Places imported through the Share Extension follow exactly the same creation process.

Imported content may help pre-fill the MapKit search.

However, every imported Place still requires the user to select one MapKit result before creation.

All creation paths converge into the same workflow.

---

# Error Handling

## No Search Results

If MapKit returns no suitable results:

- No Place is created.
- The user may refine the search.

## Duplicate Found

If the selected Place already exists:

- Open the existing Place.
- Do not create a duplicate.

## Cancel

If the user cancels at any point:

- No Place is created.
- No partial draft is saved.

---

# Product Principles

> Apple Maps identifies Places.

> Users create memories.

PlacePick asks only for the information Apple cannot know.

A Place is created only after the user connects those two layers together.