
# MomentMap MVP

## Vision
**Remember life through places.**

MomentMap is a personal memory app organized around real-world places. The product revolves around Places, Memories, and Photos.

---

# Core Philosophy

The app answers two questions:

- **Where?** → Map
- **When?** → Calendar

The system determines:
- Place
- Time

The user determines:
- Emotion
- Meaning
- Notes

---

# Core Model

```
Collection
    ↓
Place
    ↓
Memory (Visit)
    ↓
Photos
```

Rules:

- Place can exist without Memories.
- Memory belongs to exactly one Place.
- Memory requires at least one Photo with reliable capture-time metadata.
- Favorite belongs to Place.
- Emotion belongs to Memory.

---

# Capture

## Place-first

```
Search Place
↓
Open Place
↓
Add Memory
↓
Choose Photos
↓
Emotion / Note
```

## Photo-first

```
Choose Photos
↓
Read metadata
↓
Suggest groups
↓
Suggest nearby Places
↓
User confirms
↓
Create Memories
```

The system never creates Memories automatically.

---

# Browse

## Map

Browse memories spatially.

## Calendar

Browse memories temporally.

Selecting a day opens **Day Detail**.

## Day Detail

A chronological feed of Memories:

```
9:12  Blue Bottle
📷📷📷
😊

11:36 Golden Gate Bridge
📷📷

1:48 Ferry Building
📷📷📷

7:32 Nopa
📷📷
🤩
```

Each card represents one Memory.

## Place Detail

Shows:

- Place information
- Favorite
- Collections
- Memory history

---

# MVP Includes

- Apple Maps search
- Map
- Calendar
- Day Detail
- Place Detail
- Add Memory
- Multi-photo Memories
- Emotion
- Notes
- Collections
- Favorites
- Photo-first import
- Suggested photo grouping
- Suggested nearby Places
- User-confirmed Place resolution
- Sharing (Place and Collection, via Share Extension / share sheet)

---

# Not in MVP

- Trips
- Travel Logs
- AI photo recognition
- Background photo scan
- Story generation
- Year Review
- Social features

---

# Design Principles

- Memory is photo-anchored.
- Favorite is long-term.
- Emotion belongs to one Memory.
- Place can exist without Memories.
- Ask only what the world cannot answer.

---

# Future

Future features such as Travel Logs, Year Review, AI memories and Story Sharing will all build on the same Place + Memory model without changing the underlying data model.
