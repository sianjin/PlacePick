# MomentMap — DESIGN_LANGUAGE.md

Version: 5.0

Status: Product Language Guide

---

# Purpose

This document defines the language used throughout MomentMap.

Language is part of the product design.

The words users read shape how they understand the product.

Consistent language creates a consistent mental model.

Every product concept should therefore have:

- one stable name
- one clear meaning
- one consistent usage

This document defines those rules.

---

# Relationship to Other Documents

This document defines **how MomentMap communicates**.

Other documents describe the product from different perspectives.

MVP.md defines:

- product vision
- product scope
- user experience

DESIGN_PRINCIPLES.md defines:

- why the product is designed this way

DATA_MODEL.md defines:

- what a Place is

UI_STRUCTURE.md defines:

- how users interact with the product

This document defines:

- product terminology
- naming conventions
- interface language
- writing style

Its purpose is to ensure that every screen speaks with one consistent voice.

---

# Language Philosophy

The language of MomentMap should make the product feel like a personal map rather than a place database.

Users are not managing records.

They are building a collection of meaningful Places.

The language should reinforce this feeling in every interaction.

Words do more than describe features.

They define how users understand the product.

Whenever possible, product language should express:

- personal ownership
- clarity
- calmness
- confidence
- simplicity

The interface should feel natural rather than technical.

---

# Principle 1 — Use User Concepts

Prefer concepts users naturally understand over implementation terminology.

For example:

Use:

- Place
- Collection
- Favorite
- Note

Avoid:

- Record
- Category
- Entry
- Metadata

Users think in places.

The product should speak the same language.

---

# Principle 2 — Use Personal Language

MomentMap is about personal memory.

Its language should therefore feel personal rather than administrative.

Prefer words that describe the user's relationship with Places.

Examples include:

- Favorite
- Emotion
- Memory Photo

Avoid language commonly associated with databases, review platforms, or file managers.

Examples include:

- Rating
- Bookmark
- Folder
- Cover Image
- Description

The interface should sound like a personal companion rather than a management tool.

---

# Principle 3 — Use Stable Concepts

Each product concept should have one official name.

Once a concept has been established, it should be used consistently throughout:

- the interface
- documentation
- onboarding
- future features

Different words should not be used interchangeably for the same concept.

Consistency reduces cognitive load and makes the product easier to learn.

---

# Tone

The overall tone of MomentMap should feel:

- Personal
- Calm
- Lightweight
- Native
- Confident

The interface should never feel:

- Technical
- Administrative
- Promotional
- Overly conversational

Users should feel that the product quietly supports their own memories rather than demanding attention.

---

# Writing Style

Prefer:

- Short labels
- Plain English
- Native Apple terminology
- Direct wording

Avoid:

- Long explanations
- Marketing language
- Technical implementation terms
- Internal engineering vocabulary

When in doubt:

Choose the simplest wording that accurately communicates the concept.

---

# Part 1 Summary

Language is part of the product architecture.

Every concept should have one stable name, one clear meaning, and one consistent usage.

The language of MomentMap should always reinforce the same idea:

> This is your personal map—not a database of places.

---

# Core Product Vocabulary

The following terms define the core concepts of MomentMap.

These concepts appear consistently throughout the product, documentation, and future features.

Each concept has one official meaning and should not be replaced with alternative terminology.

---

# Place

A Place represents one real-world location identified by Apple Maps.

Every Place consists of two conceptual layers:

- Place Identity
- Personal Relationship

A Place is the fundamental object of the Personal Map.

Always use:

> Place

Never use:

- Item
- Record
- Entry
- Location

"Location" refers to geography.

"Place" refers to something personally meaningful.

---

# Collection

A Collection organizes Places according to the user's own thinking.

Collections do not describe what a Place objectively is.

Examples include:

- Coffee
- Date Ideas
- Weekend Trips
- Japan 2027

Different users may organize the same Place differently.

Always use:

> Collection

Never use:

- Category
- Folder
- Tag
- Label

Collections organize personal meaning rather than objective information.

---

# Favorite

Favorite marks Places that deserve additional attention.

It represents personal importance rather than quality.

Display:

⭐

Always use:

> Favorite

Never use:

- Bookmark
- Saved
- Pin

Favorite is part of the Personal Relationship.

It does not change the Place itself.

---

# Emotion

Emotion records how the user feels about a Place.

Supported states:

- 😐
- 😊
- 🤩

No emotion means:

The user has not recorded a personal feeling.

Emotion is not:

- Rating
- Score
- Review

Emotion captures memory rather than evaluation.

---

# Note

A Note records personal thoughts about a Place.

Notes belong entirely to the user.

They describe:

- memories
- reminders
- experiences

They do not describe the Place objectively.

Always use:

> Note

Never use:

- Description
- Review
- Comment

---

# Memory Photo

A Memory Photo is a personal photograph attached to a Place.

Its purpose is to help the user remember the Place.

It is not intended to document the business itself.

Always use:

> Memory Photo

Never use:

- Cover Image
- Gallery
- Album

The photo represents a memory rather than an illustration.

---

# Personal Map

The Personal Map represents the user's own collection of meaningful Places.

It is the central concept of MomentMap.

The Personal Map is not:

- a review platform
- a travel guide
- a business directory

It is the user's own representation of the world.

Whenever possible, interface language should reinforce this concept.

---

# Part 2 Summary

The vocabulary of MomentMap reflects its conceptual model.

Places represent the real world.

Collections organize personal thinking.

Favorites, Emotions, Notes, and Memory Photos express personal meaning.

Together, these concepts form the user's Personal Map.

---

# Interaction Language

Interaction language describes how MomentMap communicates with users during everyday use.

Unlike the Core Product Vocabulary, these terms describe actions and interface elements rather than product concepts.

Interaction language should feel:

- clear
- direct
- native
- predictable

Users should immediately understand what an action does without interpreting technical terminology.

---

# Collection Bar

The horizontal control above the map is called the **Collection Bar**.

Example:

```text
All   Coffee   Weekend Trips   Japan 2027
```

The Collection Bar allows users to view different parts of their Personal Map.

It is not:

- a tab bar
- a navigation bar
- a filter menu

Always use:

> Collection Bar

---

# Manage Collections

The interface used to organize Collections is called:

> Manage Collections

Supported actions include:

- Create
- Rename
- Change Icon
- Reorder
- Delete

Avoid interface labels such as:

- Edit Categories
- Category Settings
- Manage Folders

Collections are user-created concepts, not system-defined categories.

---

# Replace Place

Replace Place corrects an incorrect Apple Maps identity.

It does not edit the Place itself.

Always use:

> Replace Place

Avoid:

- Edit Place
- Change Address
- Update Location

The user is replacing the objective identity while preserving personal meaning.

---

# Open in Apple Maps / Google Maps

When users need navigation or additional place information, MomentMap hands the Place back
to a maps provider — Apple Maps or Google Maps.

The interface presents this as a single "Open in" confirmation, with the provider name as
the choice:

```text
Open in

Apple Maps
Google Maps
```

Always use:

> Open in
> Apple Maps
> Google Maps

Avoid:

- Navigate
- Get Directions
- Open Maps

The provider name alone is sufficient once "Open in" is already the dialog's title;
repeating "Open in" on every button would be redundant. The action still emphasizes that
navigation belongs to the maps provider rather than MomentMap.

---

# Current Location

The user's current position on the map is called:

> Current Location

Avoid:

- My Position
- Live Location
- Tracking

Current Location provides spatial context.

It is not part of the user's Personal Map.

---

# Location Button

The native MapKit control used to return the map to the user's current position should remain visually and behaviorally consistent with Apple's platform conventions.

Avoid custom labels such as:

- Find Me
- Locate Me
- Track Me
- Nearby Me

Whenever possible, rely on the native control without additional wording.

---

# Empty States

Empty-state language should encourage exploration rather than highlight missing data.

Prefer:

- Save your first Place.
- Start building your Personal Map.
- No Places in this Collection yet.

Avoid:

- Database is empty.
- No records found.
- Nothing available.

The interface should always invite users to continue building their map.

---

# Confirmation Language

Confirmation messages should acknowledge meaningful user actions without drawing unnecessary attention.

Prefer concise confirmations such as:

- Place Saved
- Collection Created
- Place Updated

Avoid overly expressive or promotional language such as:

- Amazing!
- Success!
- Congratulations!

The product should feel quietly supportive rather than celebratory.

---

# Part 3 Summary

Interaction language should feel natural, concise, and consistent with the rest of the product.

Core concepts define what the product is.

Interaction language defines how users communicate with it.

Every label, button, and message should reinforce the feeling that users are building and exploring their own Personal Map.


---

# Consistency

The language of MomentMap should remain consistent as the product evolves.

New features should extend the existing language rather than introducing new terminology unnecessarily.

Consistency is achieved by protecting concepts, not by expanding vocabulary.

---

# Principle 4 — One Concept, One Name

Every product concept should have one official name.

Once established, that name should be used consistently throughout:

- the interface
- onboarding
- documentation
- future features

Do not introduce alternative names for the same concept.

For example:

Always use:

- Place
- Collection
- Favorite
- Emotion
- Note

Never alternate between:

- Place / Item
- Collection / Category
- Favorite / Bookmark
- Emotion / Rating

Stable terminology creates a stable mental model.

---

# Principle 5 — Reuse Existing Concepts

Before introducing a new term, ask:

- Can an existing concept describe this feature?
- Does this feature truly represent something new?
- Will a new word reduce or increase cognitive load?

Prefer extending existing concepts over inventing new ones.

For example:

Future features should naturally build upon concepts such as:

- Place
- Collection
- Favorite
- Personal Map

rather than introducing parallel terminology.

The product should grow by deepening its existing vocabulary rather than expanding it.

---

# Principle 6 — Prefer Product Meaning Over Implementation

Interface language should describe what users experience rather than how the system works.

Prefer:

- Replace Place
- Open in Apple Maps / Google Maps
- Memory Photo

Avoid implementation-oriented language such as:

- Update Identifier
- Launch Maps
- Image Attachment

Users should never need to understand the internal architecture of the product.

The language should always describe intent rather than implementation.

---

# Principle 7 — Prefer Human Language Over System Language

Whenever possible, use language that feels natural to people rather than to software.

Prefer:

- Saved Place
- Current Location
- Personal Map

Avoid:

- Record
- Object
- Entity
- Database
- Metadata

The product should speak as though it is helping users remember meaningful Places—not managing information.

---

# Product Vocabulary Reference

| Preferred | Avoid |
|------------|-------|
| Place | Item, Record, Entry |
| Collection | Category, Folder, Tag |
| Favorite | Bookmark, Pin, Saved |
| Emotion | Rating, Score, Review |
| Note | Description, Comment |
| Memory Photo | Cover Image, Gallery |
| Replace Place | Edit Place, Change Address |
| Open in Apple Maps / Google Maps | Navigate, Get Directions |
| Current Location | My Position, Live Location |

This table serves as the canonical vocabulary reference for the product.

Future terminology should remain compatible with these conventions.

---

# Final Principle

Every word in MomentMap should reinforce the same mental model.

Apple Maps describes the world.

MomentMap describes the user's relationship with the world.

The language should therefore feel:

- personal rather than administrative
- stable rather than fashionable
- simple rather than technical
- meaningful rather than descriptive

As the product evolves, its vocabulary should become more consistent—not more extensive.