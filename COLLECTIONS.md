# PlacePick — COLLECTIONS.md

Version: 1.0

---

# Purpose

This document defines how Places are organized inside PlacePick.

Collections are one of the core concepts of the product.

They determine how users organize their own maps.

This document intentionally focuses on **organization**, not recommendation, rendering, or data persistence.

---

# Core Principle

> Apple Maps organizes the world.

> **Users organize their own map.**

Apple Maps classifies places according to real-world business types.

PlacePick does not.

PlacePick allows every user to organize saved places in whatever way feels natural to them.

---

# Why Collections Instead of Categories?

Traditional map apps use fixed categories.

Examples:

- Restaurant
- Cafe
- Museum
- Hotel
- Shopping

This works well for discovering public places.

It works poorly for organizing personal memories.

Different people naturally think in different ways.

One user might organize places by:

- Food
- Drink
- Shopping

Another user might prefer:

- Beaches
- Hiking
- Skiing
- Fruit Picking

Another might organize by life events:

- Date
- Family
- Japan 2027

There is no universally correct structure.

PlacePick therefore lets users define their own Collections.

---

# One Place Belongs to One Collection

Each Place belongs to exactly one Collection.

This keeps the map simple and predictable.

Collections are intended to represent the user's primary way of organizing their map.

PlacePick intentionally does not support assigning one Place to multiple Collections.

Multiple Collections would gradually become a tagging system rather than an organizational structure.

---

# Suggested Collections

When a user first installs PlacePick, the app provides a small set of suggested Collections.

Examples may include:

- Food
- Drink
- Dessert
- Shopping
- Museum
- Hotel

These are only starting points.

Users remain free to:

- Keep them
- Rename them
- Delete them
- Reorder them
- Ignore them completely

The app does not assume these Collections are correct.

---

# Creating Collections

Users may create their own Collections at any time.

Examples:

- Beach
- Hiking
- Fruit Picking
- Skiing
- Photography
- Date
- Family
- Weekend Trips

Collections should reflect how the user naturally thinks.

They are personal organizational tools rather than objective place classifications.

---

# Collection Icon

Each Collection has one SF Symbol chosen by the user.

Examples:

Food
→ fork.knife

Beach
→ beach.umbrella

Museum
→ building.columns

Photography
→ camera

The icon exists only to improve recognition.

It has no semantic meaning within the recommendation system.

---

# Collection Order

Collections are displayed in a user-defined order.

Users may reorder them at any time.

The map's top Collection bar follows this order.

Example:

All

Food

Beach

Photography

Weekend

The order reflects personal preference rather than any product-defined priority.

---

# No "Other" Collection

PlacePick intentionally does not include an "Other" Collection.

If a Place does not belong in an existing Collection, the correct action is to create a new Collection.

"Other" gradually becomes an unorganized bucket and weakens the user's map structure.

Creating meaningful Collections keeps the map personal and understandable.

---

# Relationship to Recommendation

Collections do not influence recommendation scores.

Recommendation answers:

> Which saved Places deserve more visual attention?

Collections answer:

> How does the user organize their world?

These are independent systems.

Changing a Place's Collection must not change its Importance Score.

---

# Relationship to Apple Maps

Apple Maps may know that a Place is:

- a restaurant
- a museum
- a park

This information belongs to Apple Maps.

PlacePick does not require Collections to mirror Apple Maps classifications.

A museum may belong to:

- Museums
- Date
- Family
- Japan Trip

depending on how the user thinks.

---

# Engineering Invariants

1. Every Place belongs to exactly one Collection.
2. Collections are user-defined.
3. Collections may be renamed.
4. Collections may be reordered.
5. Collections may be deleted.
6. Collections may use any supported SF Symbol.
7. There is no "Other" Collection.
8. Recommendation is independent of Collections.

---

# Final Principle

> **Collections organize the user's memories, not the world's places.**

Apple Maps describes what a place is.

PlacePick remembers where it belongs in the user's own map.