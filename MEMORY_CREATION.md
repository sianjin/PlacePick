# PlacePick — MEMORY_CREATION

Version: 1.0

---

# Purpose

Memory Creation is the primary way to capture experiences in PlacePick.

The goal is not to import a photo library.

The goal is to transform existing photos into meaningful Memories with as little work as possible.

---

# Philosophy

- Users think in memories, not imports.
- The system suggests.
- The user confirms.
- Nothing is saved until confirmation.
- One Memory represents one visit to one place.

---

# Mental Model

The creation flow follows the natural way people remember experiences.

```
Photos

↓

This was an experience

↓

Where did it happen?

↓

Save
```

The interface should never expose implementation concepts such as clustering,
GPS matching, or AI extraction.

---

# Creation Flow

```
Tap +

↓

What would you like to save?

• A Place
• A Memory
```

Selecting **A Memory** starts the following flow.

```
Choose Photos

↓

Review Groups & Confirm Places

↓

Review

↓

Create Memories
```

---

# Stage 1 — Choose Photos

The user selects one or more photos from the system photo picker.

No Memories are created at this stage.

---

# Stage 2 — Review Groups & Confirm Places

Originally split into a separate group-review screen and a separate place-confirmation
screen (formerly Stage 3); merged into one screen so reviewing group boundaries,
confirming a place, and choosing a Collection are decisions about the same group, not
separate screens the user has to hold in their head across. See ReviewGroupsStage.swift.

The system suggests groups that likely belong to the same visit. For each group, the
user sees its photos, its suggested place, and its Collection together, in one place —
reviewing group boundaries, confirming a place, and choosing a Collection are all
decisions about the same group, not separate screens the user has to hold in their
head across. A single import can span unrelated kinds of places (a hike and a
restaurant), so Collection is chosen per group, never once for the whole batch.

Example:

```
──────────────────

📷📷📷

9:12 – 9:40

Blue Bottle Coffee ✓
Food

──────────────────

📷📷

11:20 – 11:45

[ mini-map: tap a nearby pin ]
Search for a Place

──────────────────
```

Searching for a place offers two ways to pick one: typing in the search bar, or tapping
a pin directly on a small map centered on the group's photos — the same choice Photos.app
itself offers on a photo's own location screen. The mini-map always shows real nearby
points of interest; it does not depend on a suggestion existing.

The user may:

- Merge groups
- Split groups
- Move photos
- Remove photos
- Reorder photos within a group by dragging — the first photo becomes the Memory's cover
  photo, so dragging a favorite to the front is how the cover is chosen; no separate
  "set as cover" action exists
- Accept the suggested place, or choose another
- Accept the default Collection, or choose another

Groups remain temporary until confirmed. Every Memory must be associated with exactly
one Place and one Collection.

---

# Stage 3 — Review

The user reviews the Memories that will be created.

Example:

```
Blue Bottle Coffee
3 Photos

────────────

Golden Gate Bridge
2 Photos
```

Nothing has been saved yet.

---

# Stage 4 — Create

After confirmation:

- Memories are created.
- Photos are attached to each Memory.
- Places are linked.
- The user returns to browsing.

---

# Principles

- Capture memories, not files.
- Photos are evidence of a memory.
- Places organize memories.
- The system assists.
- The user decides.
- Creation should feel calm, lightweight, and trustworthy.
