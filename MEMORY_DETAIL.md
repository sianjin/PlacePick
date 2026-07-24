# PlacePick — MEMORY_DETAIL

Version: 1.0

---

# Purpose

Memory Detail is the heart of PlacePick.

Every browsing path eventually leads here.

```
Map
  ↓
Place
  ↓
Memory Detail

Calendar
  ↓
Day Detail
  ↓
Memory Detail
```

This document defines how a single Memory should be experienced.

---

# Design Philosophy

A Memory is experienced through its photos first, then enriched by place, emotion, and notes.

The interface should follow the natural order of human recall, not the storage order of the database.

People usually remember:

1. What they saw.
2. Where they were.
3. How they felt.
4. What happened.
5. When it happened.

The UI should respect this sequence.

---

# Layout

```
┌──────────────────────────┐
│                          │
│       Large Photo         │
│                          │
│         ● ○ ○            │
└──────────────────────────┘

Blue Bottle Coffee

😊 Loved it

第一次和朋友来這裡。

下次想再試試另一款咖啡。

────────────────────

July 18, 2026 · 9:12 AM
```

---

# Visual Hierarchy

## Photos

- Largest element on the page.
- Swipe horizontally.
- Use the native iOS page indicator.
- Photos are the hero of the experience.

## Place

- Primary title.
- Large and bold.
- Represents the identity of the Memory.

## Emotion

- Displayed directly below the place.
- A quick emotional summary.

## Note

- Optional.
- Hidden entirely when empty.
- Supports multiline text.

## Date & Time

- Displayed at the bottom.
- Secondary text color.
- Serves as metadata rather than content.

---

# Interaction

- Swipe to browse photos.
- Tap a photo for full-screen viewing.
- Tap Edit to modify the memory.
- Swipe back to return to the previous screen.

---

# Principles

- Photos first.
- Place anchors the memory.
- Emotion summarizes the experience.
- Notes preserve the story.
- Time provides context.
- Calm, spacious, and native.
