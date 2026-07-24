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

Review Memory Groups

↓

Confirm Places

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

# Stage 2 — Review Memory Groups

The system suggests groups that likely belong to the same visit.

Example:

```
──────────────────

📷📷📷

9:12 – 9:40

──────────────────

📷📷

11:20 – 11:45

──────────────────
```

The user may:

- Merge groups
- Split groups
- Move photos
- Remove photos

Groups remain temporary until confirmed.

---

# Stage 3 — Confirm Places

For each group, PlacePick suggests a place.

Example:

```
📷📷📷

↓

Blue Bottle Coffee ✓
```

The user may accept or choose another place.

Every Memory must be associated with exactly one Place.

---

# Stage 4 — Review

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

# Stage 5 — Create

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
