# PlacePick — UI_STRUCTURE

Version: 6.0

---

# Purpose

This document defines how users navigate and interact with PlacePick.

It focuses on interface structure and interaction flow.
Product philosophy, data model, and implementation details are defined in their respective documents.

---

# Information Architecture

PlacePick is built around two equally important ways of browsing memories.

## Browse

- 🗺 **Map** → **Where**
- 📅 **Calendar** → **When**

## Capture

- **New Place**
- **Photo Memory**

```
                Browse

        Map            Calendar
          │                │
          └──────┬─────────┘
                 │
              Memories
                 ▲
          ┌──────┴──────┐
          │             │
     New Place    Photo Memory
```

Everything else in PlacePick is built on these four interactions.

---

# Navigation

The app contains two primary tabs.

## 🗺 Map

Browse memories by place.

## 📅 Calendar

Browse memories by date.

Both ultimately lead to the same Memory.

---

# Map Flow

```
Map
  ↓
Place
  ↓
Memory List
  ↓
Memory Detail
```

The map answers one question:

> **Where did this happen?**

---

# Calendar Flow

```
Calendar
    ↓
Day Detail
    ↓
Memory Feed
    ↓
Memory Detail
```

The calendar answers one question:

> **When did this happen?**

---

# Capture Flow

```
Tap +

↓

What do you want to save?

• New Place
• Photo Memory
```

## New Place

```
Search Apple Maps
        ↓
Create Place
```

## Photo Memory

```
Choose Photos
        ↓
Suggest Groups
        ↓
Suggest Places
        ↓
User Confirms
        ↓
Create Memories
```

The system suggests.

The user confirms.

---

# Core Interaction Principles

- Apple Maps owns geography.
- PlacePick owns personal memories.
- One interaction edits one concept.
- The system suggests.
- The user confirms.
- Memory is the primary experience.
- Place is one way of organizing memories.

---

# UI Principles

- Native first.
- Calm and lightweight.
- Minimize navigation depth.
- Return users to browsing quickly.
- Browse by **Where** or **When**.
- Capture with **New Place** or **Photo Memory**.
