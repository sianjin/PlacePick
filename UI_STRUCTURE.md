# PlacePick — UI_STRUCTURE.md

Version: 4.2

---

## 1. Purpose

This document defines PlacePick's user-facing structure and interaction patterns.

PlacePick should feel like **Apple Maps with a personal memory layer**.

The map is always the primary interface. PlacePick should not recreate search, navigation, business information, or other functionality already owned by Apple Maps.

Collections are the user's own way of organizing that personal map.

---

## 2. Core UI Principles

### 2.1 Map First

The map is the product.

The map should remain visible whenever possible and should not be replaced by a separate browsing hierarchy.

### 2.2 Native First

Prefer:

- Native MapKit behavior
- Native SwiftUI sheets
- Native gestures
- Native user-location presentation
- SF Symbols
- System colors
- Default platform animations

Do not introduce custom controls when a clear native control already exists.

### 2.3 Personal Layer Only

Apple Maps owns:

- Place identity
- Place name
- Coordinates
- Search
- Navigation
- Business information

PlacePick owns:

- Collection
- Favorite
- Emotion
- Note
- Memory photo

Current location is map context. It is not stored Place data.

### 2.4 Immediate Editing

Relationship fields should be editable directly from the Place Detail Card.

There is no dedicated full-screen edit mode for ordinary relationship editing.

### 2.5 Identity Is Different from Relationship

Editing the user's relationship with a Place and replacing the Place's real-world identity are fundamentally different operations.

Relationship editing should be lightweight.

Replacing Place identity should be explicit and controlled.

### 2.6 Collections Are User-Owned

Collections are not fixed place categories.

They are the user's own organizational structure.

The interface should never imply that a Collection objectively describes what a Place is.

---

# 3. Main Map

## 3.1 Map Content

The map displays only Places saved by the user.

It does not attempt to reproduce the full Apple Maps point-of-interest layer.

## 3.2 Map Controls

Preserve native behavior and controls where appropriate:

- Pan
- Zoom
- Rotation
- Compass
- Current-location indicator
- Apple Maps attribution

## 3.3 Current Location

The map displays the user's current location using MapKit's native user-location presentation.

This may include, when available:

- Blue location dot
- Accuracy radius
- Device heading indicator
- Live location updates while the app is in use

PlacePick should not design a custom user-location marker.

### Location Control

MVP does not include a dedicated recenter control.

The user locates themselves by reading the native blue dot and panning/zooming manually, the same way they would on any native map surface.

A native recenter control (e.g. `MapUserLocationButton`) may be added in a later pass once its behavior can be verified reliably; it is not required for MVP.

### Permission Behavior

Request **When In Use** location authorization only when location is first needed — in practice, the first time the map appears, rather than immediately at process launch.

Location permission is optional.

If permission is denied:

- The map remains usable.
- Saved Places remain fully accessible.
- Collection browsing remains available.
- The blue dot simply does not appear.

Suggested permission explanation:

> PlacePick uses your location to show where you are relative to the places you saved.

### Location Rules

PlacePick does not:

- Request Always Location permission
- Track location in the background
- Store location history
- Save the user's current location as Place data
- Attach movement history to Places
- Force the map to remain centered after the user begins browsing
- Make recommendation directly dependent on live user location

### Initial Viewport

When a useful previous viewport exists, restore it.

When no meaningful viewport exists and location is available, the user's current location may be used as the initial viewport.

Opening the app should not repeatedly pull the map away from a region the user was intentionally browsing.

> Always show where the user is, but move the map only when the user asks.

## 3.4 Place Symbols

Each saved Place uses the SF Symbol of its Collection.

Recommendation may affect prominence, but never availability.

Recommendation may influence:

- Symbol size
- Label visibility
- Cluster release priority

Recommendation must never:

- Hide a saved Place
- Change the selected Collection
- Move a Place into another Collection
- Move the map automatically
- Modify stored Place data

## 3.5 Collection Bar

A horizontally scrollable Collection Bar appears over the map.

Conceptually:

```text
All   Food   Beaches   Date   Japan 2027   …
```

Each item may show:

- Collection icon
- Collection name

`All` is a map view, not a stored Collection.

Selecting a Collection shows only Places assigned to that Collection.

Selecting `All` shows Places from every Collection.

The Collection Bar follows the user's Collection order.

## 3.6 Collection Bar Behavior

The Collection Bar should:

- Remain lightweight
- Preserve as much map visibility as possible
- Make the selected state clear
- Support horizontal scrolling
- Avoid looking like a traditional tab bar

Changing the selected Collection changes map visibility only.

It does not modify stored Place data or recommendation scores.

## 3.7 Nearby Discovery

PlacePick does not need a separate Nearby page in MVP.

The combination of:

- Current-location indicator
- Location control
- Current map viewport
- Collection Bar
- Saved Place symbols

is the Nearby experience.

Example flow:

```text
Tap Current Location
→ Select Food
→ See saved food Places around the current viewport
→ Open one Place
→ Open in Apple Maps
```

The viewport defines what "nearby" means.

## 3.8 Manage Collections Entry Point

The end of the Collection Bar should provide a lightweight way to open **Manage Collections**.

A suitable native control may be:

- An ellipsis button
- An edit button
- A context menu

The control should not compete visually with the map.

---

# 4. Add Place

## 4.1 Entry Point

The user taps the **+** button from the map.

## 4.2 Add Place User Flow

```text
┌──────────────────┐
│       Map        │
└────────┬─────────┘
         │
      Tap "+"
         │
         ▼
┌────────────────────────────┐
│ Apple Maps-style Search UI │
└────────────┬───────────────┘
             │
     Live MapKit Suggestions
             │
             ▼
  User selects one MapKit result
             │
             ▼
┌────────────────────────────┐
│ Edit Personal Information  │
│ • Collection               │
│ • Favorite                 │
│ • Emotion                  │
│ • Note                     │
│ • Memory Photo             │
└────────────┬───────────────┘
             │
           Save
             │
             ▼
       Return to Map
```

## 4.3 Search UI

The search experience should closely follow Apple Maps.

The search field accepts:

- Place names
- Addresses
- Landmarks

Search suggestions come directly from MapKit.

PlacePick does not build its own search index or custom suggestion engine.

## 4.4 Search Rule

A Place can only be created by selecting a MapKit search result.

Users never create a Place from:

- Free text
- Arbitrary coordinates
- A manually typed place name
- Unresolved imported text

> PlacePick does not ask the user to describe a Place. It asks the user to select one.

## 4.5 After Selection

Once the user selects a MapKit result, PlacePick already knows:

- Place name
- Coordinates
- Apple Maps identifier
- MapKit-derived metadata, when available

The user should not be asked to reconfirm or manually edit these facts.

The user immediately edits only the personal layer.

## 4.6 Collection Selection

Every new Place must be assigned to exactly one Collection before saving.

The Collection picker shows the user's Collections in user-defined order.

It should also provide a lightweight **New Collection** action.

Creating a Collection from this flow should return the user directly to the Place draft with the new Collection selected.

The app must not require the user to leave the Add Place flow and manage Collections elsewhere first.

## 4.7 Save Behavior

On Save:

1. Confirm that one Collection is selected.
2. Check whether the selected Apple Maps identifier already exists.
3. If it does not exist, create the Place.
4. If it already exists, open the existing Place instead of creating a duplicate.

The MVP does not offer **Save Another** for the same real-world Place.

---

# 5. Place Detail Card

## 5.1 Purpose

The Place Detail Card represents the user's relationship with a Place.

It is not a business listing.

## 5.2 Content

The card may contain:

- Memory photo
- Place name
- Collection
- Favorite
- Emotion
- Note
- Open in Apple Maps
- More menu

It should not prioritize:

- Business hours
- Reviews
- Phone number
- Website
- Full address
- Navigation instructions

Apple Maps already owns those functions.

## 5.3 Conceptual Layout

```text
┌──────────────────────────────────────┐
│ Optional Memory Photo                │
├──────────────────────────────────────┤
│ Place Name                       ⋯   │
│ Collection icon + name               │
│                                      │
│ ☆ / ★        😐 / 😊 / 🤩           │
│                                      │
│ Personal note                        │
│                                      │
│ Open in Apple Maps                   │
└──────────────────────────────────────┘
```

---

# 6. Direct Relationship Editing

There is no dedicated edit screen for ordinary relationship fields.

## 6.1 Interactions

| Field | Interaction |
|---|---|
| Note | Tap note to edit |
| Emotion | Tap emoji to open picker |
| Favorite | Tap star to toggle |
| Collection | Tap Collection to open picker |
| Memory photo | Tap photo area to add, replace, or remove |
| Delete | Use the More menu |

Editing should feel immediate and lightweight.

## 6.2 Changing Collection

Changing a Place's Collection is a direct relationship edit.

The Collection picker should:

- Show all existing Collections
- Preserve the user's Collection order
- Clearly mark the current Collection
- Offer **New Collection**

Selecting a different Collection applies immediately or through one lightweight confirmation action, depending on the native picker pattern used.

Changing Collection must not affect:

- Place identity
- Favorite
- Emotion
- Note
- Memory photo
- Recommendation score

## 6.3 Editing Scope

Direct editing applies only to the user's relationship fields.

The following are not freely editable:

- Place name
- Coordinates
- Apple Maps identifier

These fields belong to the selected Apple Maps identity.

---

# 7. Manage Collections

## 7.1 Purpose

Manage Collections allows users to shape the organizational structure of their own map.

It should be presented as a native sheet rather than as a new primary page.

## 7.2 Collection List

The sheet displays Collections in current user-defined order.

Each row may contain:

- SF Symbol
- Collection name
- Reorder handle
- More or edit action

Conceptually:

```text
Manage Collections

≡  fork.knife       Food
≡  beach.umbrella   Beaches
≡  heart            Date
≡  airplane         Japan 2027

+ New Collection
```

## 7.3 Create Collection

Creating a Collection requires:

- Name
- SF Symbol

A new Collection should receive a stable internal ID.

It should be placed at the end of the current Collection order unless the user explicitly reorders it.

## 7.4 Rename Collection

Users may rename any Collection.

Renaming a Collection updates how it appears everywhere without changing the Places assigned to it.

## 7.5 Change Collection Icon

Users may choose a different supported SF Symbol.

Changing the icon updates the Collection Bar, map symbols, pickers, and Place Detail Cards.

It must not modify any Place relationship other than its visual Collection reference.

## 7.6 Reorder Collections

Users may reorder Collections through a native drag interaction.

The Collection Bar follows the saved order.

`All` remains fixed at the beginning and is not part of the user-defined order.

## 7.7 Delete Collection

A Collection containing no Places may be deleted after lightweight confirmation.

A Collection containing Places cannot be deleted immediately.

The user must first choose a destination Collection for those Places.

Conceptual flow:

```text
Delete "Beaches"?

12 Places belong to this Collection.

Move Places to:
[ Choose Collection ]

Cancel                  Move and Delete
```

Rules:

- Every affected Place moves to one selected destination Collection.
- Reassignment and deletion occur atomically.
- The destination cannot be the Collection being deleted.
- The app must never leave a Place without a Collection.
- The app must never silently choose a destination.
- There is no automatic move to an `Other` Collection.

## 7.8 Empty Collection Set

The app should always allow the user to create a Collection before adding a Place.

The last remaining Collection may be deleted only when it contains no Places.

When no Collections remain, the Add Place flow must require the user to create one before saving.

Suggested Collections may be offered as optional starting points, but must not be silently recreated after the user deletes them.

---

# 8. Replace Place

## 8.1 Purpose

Replace Place is used when the user selected the wrong Apple Maps result.

Examples:

- Wrong restaurant branch
- Wrong building
- Wrong business with a similar name
- Nearby location selected accidentally

This is not ordinary editing.

It replaces the real-world identity attached to the existing personal relationship.

## 8.2 Entry Point

The user opens the **More** menu from the Place Detail Card.

```text
⋯

Replace Place
Delete
```

Collection editing remains available through direct tap and does not need to be duplicated in the More menu.

## 8.3 Replace Place Flow

```text
Existing Place Detail
        │
      Tap "⋯"
        │
        ▼
   Replace Place
        │
        ▼
Apple Maps-style Search
        │
        ▼
Select a new MapKit result
        │
        ▼
Duplicate Check
        │
   ┌────┴────┐
   │         │
 New       Existing
   │         │
   ▼         ▼
Confirm    Open Existing
Replace
   │
   ▼
Return to Place Detail
```

## 8.4 Reused Search UI

Replace Place reuses the same MapKit search experience used by Add Place.

Do not create a second search implementation.

## 8.5 Data Preservation

Replacing Place identity preserves:

- Collection
- Favorite
- Emotion
- Note
- Memory photo

Replacing Place identity updates:

- Place name
- Coordinates
- Apple Maps identifier
- MapKit-derived metadata

The operation should feel like correcting the selected location, not creating a new personal memory.

## 8.6 Duplicate Result During Replacement

If the replacement target already exists as another saved Place:

- Do not merge automatically
- Do not create a duplicate
- Open the existing Place
- Preserve the current Place until the user explicitly deletes or changes it

Automatic merging is out of scope for MVP because it could silently destroy or combine personal data.

## 8.7 Confirmation

Because Replace Place changes identity, show a lightweight confirmation before applying it.

Example:

```text
Replace this Place with "Din Tai Fung — Valley Fair"?

Your Collection, note, emotion, favorite, and memory photo will be kept.
```

Actions:

- Replace
- Cancel

---

# 9. Delete Place

Delete is available from the More menu.

Deletion should require confirmation.

Deleting removes the Place and its personal relationship data.

It does not delete the Collection containing it.

Replace Place should never be implemented as delete-and-recreate in the UI.

---

# 10. Open in Apple Maps

PlacePick should provide an explicit action to open the selected Place in Apple Maps.

Apple Maps handles:

- Directions
- Navigation
- Business details
- Hours
- Reviews
- Contact information

PlacePick should not duplicate these features.

---

# 11. Share Import Handoff

The Share Extension extracts enough information to resolve a Place through MapKit.

The main app opens automatically and presents the same Add Place search and selection flow.

Imported text must not create a Place directly.

All import paths converge on user selection of one MapKit result and one Collection.

---

# 12. Empty States

## 12.1 No Saved Places

Prefer:

> Save places you want to remember.

The primary action should begin Add Place.

## 12.2 Empty Selected Collection

Prefer:

> No places in this Collection yet.

The map remains visible.

The user may:

- Add a Place
- Switch Collections
- Manage Collections

## 12.3 No Collections

Prefer:

> Create your first Collection to start building your map.

Suggested Collections may be offered, but the user remains in control.

## 12.4 Location Unavailable

When location is unavailable, avoid alarming language.

Prefer:

> Current location is unavailable.

The map and saved Places remain usable.

---

# 13. Recommendation and Location

Recommendation remains based on the current map viewport, not directly on live user location.

The relationship is:

```text
Current Location (when available)
→ May seed the initial viewport

Recommendation
→ Evaluates Places relative to the current viewport
```

This preserves correct behavior when the user browses a distant city.

Current location should never automatically override intentional map exploration.

---

# 14. Final UI Principles

> Whenever Apple already knows the answer, PlacePick should not ask the user again.

> Collections organize the user's map; they do not classify the world.

> The blue dot shows where the user is. Saved Places show what matters around them.

PlacePick should ask only for the personal information Apple cannot know.
