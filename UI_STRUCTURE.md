# PlacePick — UI_STRUCTURE.md

Version: 5.0

---

# Purpose

This document defines how users interact with PlacePick.

While other documents define the product's concepts, this document defines how those concepts become a coherent user experience.

It specifies:

- Workspace structure
- Interaction patterns
- Primary user flows
- Presentation behavior

The goal is not to describe individual screens.

The goal is to define a consistent interaction model.

---

# Relationship to Other Documents

This document should be read together with:

- MVP.md
- COLLECTIONS.md
- DATA_MODEL.md
- RECOMMENDATION_MODEL.md

Responsibilities are divided as follows.

MVP.md defines:

- Product philosophy
- Core user experience
- Product scope

COLLECTIONS.md defines:

- How users organize their Personal Map

DATA_MODEL.md defines:

- Place Identity
- Personal Relationship
- Persistence

RECOMMENDATION_MODEL.md defines:

- How Relationships become Importance

This document defines:

- How users interact with those concepts
- How Recommendation becomes presentation
- How interactions remain consistent throughout the product

UI should never redefine product concepts.

It presents them.

---

# Core UI Principles

## 1. Map First

The map is the primary workspace.

Users should spend most of their time interacting with the map rather than navigating between pages.

Whenever possible, the map remains visible while secondary interfaces appear as native sheets or cards.

---

## 2. Native First

Prefer platform conventions whenever they provide an excellent experience.

Examples include:

- MapKit interaction
- Native sheets
- Native gestures
- SF Symbols
- System typography
- System colors
- Standard animations

Avoid custom controls when native behavior already feels familiar.

---

## 3. Personal Layer Only

Apple Maps owns:

- Place Identity
- Search
- Navigation
- Business information
- Geographic knowledge

PlacePick owns:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

The interface should ask users only for information Apple Maps cannot know.

---

## 4. Relationship First

Most interactions edit the user's relationship with a Place.

Examples include:

- changing Collection
- recording Emotion
- writing Notes
- marking Favorite
- adding a Memory Photo

These interactions should feel immediate and lightweight.

---

## 5. Identity Is Explicit

Changing a Place's real-world identity is fundamentally different from editing a personal relationship.

Identity changes should always be:

- explicit
- deliberate
- reversible whenever possible

Identity correction should never feel like ordinary editing.

---

## 6. One Concept, One Interaction

Each user action should have one clear responsibility.

Examples:

Tap Collection

→ Change Collection

Tap Emotion

→ Change Emotion

Tap Favorite

→ Toggle Favorite

Tap Note

→ Edit Note

Interactions should not mix unrelated concepts.

---

# Interaction Philosophy

PlacePick is designed around one continuous workspace.

Conceptually:

```text
             Map
              │
     ┌────────┼────────┐
     │        │        │
Collection  Place   Current
   Bar      Detail  Location
```

Users should rarely feel that they have "left" the map.

Instead, interactions temporarily layer on top of the workspace before naturally returning to it.

The map remains the user's anchor throughout the product.

---

# Main Workspace

PlacePick is fundamentally a single-workspace application.

Conceptually:

```text
┌──────────────────────────────────────┐
│ Collection Bar                       │
├──────────────────────────────────────┤
│                                      │
│              Map                     │
│                                      │
│     Current Location                 │
│     Saved Places                     │
│                                      │
│                              +       │
└──────────────────────────────────────┘
```

Everything else in the product originates from this workspace.

Users should always be able to understand where they are without navigating through multiple levels of pages.

---

# Workspace Components

The primary workspace contains:

- Map
- Collection Bar
- Saved Place symbols
- Current location indicator
- Add Place button

Secondary interfaces appear temporarily as:

- Sheets
- Bottom cards
- Pickers
- Context menus
- Confirmation dialogs

The product intentionally avoids introducing a permanent multi-tab navigation structure.

---

# Primary Entry Points

The workspace exposes only a small number of primary actions.

These include:

- Select Collection
- Select Place
- Add Place
- Manage Collections

All other interactions originate from one of these entry points.

Keeping the number of primary actions intentionally small helps preserve the simplicity of the map experience.

---

# Part 1 Summary

PlacePick is a map-centered application.

The map is not one screen among many.

It is the user's primary workspace.

Most interactions modify the user's relationship with Places while remaining anchored to that workspace.

The interface should remain native, lightweight, and focused on the personal layer rather than the geographic layer.

---

# Core Place Flows

Every interaction with a Place belongs to one of five flows:

```text
Capture

↓

Review

↓

Maintain

↓

Correct

↓

Delete
```

Each flow has a single responsibility.

Users should never edit multiple concepts simultaneously.

---

# Capture Flow

The Capture Flow creates a new Place in the user's Personal Map.

Conceptually:

```text
Map

↓

Tap "+"

↓

MapKit Search

↓

Select Place

↓

Choose Collection

↓

Edit Personal Relationship

↓

Save

↓

Return to Map
```

The flow intentionally separates:

1. Selecting a real-world Place.
2. Recording a personal relationship.

The first belongs to Apple Maps.

The second belongs to PlacePick.

---

# Place Selection

Place selection always uses MapKit.

Users may search using:

- Place names
- Addresses
- Landmarks

Search suggestions come directly from MapKit.

A Place is created only after the user selects one resolved MapKit result.

Users never create Places from:

- free text
- manually entered coordinates
- unresolved imported text

PlacePick never asks users to describe a Place.

It asks them to choose one.

---

# Collection Selection

Every Place belongs to exactly one Collection.

Collection selection occurs before saving.

The Collection picker should:

- follow user-defined order
- clearly indicate the current selection
- allow creating a new Collection without leaving the Capture Flow

The user should never be forced to abandon the Capture Flow in order to organize Collections.

---

# Personal Relationship

After selecting a Place, the user immediately records only the personal layer.

Relationship fields include:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Apple Maps identity is already known.

The user should never manually edit:

- Place name
- Coordinates
- Apple Maps identifier

---

# Duplicate Handling

Before creating a new Place:

The app checks whether the selected Apple Maps identifier already exists.

If no matching Place exists:

Create the new Place.

If a matching Place already exists:

Open the existing Place instead.

The MVP intentionally does not support saving the same real-world Place multiple times.

---

# Place Detail

After a Place has been created, interactions occur through the Place Detail Card.

Conceptually:

```text
Memory Photo

↓

Place Name

↓

Collection

↓

Favorite

↓

Emotion

↓

Note

↓

Open in Apple Maps
```

The Place Detail Card represents the user's relationship with the selected Place.

It is not a business listing.

Apple Maps remains responsible for:

- navigation
- business information
- reviews
- operating hours
- contact information

---

# Relationship Editing Flow

Relationship editing is lightweight.

Users edit information directly from the Place Detail Card.

Examples include:

Tap Collection

→ Change Collection

Tap Favorite

→ Toggle Favorite

Tap Emotion

→ Choose Emotion

Tap Note

→ Edit Note

Tap Memory Photo

→ Add, replace, or remove

Relationship editing should never require a dedicated full-screen edit mode.

The interaction should feel immediate.

---

# Identity Correction Flow

Identity correction is fundamentally different from relationship editing.

Relationship answers:

> What does this Place mean to me?

Identity answers:

> Which real-world Place is this?

Identity correction is entered from the More menu.

Conceptually:

```text
Place Detail

↓

More

↓

Replace Place

↓

MapKit Search

↓

Select New Place

↓

Duplicate Check

↓

Confirm

↓

Return to Detail
```

Identity correction updates:

- Place name
- Coordinates
- Apple Maps identifier
- MapKit-derived metadata

Identity correction preserves:

- Collection
- Favorite
- Emotion
- Note
- Memory Photo

Correcting identity should feel like fixing a mistaken map reference rather than creating a new memory.

---

# Delete Flow

Delete permanently removes a Place from the Personal Map.

Deletion is available from the More menu.

The operation requires confirmation.

Deleting a Place removes:

- Identity
- Personal Relationship

Deleting a Place never deletes its Collection.

Replace Place should never be implemented as:

Delete

↓

Create

from the user's perspective.

Identity correction and deletion are separate user intentions.

---

# Open in Apple Maps

PlacePick intentionally delegates geographic functionality to Apple Maps.

The Place Detail Card provides an explicit:

Open in Apple Maps

action.

Apple Maps remains responsible for:

- directions
- navigation
- live traffic
- business information
- contact details
- reviews

PlacePick should never duplicate these capabilities.

---

# Part 2 Summary

The lifecycle of a Place consists of five distinct flows:

Capture

↓

Review

↓

Maintain Relationship

↓

Correct Identity

↓

Delete

Each flow has one responsibility.

Relationship editing remains lightweight.

Identity correction remains explicit.

Geographic knowledge belongs to Apple Maps.

Personal meaning belongs to PlacePick.


---

# Organization & Attention Presentation

After Places have been saved, the primary experience becomes browsing and rediscovering the user's Personal Map.

Two systems shape this experience:

- Collections organize Places.
- Recommendation guides attention.

Neither system changes the underlying Place data.

---

# Collection Browsing

Collections are the primary way users browse their Personal Map.

The Collection Bar appears above the map.

Conceptually:

```text
All   Food   Coffee   Hiking   Japan 2027   …
```

Each Collection displays:

- Collection icon
- Collection name

`All` is a map view.

It is not a stored Collection.

Selecting a Collection filters the visible Places shown on the map.

Changing the selected Collection never modifies:

- Place Identity
- Personal Relationship
- Recommendation

Collections organize visibility only.

---

# Collection Bar

The Collection Bar should remain lightweight.

It should:

- preserve map visibility
- support horizontal scrolling
- clearly indicate the selected Collection
- avoid looking like a traditional tab bar

The Collection order follows the user's own ordering.

The interface should never imply that Collections are global place categories.

They are personal organization.

---

# Manage Collections

Collection management is presented as a lightweight sheet rather than a primary page.

Users may:

- Create Collection
- Rename Collection
- Change Collection Icon
- Reorder Collections
- Delete Collection

The sheet should preserve the feeling that users are organizing one Personal Map rather than managing a separate database.

---

# Collection Deletion

Deleting a Collection must preserve every Place.

If a Collection still contains Places:

The user chooses another Collection.

Conceptually:

```text
Delete "Coffee"?

15 Places belong to this Collection.

Move Places to:

[ Choose Collection ]

Cancel        Move and Delete
```

Rules:

- Every Place moves exactly once.
- Reassignment and deletion occur atomically.
- The destination Collection cannot be the Collection being deleted.
- No Place may exist without a Collection.

The product should never invent an automatic destination.

---

# Attention Presentation

Recommendation determines Importance.

Presentation determines how Importance appears on the map.

Conceptually:

```text
Relationship

↓

Recommendation

↓

Importance

↓

Presentation

↓

Map
```

Presentation may use Importance to influence:

- symbol prominence
- label visibility
- annotation priority
- cluster release priority

Presentation must never modify Recommendation itself.

---

# Map Presentation

Presentation adapts continuously to the viewing context.

Context includes:

- current viewport
- zoom level
- annotation density

Presentation may:

- enlarge important symbols
- reduce label clutter
- cluster nearby Places
- simplify crowded regions

These changes improve readability.

They never change Importance.

---

# Nearby Discovery

Nearby is not a separate feature.

It naturally emerges from three concepts:

- current viewport
- current Collection
- saved Places

Conceptually:

```text
Current Viewport

+

Selected Collection

+

Saved Places

↓

Nearby Discovery
```

Users discover nearby Places simply by exploring the map they are already viewing.

---

# Current Location

Current location provides spatial context.

It is not Place data.

When permission is granted, the map uses the native MapKit user-location presentation.

This may include:

- blue location dot
- accuracy radius
- heading indicator

PlacePick should not create a custom location marker.

Current location is never:

- stored
- attached to Places
- included in Recommendation
- recorded as history

It only helps users understand where they are relative to their saved Places.

---

# Initial Viewport

When the app launches:

If a previous viewport exists:

Restore it.

Otherwise:

If location is available:

Use the current location as the initial viewport.

The map should never repeatedly pull users away from a region they intentionally chose to explore.

The user's browsing context should always take priority over automatic recentering.

---

# Part 3 Summary

Collections organize the Personal Map.

Recommendation guides attention.

Presentation makes attention visible.

The map remains the primary browsing experience.

Users discover nearby Places simply by exploring their own map rather than navigating through separate pages.


---

# System States & External Entry

The previous sections describe normal interaction with the Personal Map.

This section defines how PlacePick behaves at its boundaries:

- entering the app
- importing content
- handling missing data
- handling unavailable system services

These situations should feel consistent with the rest of the product.

---

# Share & Import

The Share Extension provides an alternative entry into the Capture Flow.

Conceptually:

```text
Social App

↓

Share

↓

PlacePick

↓

Extract Text

↓

MapKit Search

↓

User Selects Place

↓

Choose Collection

↓

Save

↓

Return to Map
```

Import should never bypass Place selection.

Imported content suggests a Place.

The user confirms the Place.

Every entry path ultimately converges on the same Capture Flow.

---

# Location Permission

Location permission exists only to provide spatial context.

The app requests **When In Use** authorization only when location first becomes useful.

For most users, this occurs when the map is first displayed.

Location permission remains optional.

If permission is denied:

- the map remains usable
- saved Places remain accessible
- Collections continue to function
- Recommendation behaves normally

Only the current-location indicator becomes unavailable.

---

# Current Location Behavior

Current location belongs to the workspace.

It never becomes Place data.

The app does not:

- request Always authorization
- track background location
- store location history
- attach location history to Places

The blue location indicator exists only to answer one question:

> Where am I relative to my saved Places?

---

# Initial Launch Behavior

The app should preserve browsing continuity whenever possible.

On launch:

If a previous viewport exists:

Restore it.

Otherwise:

If location is available:

Use the user's current location.

The app should never repeatedly override an intentional browsing region.

The user's last browsing context has higher priority than automatic centering.

---

# Empty States

Empty states should encourage progress rather than explain missing functionality.

## No Saved Places

Suggested message:

> Save places you want to remember.

Primary action:

Add Place

---

## Empty Collection

Suggested message:

> No places in this Collection yet.

The map remains visible.

Users may:

- Add Place
- Switch Collection
- Manage Collections

---

## No Collections

Suggested message:

> Create your first Collection to start building your map.

Suggested Collections may be offered.

The user always remains in control.

---

## Location Unavailable

Suggested message:

> Current location is unavailable.

Avoid alarming language.

The Personal Map continues functioning normally.

---

# Cancellation Behavior

Users should be able to abandon any incomplete flow without unintended side effects.

Examples include:

Cancel Capture

↓

No Place created

Cancel Replace Place

↓

Existing Place remains unchanged

Dismiss Collection Picker

↓

Collection unchanged

Dismiss Emotion Picker

↓

Emotion unchanged

Partial interactions should never leave inconsistent data.

---

# System Invariants

Every interaction should preserve the following rules.

A Place always belongs to exactly one Collection.

Recommendation never edits data.

Presentation never changes Recommendation.

Identity correction preserves Personal Relationship.

Relationship editing never changes Identity.

Deleting a Place never deletes its Collection.

Deleting a Collection never deletes Places.

Every flow should either:

complete successfully

or

leave the existing Personal Map unchanged.

---

# Final UI Principles

> The map is the user's workspace.

> Apple Maps owns geography.

> PlacePick owns personal meaning.

> Users organize Places through Collections.

> Recommendation guides attention, not behavior.

> Every interaction should modify exactly one concept.

> The user should always know where they are, what they are editing, and why.

> The interface should remain calm, native, and focused on the user's Personal Map.