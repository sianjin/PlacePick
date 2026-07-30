# PlacePick — IMPORT_PIPELINE.md

Version: 2.0

Status: Import Architecture Specification

---

# Purpose

This document defines how external content becomes part of the user's Personal Map.

Import exists to reduce the effort of capturing meaningful Places while preserving reliable Place identity.

It does not attempt to understand or reproduce the original content.

Instead, it helps users move from discovering a Place to saving it correctly.

---

# Relationship to Other Documents

This document should be read together with:

- MVP.md
- COLLECTIONS.md
- DATA_MODEL.md
- UI_STRUCTURE.md

Responsibilities are divided as follows.

MVP.md defines:

- Product philosophy
- User experience
- Product scope

DATA_MODEL.md defines:

- Place Identity
- Personal Relationship
- Persistence

UI_STRUCTURE.md defines:

- Capture Flow
- Relationship Editing
- Identity Correction

This document defines:

- How external content enters the product
- How Place identity is resolved
- How import integrates with the standard Capture Flow

Import never creates new product concepts.

It simply provides an alternative entry into the existing Place lifecycle.

---

# Import Model

Import is the bridge between the outside world and the user's Personal Map.

Conceptually:

```text
External Content
        │
        ▼
Candidate
        │
        ▼
Apple Maps Identity
        │
        ▼
Personal Relationship
        │
        ▼
Saved Place
```

Each stage has a different responsibility.

External Content answers:

> What did the user discover?

Candidate answers:

> What Place might this refer to?

Apple Maps Identity answers:

> Which real-world Place is this?

Personal Relationship answers:

> What does this Place mean to the user?

Saved Place answers:

> This Place is now part of the Personal Map.

Import ends once the Place enters the normal Capture Flow.

---

# Import Principles

Import should always remain:

- Fast
- Reliable
- Deterministic
- Local-first
- Explainable

Import should never become:

- Automatic saving
- AI-generated memory
- Social-media archiving
- Business information import
- Personal knowledge extraction

Import exists to accelerate saving.

It does not replace user judgment.

---

# Identity Before Relationship

Import follows the same conceptual model as the rest of PlacePick.

Identity is established first.

Only then can the user record a personal relationship.

Conceptually:

```text
Candidate

↓

Apple Maps Identity

↓

Collection

↓

Favorite

↓

Emotion

↓

Note

↓

Memory Photo
```

Users never attach personal memories to an unresolved Place.

Reliable identity always comes first.

---

# Automation Boundary

Automation may assist throughout the import process.

Examples include:

- extracting likely search text
- recognizing an obvious place name
- suggesting a search query
- suggesting a Collection

Automation never decides:

- which Place is correct
- which Apple Maps result should be used
- what the user's relationship is
- whether a Place should be saved

Automation proposes.

Apple Maps resolves.

The user confirms.

---

# Import Boundary

Import intentionally ends at Identity resolution.

Once the user has selected a valid Apple Maps Place:

The remaining experience is the standard Capture Flow defined in UI_STRUCTURE.md.

Import should never create a separate editing experience.

Every successful import ultimately becomes an ordinary saved Place.

From that point forward, imported Places behave exactly the same as manually created Places.

The product should never distinguish between them.

---

# Part 1 Summary

Import is not a separate feature.

It is an alternative entry into the Place lifecycle.

External content becomes a Candidate.

A Candidate becomes a verified Apple Maps Identity.

The user then records a Personal Relationship.

Once saved, every Place follows the same product model regardless of how it entered the Personal Map.



---

# Candidate Resolution

Candidate Resolution transforms external content into a verified Apple Maps Place.

Conceptually:

```text
External Content
        │
        ▼
Candidate
        │
        ▼
MapKit Resolution
        │
        ▼
Verified Apple Maps Identity
```

Candidate Resolution never creates a Place.

It prepares the user to select one.

---

# Entry Points

Import may begin from many sources.

Examples include:

- Xiaohongshu
- Instagram
- TikTok
- YouTube
- Safari
- Messages
- Notes
- Any app supporting the iOS Share Sheet

Although these sources provide different payloads, they all enter the same Candidate Resolution pipeline.

The source application should not affect the saved Place model.

---

# Share Extension

The Share Extension should remain lightweight.

Its responsibilities are limited to:

1. Receive shared content.
2. Preserve the shared payload.
3. Extract an initial Candidate when possible.
4. Launch the main application.

The Share Extension should not:

- resolve Places
- perform complex searches
- save Places
- synchronize user data
- perform long-running network operations

It exists only to hand off information to the main application.

---

# Candidate Extraction

External content is interpreted only far enough to produce a useful search candidate.

Possible inputs include:

- shared title
- selected text
- shared URL
- shared caption

The output is always:

> A Candidate Search Phrase

Candidates are intentionally imperfect.

They exist only to reduce typing.

---

# Candidate Priority

When multiple possible candidates exist, prefer the first reliable source:

1. Explicit shared title
2. User-selected text
3. Shared caption
4. Human-readable URL title
5. URL fragments
6. Empty search

An empty search field is always preferable to inventing a Place.

---

# Candidate Cleanup

Before searching MapKit:

- trim whitespace
- remove obvious share boilerplate
- collapse repeated spaces
- remove tracking URL parameters
- preserve branch information
- preserve city and neighborhood hints
- preserve non-English Place names

Candidate cleanup should remain conservative.

Import should improve search quality without changing the user's intended meaning.

---

# URL Resolution

URLs should assist Candidate Resolution rather than bypass it.

## Apple Maps URLs

Apple Maps links may already contain reliable Place information.

When available:

- extract MapKit identifiers
- extract coordinates
- extract Place names

Even then:

The user still confirms the final Place.

---

## Google Maps URLs

Google Maps links may provide:

- Place name
- Coordinates
- Query text

These values become Candidate information for Apple Maps Search.

The saved Place always uses Apple Maps identity.

---

## Yelp URLs

Yelp links may provide a Place name via the yelp.com/biz/&lt;slug&gt; URL slug.

Yelp blocks automated page fetches, so only the URL itself is used — never page content.

These values become Candidate information for Apple Maps Search.

The saved Place always uses Apple Maps identity.

---

## Social Media URLs

Social-media links should use only information already provided through the share payload.

The product should not:

- scrape web pages
- require authentication
- depend on private APIs

If useful Candidate information cannot be extracted, the user simply begins with an empty search.

---

# Optional AI Enhancement

The MVP does not require AI.

Future versions may use lightweight AI to improve Candidate quality.

Possible AI output:

- Place name
- City
- Neighborhood
- Category hint

AI remains advisory.

It never:

- creates Places
- chooses branches
- invents addresses
- bypasses user confirmation

Candidate Resolution must remain fully functional without AI.

---

# Apple Maps Resolution

Candidate Resolution ends with Apple Maps.

The main application performs Place resolution using MapKit.

The search experience should feel similar to Apple Maps.

Users may:

- review suggestions
- refine the search
- select the correct Place

Only a verified Apple Maps result may become a Place.

---

# Duplicate Resolution

After the user selects an Apple Maps result:

The app checks for an existing saved Place.

Useful signals include:

- Apple Maps identifier
- nearby coordinates
- normalized Place name

If no duplicate exists:

Continue to the standard Capture Flow.

If a duplicate exists:

Open the existing Place instead.

The MVP intentionally avoids automatic merging or duplicate creation.

---

# Candidate Resolution Summary

Candidate Resolution converts uncertain external information into reliable Place identity.

Import never assumes the correct Place.

Automation proposes a Candidate.

Apple Maps resolves identity.

The user confirms the final result.

Only then does the Place enter the normal Capture Flow.

---

# Relationship Capture

Once a Place has been successfully resolved through Apple Maps, the import pipeline enters the standard Capture Flow.

Conceptually:

```text
Verified Apple Maps Identity
        │
        ▼
Personal Relationship
        │
        ▼
Saved Place
```

Import no longer owns the experience.

From this point forward, the interaction is identical to manually adding a Place.

---

# Standard Capture Flow

After Identity has been resolved, the user records only the personal layer.

Conceptually:

```text
Verified Place

↓

Collection

↓

Favorite

↓

Emotion

↓

Note

↓

Memory Photo

↓

Save
```

The import pipeline intentionally reuses the existing Capture Flow.

It should never introduce a second editing experience.

---

# Collection Selection

Every imported Place belongs to exactly one Collection.

Collection selection is required before saving.

The Collection picker should:

- display Collections in user-defined order
- support creating a new Collection
- preserve the current Capture Flow

Import should never assign a Collection automatically.

Suggestions may be offered, but the user remains the final authority.

---

# Optional Relationship Fields

Only Collection is required.

The following fields remain optional:

- Favorite
- Emotion
- Note
- Memory Photo

Users should be able to save a Place immediately without filling every field.

The capture experience should remain lightweight.

---

# Duplicate Handling

Before creating the Place, the app checks for an existing Apple Maps Identity.

If the Place already exists:

Open the existing Place.

Do not:

- create another copy
- merge automatically
- overwrite Personal Relationships

The imported Candidate has already completed its purpose.

The user's existing Place remains authoritative.

---

# Save Behavior

Saving an imported Place follows exactly the same rules as manual Capture.

A successful save creates:

- Place Identity
- Personal Relationship
- Persistence Metadata

The Place immediately becomes part of the user's Personal Map.

Recommendation and Presentation begin only after saving.

Import plays no further role.

---

# Pending Import Cleanup

PendingImport exists only to bridge the Share Extension and the main application.

It is temporary transport data.

After a successful save:

- PendingImport is deleted.
- Temporary extraction data is discarded.
- The Personal Map becomes the only source of truth.

If the user cancels the Capture Flow:

PendingImport may be retained temporarily so the import can be resumed.

Expired PendingImports should be removed automatically after a short period.

PendingImport must never appear as user-visible content.

---

# Failure and Recovery

Import should always fail gracefully.

## Weak Candidate

If extraction produces poor search text:

Allow the user to edit the search manually.

---

## No Search Results

If MapKit cannot resolve the Candidate:

Allow the user to revise the search.

Do not create an unresolved Place.

---

## Multiple Branches

If several similar Places exist:

Show the Apple Maps results.

The user selects the correct identity.

---

## User Cancels

If the user leaves the Capture Flow before saving:

No Place is created.

The Personal Map remains unchanged.

---

## Offline

The existing Personal Map remains fully usable.

Creating a new Place may require network access for Apple Maps resolution.

Import should never create a placeholder Place without verified identity.

---

# Relationship Capture Summary

Import ends when a verified Apple Maps Identity enters the standard Capture Flow.

From that point forward:

The user records a Personal Relationship.

The Place is saved.

Recommendation begins.

Presentation follows.

Every imported Place becomes indistinguishable from every manually created Place.

The product should remember the Place—not how it entered the Personal Map.

---

# System Boundaries

The previous sections define how external content becomes a saved Place.

This section defines the boundaries that keep the import system reliable, predictable, and consistent with the rest of PlacePick.

Import should accelerate capture without changing the product model.

---

# Privacy

Import should retain only the information necessary to complete the current import.

Temporary import data should never become part of the user's permanent memory unless the user explicitly saves a Place.

The system should:

- minimize retained shared content
- avoid storing unnecessary source data
- delete temporary import data after successful completion
- expire abandoned imports automatically

The permanent Personal Map should contain:

- verified Place identity
- Personal Relationship
- Persistence Metadata

It should not contain copies of social-media posts.

---

# Performance

Import should feel immediate.

The Share Extension should:

- capture the shared payload quickly
- avoid unnecessary parsing
- avoid blocking network requests
- hand off to the main application as soon as possible

Candidate extraction should reduce typing rather than delay capture.

The standard Capture Flow should begin without noticeable interruption.

---

# Reliability

Import should always produce one of two outcomes.

Either:

```text
Verified Place

↓

Capture Flow
```

or:

```text
No Place Created
```

The system should never produce:

- partially created Places
- unresolved Places
- placeholder identities
- incomplete Personal Relationships

Import either succeeds completely or leaves the Personal Map unchanged.

---

# Failure Behavior

Weak imports should never prevent users from saving Places manually.

Examples include:

Weak Candidate

↓

Allow manual search.

No Apple Maps results

↓

Allow search refinement.

User cancels

↓

Discard the unfinished import.

Offline

↓

Keep the existing Personal Map available.

Wait until Apple Maps resolution becomes possible.

Import failures should degrade gracefully.

The user should always understand how to continue.

---

# Telemetry

The MVP does not require detailed import analytics.

If analytics are introduced later, they should measure only coarse workflow events.

Examples include:

- Import Started
- Candidate Generated
- Apple Maps Place Selected
- Place Saved
- Import Cancelled

The product should never log:

- complete shared posts
- personal notes
- imported text beyond temporary processing
- memory photos
- sensitive source content

Telemetry exists to improve the product rather than reconstruct user content.

---

# Implementation Boundaries

Future implementations should preserve the following architectural rules.

Import must never:

- save a Place without verified Apple Maps identity
- bypass user confirmation
- create unresolved Places
- create duplicate Personal Relationships automatically
- merge Places automatically
- scrape authenticated social-media content
- depend on third-party AI services
- introduce a permanent source field without an explicit product decision

Import should remain compatible with the existing Place lifecycle rather than creating a parallel workflow.

---

# Success Criteria

The import pipeline succeeds when:

- sharing is faster than manual entry
- Candidate extraction reduces typing
- Apple Maps reliably resolves identity
- users can easily correct imperfect Candidates
- imported Places become ordinary saved Places
- failed imports never block manual capture

The quality of the import system is measured by how naturally it disappears into the normal Capture Flow.

---

# Final Principles

> Import bridges the outside world and the Personal Map.

> Automation suggests. Apple Maps resolves. The user confirms.

> Identity must be verified before a Personal Relationship can exist.

> Every imported Place becomes an ordinary Place.

> The product remembers Places, not their sources.

> Import should remove friction—not user judgment.