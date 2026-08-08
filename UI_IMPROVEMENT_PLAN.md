# PlacePick — UI Improvement Plan

Status: Living document
Version: 2.0

---

# Goal

The goal is not to make PlacePick look more beautiful.

The goal is to make every interaction reinforce one idea:

> Every place deserves a memory.

Editor’s Choice apps are recognizable because every screen expresses the same philosophy.
Visual polish is important, but product clarity, emotional design, and memorable interactions come first.

---

# Design Principles

## 1. Memory First

Maps are infrastructure.

Memories are the product.

Every screen should move the user closer to their memories rather than exposing map functionality.

Whenever a design decision conflicts with traditional map behavior, choose the design that better highlights memories.

---

## 2. One Place, Many Stories

A place is never a single pin.

A place is a collection of moments across different years, people, seasons, and emotions.

The UI should constantly remind users that places become more valuable over time.

---

## 3. One Day, Many Places

Time is equally important.

Calendar is not a secondary feature.

Browsing by day should feel like opening a travel journal rather than viewing a timeline of records.

---

## 4. Feelings Over Ratings

PlacePick never asks users to score places.

Instead, it asks:

"How did this place make you feel?"

Emotion should influence the atmosphere of the UI instead of behaving like metadata.

---

# Priority 1 — Build Signature Experiences

These are the moments users remember after closing the app.

Without them, PlacePick is simply another well-designed map app.

---

## 1. Place Expansion

Current

Map Pin

↓

Bottom Sheet

Desired

Map Pin

↓

Pin expands

↓

Memory Card

↓

Photo

↓

Detail

The memory should feel like it grows naturally from the map.

Potential implementation:

- matchedGeometryEffect
- spring animation
- subtle scale transition

---

## 2. Calendar Expansion

Current

Tap day

↓

New page

Desired

Calendar

↓

Selected day expands

↓

Timeline unfolds

↓

Photos appear naturally

Browsing a day should feel like opening a travel diary.

---

## 3. Emotion Interaction

Current

Tap emoji

↓

Selection changes

Desired

Tap emoji

↓

soft haptic

↓

spring animation

↓

emoji enlarges

↓

memory card slightly changes tint

↓

selection feels alive

The emotion becomes part of the experience instead of a form field.

---

# Priority 2 — Emotional Design System

Introduce a lightweight visual language shared across the app.

---

## Color

Rather than one accent color, use subtle emotional accents.

😐 Neutral

Soft gray

😊 Loved

Warm amber

🤩 Unforgettable

Golden highlight

These colors should never dominate the interface.

They simply make memories feel different.

---

## Motion

Animations should feel calm.

Avoid playful animations.

Prefer

- spring
- fade
- scale
- material transitions

Everything should feel effortless.

---

## Typography

Large titles should celebrate memories.

Metadata should stay quiet.

Photos should remain the visual focus.

---

# Priority 3 — Visual Consistency

Create a minimal design system.

Instead of repeating values throughout the project, define reusable tokens.

Examples:

Theme.swift

- Colors
- Radius
- Shadows
- Animation
- Spacing

Goals:

- consistent corner radius
- consistent card elevation
- consistent spacing
- consistent animation timing

---

# Priority 4 — Better Memory Cards

Memory cards appear throughout the app.

They should become the signature component.

Improve:

• layered backgrounds

• softer shadows

• better photo treatment

• consistent spacing

• larger imagery

• stronger hierarchy

A screenshot should instantly communicate:

"This is a memory."

---

# Priority 5 — Better Place Detail

Current

Information is presented clearly.

Future

The page should communicate history.

Possible improvements:

• memory count

• first visited

• latest visit

• visual timeline

• larger memory thumbnails

The place becomes a personal archive instead of a location.

---

# Priority 6 — App Store Storytelling

The App Store should explain the philosophy rather than the feature list.

Current messaging is already strong.

Future screenshots should emphasize long-term value.

Examples:

Browse by place

↓

One place, many memories

↓

One day, every memory

↓

A feeling, not a score

↓

Your life, remembered.

The final screenshot should answer:

"Why will I still use this app five years from now?"

---

# Future Platform Features

Only pursue features that strengthen the core philosophy.

Good examples:

• Widgets

Recent memories

This day in history

Nearby favorites

---

• Interactive Widgets

Quick Add Memory

---

• Live Activities

Only if they help capture memories.

Never build Live Activities for novelty.

---

• Vision Pro

Revisit trips spatially.

Only pursue when the experience feels genuinely meaningful.

---

# Out of Scope

Do not add features simply because other apps have them.

Examples:

✗ Social feed

✗ Public reviews

✗ Like counts

✗ Achievement systems

✗ Numeric ratings

✗ AI-generated travel plans

Every feature should answer one question:

"Does this make memories more meaningful?"

If not, it doesn't belong in PlacePick.

---

# North Star

Every screen should leave the user's memories feeling more valuable than when they arrived.

If a new feature improves functionality but weakens that feeling, it should be reconsidered.

The best version of PlacePick is not the map app with the most features.

It is the map app that makes people smile when they revisit their own lives.