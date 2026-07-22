# PlacePick — DESIGN_LANGUAGE.md

Version: 4.0

This document defines the product language used throughout PlacePick.

Consistent language creates a consistent product.

---

# Philosophy

The language of PlacePick should reinforce one central idea:

> This is your map.

Users are not managing locations.

They are building a personal map of places that matter to them.

Every word should support that feeling.

---

# Core Product Language

## Place

A Place represents a real-world location identified by Apple Maps.

A Place has two layers:

- Apple Maps identity
- Personal relationship

Never refer to a Place as an "item", "record", or "entry".

Always use **Place**.

---

## Collection

Collections organize the user's personal map.

Collections do **not** describe what a place objectively is.

Examples:

- Food
- Coffee
- Family
- Date
- Japan 2027

Different users may organize the same Place differently.

Always use:

> Collection

Never use:

- Category
- Folder
- Tag
- Label

Collections are a core product concept.

---

## Collection Bar

The horizontal control above the map is called the **Collection Bar**.

Example:

```text
All   Food   Coffee   Japan 2027
```

The Collection Bar is not:

- a tab bar
- a navigation bar
- a filter menu

It is simply the user's way of viewing different parts of their own map.

---

## Manage Collections

The interface used to create and organize Collections is called:

> Manage Collections

Supported actions:

- Create
- Rename
- Change Icon
- Reorder
- Delete

Avoid terms like:

- Edit Categories
- Category Settings

---

## Favorite

Favorite represents places the user wants to keep especially visible.

Display:

⭐

Use:

> Favorite

Never use:

- Bookmark
- Pin
- Saved

---

## Emotion

Emotion records how the user felt about a Place.

Supported states:

- 😐
- 😊
- 🤩

No emoji means:

The user has not recorded an emotion.

Avoid:

- Rating
- Score
- Review

Emotion expresses memory rather than evaluation.

---

## Memory Photo

The user's personal photo attached to a Place.

Always use:

> Memory Photo

Avoid:

- Cover Image
- Gallery
- Album

The image exists to trigger memory, not document the business.

---

## Note

Each Place supports one personal note.

Use:

> Note

Avoid:

- Description
- Review
- Comment

The note belongs to the user rather than the place.

---

## Replace Place

Replace Place corrects an incorrect Apple Maps identity.

Use:

> Replace Place

Avoid:

- Edit Place
- Change Address

The user is replacing the identity of the Place, not editing Apple Maps data.

---

## Open in Apple Maps

Use:

> Open in Apple Maps

Avoid:

- Navigate
- Directions

Navigation belongs to Apple Maps.

PlacePick only hands the Place back.

---

## Current Location

Use:

> Current Location

Avoid:

- My Position
- Tracking
- Live Location

---

## Location Control

The native map control that returns the viewport to the user's location.

Avoid custom labels such as:

- Find Me
- Nearby Me
- Track Me

---

# Tone

The interface should feel:

- Personal
- Calm
- Lightweight
- Native
- Confident

Avoid language that feels:

- Technical
- Database-oriented
- Administrative

---

# Writing Style

Prefer:

- Short labels
- Plain English
- Native Apple terminology

Avoid:

- Long explanations
- Marketing language
- Technical implementation terms

---

# Product Vocabulary

| Preferred | Avoid |
|------------|-------|
| Place | Item |
| Collection | Category |
| Collection Bar | Category Filter |
| Manage Collections | Edit Categories |
| Favorite | Bookmark |
| Emotion | Rating |
| Memory Photo | Cover Image |
| Note | Description |
| Replace Place | Edit Place |
| Open in Apple Maps | Navigate |

---

# Final Principle

Every word in PlacePick should reinforce one idea:

> Apple Maps organizes the world.

> PlacePick organizes your map.

The language should always make the product feel personal rather than administrative.