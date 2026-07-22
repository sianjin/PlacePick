# PlacePick — MVP.md

Version: 4.0

---

# Product Goal

Build the smallest possible product that proves the PlacePick philosophy.

PlacePick should feel like **your personal map**, not another map application.

---

# Product Positioning

PlacePick is a personal memory layer built on top of Apple Maps.

Apple Maps helps users navigate.

PlacePick helps users remember why a place mattered.

The product is intentionally focused on one loop:

1. Discover a place.
2. Save it in seconds.
3. Rediscover it naturally on your map.
4. Open it in Apple Maps or Google Maps when it's time to go.

Everything in the MVP should strengthen this loop.

---

# MVP Features

## Save Places

Users can add places in two ways:

- Share into PlacePick
- Manual Add

During Manual Add:

- Tap **+**
- Search using Apple MapKit
- Select a real place
- Add personal information
- Save

Search exists **only** to resolve a place during capture.

There is no global search on the main map.

---

## Map

The map is the primary interface.

Features:

- Apple MapKit base map
- Personal saved-place layer
- Zoom & pan
- Collection bar
- Cluster support
- Lightweight recommendation highlighting
- Native user-location indicator
- Current-location control

The map never disappears.

---
## Current Location

PlacePick displays the user's current location using MapKit's native location indicator.

The user may recenter the map through a native location control.

PlacePick does not:

- track location in the background
- store location history
- automatically move the map after the user begins browsing

---

## Collections

Collections are how users organize their own maps.

Each Place belongs to exactly one Collection.

Collections are user-defined.

Users may:

- Create Collections
- Rename Collections
- Delete Collections
- Reorder Collections
- Choose an SF Symbol for each Collection

PlacePick provides several suggested Collections for new users, but users are free to organize their maps however they like.

There is no **Other** Collection.

---

## Place Detail

Each Place contains only:

- Memory Photo (optional)
- Place name
- Collection
- Favorite ⭐
- Emotion (😐 😊 🤩)
- One personal note
- Open externally (□↗︎)

It intentionally excludes:

- Address
- Business hours
- Phone
- Reviews
- Business photos
- Social media source

---

## Memory

Each Place supports:

- One personal note
- One optional personal photo
- One emotion

The photo must be uploaded by the user.

Business photos and imported social-media images are never used.

---

## Recommendation

Recommendation helps users rediscover places they have already saved.

Recommendation only changes visual prominence on the map.

It never:

- Changes Collections
- Hides saved Places
- Reorganizes the user's map

Recommendation behavior is defined separately in **RECOMMENDATION_MODEL.md**.

---

## External Navigation

PlacePick never performs navigation.

Users can open the selected place in:

- Apple Maps
- Google Maps

---

# Out of Scope

The MVP intentionally excludes:

- Navigation
- Public search
- Addresses
- Business hours
- Public reviews
- Business photos
- Route planning
- Travel planning
- AI itinerary generation
- Social features
- Multiple pages
- Bottom tab bar

If Apple Maps already does it well, PlacePick does not repeat it.

---

# Product Principles

## Apple Owns Places

Apple Maps owns:

- Place identity
- Search
- Navigation
- Business information

PlacePick owns:

- Personal memories
- Collections
- Notes
- Emotions
- Favorite
- Memory photos

---

## Collections Are Personal

Collections are not objective place categories.

They are the user's own way of organizing their world.

Different users may organize the same place differently.

---

## One Place, One Collection

Each Place belongs to exactly one Collection.

This keeps the map simple, predictable, and easy to browse.

---

## Recommendation Never Reorganizes

Recommendation decides visual prominence.

Collections define organization.

These two systems are independent.

---

# Success Criteria

The MVP succeeds when users naturally think:

> Apple Maps gets me there.

> **PlacePick reminds me why I wanted to go.**

And:

> **This feels like my own map—not the app's map.**