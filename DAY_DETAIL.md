# MomentMap — DAY_DETAIL

Version: 1.0

---

# Purpose

Day Detail answers one question:

> **What happened on this day?**

It is a chronological journal built from Memories.

The page should feel like reliving a day rather than browsing a database.

---

# Design Philosophy

A day is experienced through its Memories.

Day Detail does not introduce a new UI.

Instead, it presents Memory Cards in chronological order.

The Memory Card is the fundamental building block of MomentMap.

---

# Layout

```
July 18, 2026

────────────────────

Memory Card

────────────────────

Memory Card

────────────────────

Memory Card
```

Each card represents one Memory.

---

# Memory Card

```
┌──────────────────────────┐
│                          │
│       Large Photo         │
│                          │
│         ● ○ ○            │
└──────────────────────────┘

Blue Bottle Coffee

😊 Loved it

第一次和朋友來這裡。

下次想再試試另一款咖啡。

────────────────────

July 18, 2026 · 9:12 AM
```

The same Memory Card is used throughout MomentMap.

---

# Timeline

- Memories are sorted by capture time.
- Multiple visits to the same Place remain separate.
- The timeline preserves the actual flow of the day.
- No automatic merging of repeated Places.

Example:

```
9:12   Blue Bottle Coffee

11:35  Golden Gate Bridge

17:40  Blue Bottle Coffee
```

These remain three separate Memories.

---

# Interaction

- Scroll vertically through the day.
- Tap any Memory Card to open Memory Detail.
- Swipe horizontally inside a card to browse its photos.
- Swipe back to return to the day.

---

# Principles

- A day is a story, not a list.
- Preserve chronological order.
- Every Memory deserves its own card.
- Photos are the primary storytelling medium.
- Repeated places are part of the journey.
- Reading the page should feel like reliving the day.
