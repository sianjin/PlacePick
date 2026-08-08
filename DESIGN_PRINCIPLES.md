# MomentMap — DESIGN_PRINCIPLES.md

Version: 1.0

Status: Product Philosophy

---

# Purpose

This document records the enduring design principles behind MomentMap.

Unlike implementation documents, these principles are intended to remain stable as the product evolves.

Every feature, workflow, and future decision should be evaluated against these principles.

When a design choice conflicts with a principle, the principle should take precedence unless the philosophy of the product itself is intentionally changing.

---

# Relationship to Other Documents

This document explains **why** MomentMap is designed the way it is.

Other documents describe the product from different perspectives.

MVP.md defines:

- product scope
- user experience
- product vision

DATA_MODEL.md defines:

- what a Place is

IMPORT_PIPELINE.md defines:

- how the outside world becomes a Place

PLACE_CREATION.md defines:

- how a verified Place becomes part of the Personal Map

RECOMMENDATION_MODEL.md defines:

- how Personal Relationships become visual attention

UI_STRUCTURE.md defines:

- how users interact with the system

This document explains the principles that keep all of those documents consistent.

---

# Principle 1 — Apple Maps Owns the World

MomentMap does not attempt to recreate the world's geographic information.

Apple Maps already provides:

- Place identity
- Search
- Navigation
- Coordinates
- Business information

Duplicating these responsibilities would increase complexity without improving the user's experience.

Instead, MomentMap accepts Apple Maps as the authoritative representation of the objective world.

MomentMap builds on top of that foundation rather than competing with it.

---

# Principle 2 — MomentMap Owns Personal Meaning

Apple Maps describes Places.

MomentMap describes the user's relationship with Places.

MomentMap stores only information that cannot be objectively determined.

Examples include:

- Collection
- Favorite
- Emotion
- Personal Note
- Memory Photo

This distinction keeps the product intentionally focused.

The goal is not to build a better map.

The goal is to build a personal map.

---

# Principle 3 — Ask Only What the World Cannot Answer

Whenever the objective world already provides an answer, MomentMap should not ask the user to answer it again.

Examples include:

- Place name
- Coordinates
- Address
- Business information

Instead, user input should focus only on personal meaning.

Every additional question increases friction.

Every unnecessary question weakens the simplicity of the product.

The ideal creation flow asks only for information that Apple Maps cannot possibly know.

---

# Part 1 Summary

MomentMap is built on a clear division of responsibility.

Apple Maps owns the objective world.

Users own their personal experiences.

MomentMap exists to connect those two layers without confusing them.

Every future feature should reinforce this boundary rather than blur it.

---

# Product Structure

The structure of MomentMap follows directly from its product philosophy.

The application is organized around a small number of independent concepts.

Each concept has a single responsibility.

Keeping these responsibilities separate allows the product to remain simple while continuing to evolve.

---

# Principle 4 — One Map, One Workspace

The map is the primary workspace of MomentMap.

Users should feel that they are interacting with one continuous Personal Map rather than navigating between independent screens.

Most interactions begin on the map.

Most interactions return to the map.

Additional views exist only to support the map rather than replace it.

The map is not one feature among many.

It is the product itself.

---

# Principle 5 — Collections Organize Personal Thinking

Collections organize how users think about Places.

They do not describe Places themselves.

The same Place may reasonably belong to very different Collections depending on the user's own perspective.

For example:

- Weekend Coffee
- Date Ideas
- Japan Trip
- Favorite Bakeries

None of these describe the Place objectively.

They describe why the user saved it.

Collections therefore organize personal memories rather than geographic information.

---

# Principle 6 — Identity and Relationship Must Remain Independent

A Place contains two fundamentally different layers.

Identity answers:

> Which Place is this?

Relationship answers:

> What does this Place mean to me?

These layers evolve independently.

Correcting a Place's identity should not erase personal memories.

Likewise, changes to personal memories should never modify the objective identity of the Place.

Maintaining this separation keeps the data model predictable and resilient.

---

# Principle 7 — Organization and Attention Are Different Problems

Collections and Recommendation solve different problems.

Collections answer:

> How is my Personal Map organized?

Recommendation answers:

> Which Places deserve my attention right now?

Neither system should modify the other.

Changing Recommendation should never reorganize Collections.

Changing Collections should never directly affect Recommendation.

Keeping these concepts independent makes each system easier to understand and evolve.

---

# Part 2 Summary

MomentMap is built from a small number of independent concepts.

The map provides one continuous workspace.

Collections organize personal thinking.

Identity defines what a Place is.

Relationship defines what it means.

Recommendation determines attention without changing organization.

Each concept has one responsibility, and every responsibility belongs to exactly one concept.

---

# Simplicity

MomentMap values clarity over capability.

Every new feature increases the cognitive cost of using the product.

Features are added only when they strengthen the core experience rather than expanding the product's scope.

Simplicity is treated as a product capability rather than the absence of features.

---

# Principle 8 — Every Place Has One Home

Each Place belongs to exactly one Collection.

Multiple Collections introduce additional decisions during creation, increase organizational complexity, and make browsing less predictable.

A single Collection encourages users to decide why a Place was saved.

If a Place later belongs somewhere else, changing its Collection should be simple.

Organization should remain intentional rather than exhaustive.

---

# Principle 9 — Search Exists Only When Needed

Searching is part of creation, not exploration.

Users search only when they already know what they are looking for:

- creating a Place
- replacing a Place

Once a Place has been saved, exploration should happen naturally through the map itself.

Keeping search contextual encourages users to rediscover Places spatially rather than treating the application like a searchable database.

---

# Principle 10 — Every Place Exists Only Once

A real-world Place should have one representation in the Personal Map.

Allowing multiple copies of the same Place creates ambiguity.

Questions such as:

- Which copy should be updated?
- Which copy should Recommendation consider?
- Which memories belong to which copy?

introduce unnecessary complexity.

Instead of duplicating Places, users enrich a single Place over time.

The Personal Map should accumulate meaning rather than copies.

---

# Principle 11 — The Product Should Stay Local

MomentMap is intentionally designed around the user's own Places.

The product does not attempt to become:

- a social network
- a review platform
- a recommendation community
- a collaborative map

Its purpose is to help users remember and revisit Places that matter to them.

Personal value comes before network effects.

---

# Principle 12 — Features Must Strengthen the Core Loop

Every feature should reinforce the same product loop.

```text
Discover

↓

Save

↓

Remember

↓

Rediscover
```

Features that do not strengthen this loop should be questioned carefully.

Adding capabilities is easy.

Maintaining a coherent product is much harder.

---

# Part 3 Summary

Simplicity is not achieved by removing features.

It is achieved by protecting the core experience.

Every Place has one home.

Every Place exists only once.

Search appears only when it serves creation.

Every feature should strengthen the same Personal Map rather than expanding the product into something else.

---

# Evolution

MomentMap is expected to grow over time.

New features, workflows, and technologies will inevitably be introduced.

However, the product should evolve by reinforcing its core principles rather than replacing them.

Evolution should increase capability without increasing conceptual complexity.

---

# Principle 13 — Preserve Concepts Before Features

New features should build upon existing concepts whenever possible.

Before introducing a new concept, ask:

- Can this be represented using the current model?
- Does it strengthen an existing concept?
- Does it reduce or increase cognitive load?

A feature that requires a new concept should have a compelling product reason to exist.

The product should gain capabilities while keeping its conceptual model small.

---

# Principle 14 — Preserve User Meaning

The user's relationship with a Place is more valuable than any derived system behavior.

Recommendation may change.

Presentation may change.

Apple Maps data may change.

The user's personal meaning should remain stable.

Whenever objective information changes, the product should preserve the user's memories whenever reasonably possible.

The Personal Map should evolve without forcing users to rebuild their history.

---

# Principle 15 — Every Feature Should Have One Responsibility

A feature should solve one problem well.

Avoid features that simultaneously:

- organize
- recommend
- search
- categorize
- annotate

Mixing responsibilities makes the product harder to understand.

Features should compose naturally rather than overlap.

Simple systems emerge from clear boundaries.

---

# Principle 16 — The Product Should Feel Smaller Over Time

As MomentMap grows, it should continue to feel lightweight.

New capabilities should increase usefulness without making the product feel more complicated.

Whenever possible:

- reuse existing workflows
- reuse existing concepts
- reuse existing interactions

Users should feel that they are learning one coherent product rather than accumulating independent features.

Growth should increase depth rather than breadth.

---

# Final Principles

> Apple Maps owns the world.

> Users own personal meaning.

> Simplicity is a feature.

> Every concept has one responsibility.

> Preserve user meaning before adding new capabilities.

> The product should grow by becoming deeper—not larger.