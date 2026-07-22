# PlacePick — IMPORT_PIPELINE.md

Version: 1.0  
Scope: MVP

---

# Purpose

PlacePick should make saving a place from social media faster than manually copying information into a map app.

The MVP import flow is:

```text
Share text or link
        ↓
Extract an obvious title or place phrase
        ↓
Pre-fill Apple Maps Search
        ↓
User selects a reliable Apple Maps result
        ↓
Save as Place
```

The goal is not to understand the entire social-media post.

The goal is to reduce typing while preserving reliable place identity.

---

# Core Principle

> **Automation may suggest a place. Only Apple Maps resolution and user confirmation may create a Place.**

Shared content is untrusted input.

A social post, caption, title, or URL may contain:

- The wrong branch
- Multiple businesses
- A neighborhood rather than a place
- A city name
- A nearby landmark
- Promotional language
- No usable location at all

PlacePick must never silently convert extracted text into a saved Place.

---

# MVP Boundary

## MVP Includes

- iOS Share Extension
- Receiving shared text and URLs
- Extracting an obvious title or search phrase
- Pre-filling Add Place search
- Apple MapKit place search
- User confirmation
- Manual correction and fallback
- Temporary pending-import storage

## MVP Does Not Include

- Advanced AI interpretation
- Video understanding
- OCR of arbitrary screenshots
- Full social-post summarization
- Automatic multi-place extraction
- Automatic saving without confirmation
- Importing social-media photos
- Preserving the source platform as permanent Place data
- Scraping private or authenticated social pages

AI may be added later as an enhancement, but it is not required for a useful MVP.

---

# Product Flow

## Entry Point

The user shares content from another app to PlacePick.

Possible source apps include:

- Xiaohongshu
- Instagram
- TikTok
- YouTube
- Safari
- Messages
- Notes
- Other apps supporting the iOS share sheet

The Share Extension should accept, when available:

- URL
- Plain text
- Shared title
- Selected text

The exact payload depends on the source app.

---

# End-to-End Flow

```text
User taps Share
        ↓
Selects PlacePick
        ↓
Share Extension captures lightweight input
        ↓
PendingImport is saved to the App Group container
        ↓
Main app opens Add Place
        ↓
Best available phrase is pre-filled into MapKit Search
        ↓
User reviews Apple Maps results
        ↓
User selects the correct result
        ↓
User chooses a primary category
        ↓
Place is saved
        ↓
PendingImport is deleted
        ↓
Return to the map
```

The map remains the product destination.

The import flow should be short and should end by returning the user to their personal map.

---

# Share Extension Responsibilities

The Share Extension should do as little work as possible.

It should:

1. Receive the shared payload.
2. Extract lightweight text and URL metadata already provided by iOS.
3. Derive a reasonable initial search phrase when possible.
4. Save a `PendingImport`.
5. Hand off to the main app.

It should not:

- Perform complex MapKit searches
- Run advanced AI models
- Download large remote assets
- Write final Place records
- Start CloudKit synchronization directly
- Block while parsing a social page
- Import social-media images

This keeps the extension fast, reliable, and within iOS extension limits.

---

# PendingImport Model

`PendingImport` is temporary transport data.

It is not a Place.

Conceptual model:

```swift
struct PendingImport: Codable, Identifiable {
    let id: UUID

    var sourceURL: URL?
    var sharedTitle: String?
    var sharedText: String?
    var suggestedSearchText: String?

    let createdAt: Date
}
```

## Storage

Pending imports should be stored in an App Group shared container so both the Share Extension and main app can access them.

Pending imports:

- Do not sync through iCloud
- Are not permanent user memories
- Should be deleted after successful save
- May expire after a short period
- Must not appear as saved places

---

# Search Phrase Extraction

The MVP should use deterministic, lightweight extraction.

No advanced AI is required.

## Extraction Priority

Use the first useful value from this order:

1. Explicit shared title
2. User-selected text
3. Short shared caption or text
4. Human-readable URL title, when already available
5. URL host or path fragment as a weak fallback
6. Empty search field for manual entry

## Cleanup

Before pre-filling search:

- Trim whitespace
- Remove obvious share boilerplate
- Remove repeated hashtags
- Remove tracking URL fragments
- Collapse repeated spaces
- Limit excessive length
- Preserve non-English place names
- Preserve branch, neighborhood, and city hints when available

The extractor should avoid aggressively rewriting the text.

A slightly imperfect search phrase is safer than an invented location.

---

# Optional Lightweight Parsing

The MVP may use simple heuristics to identify likely place phrases.

Examples:

- Text before a separator such as `|`, `—`, or `-`
- A short title followed by a city or neighborhood
- A business-like phrase near words such as “at,” “in,” or localized equivalents
- Explicit address-like text

Natural Language APIs may be used as a lightweight enhancement to identify organizations or place names, but the feature must remain fully usable without them.

The parser should return search text, not a final Place.

---

# URL Handling

## Apple Maps Links

When the shared URL is an Apple Maps link:

1. Parse any available map item or coordinate information.
2. Resolve it through MapKit when needed.
3. Show the resolved Apple Maps result for confirmation.
4. Never bypass user confirmation.

## Google Maps Links

When the shared URL is a Google Maps link:

1. Extract any available place name, query, or coordinates.
2. Use those values to pre-fill Apple MapKit Search.
3. Ask the user to select the matching Apple Maps result.

The saved Place remains anchored to Apple Maps identity and coordinates.

## Social-Media Links

For social-media URLs:

- Use title or shared text supplied by the share payload.
- Do not depend on scraping the page.
- Do not require login cookies or private-page access.
- Do not preserve the original link as permanent Place data in MVP.

When no useful title or text exists, open Add Place with an empty search field.

---

# Main App Resolution

The main app performs reliable place resolution.

Recommended MapKit components:

- `MKLocalSearchCompleter`
- `MKLocalSearch`
- `MKMapItem`

The pre-filled phrase becomes the initial search query.

The user must select an Apple Maps result before saving.

---

# Search Result UI

The resolution modal should contain:

- Search bar
- Pre-filled search text when available
- Apple Maps result list
- Loading state
- Empty state
- Manual query editing

Each result should show only enough information to disambiguate it, such as:

- Place name
- Locality or neighborhood
- Short address context supplied by MapKit

Address information is allowed here because this is a resolution step.

It does not appear in the final Place Detail Card.

---

# Required Confirmation

A final Place can be created only after the user chooses a reliable MapKit result.

Minimum required resolved data:

- Internal UUID
- Apple Maps identifier when available
- Apple Maps place name
- Latitude
- Longitude
- Primary category

The user may then save immediately.

Note, emotion, favorite, and memory photo are optional and should not slow capture.

---

# Category During Import

The user must select one primary category before saving.

The app may suggest a category based on obvious text or MapKit metadata.

A category suggestion is never authoritative.

The user can change it before or after saving.

MVP category suggestions should be deterministic and simple.

Examples:

```text
cafe / bubble tea / bar → Drink
restaurant / ramen / bakery meal context → Restaurant / Food
museum / gallery → Museum
trail / mountain → Hiking
hotel / resort → Stay / Hotel
ski resort → Skiing
orchard / farm picking → Fruit Picking
```

When uncertain, default to `Other` or ask the user to choose.

---

# Duplicate Detection

Before creating the Place, check for an obvious existing match.

Useful signals:

1. Same Apple Maps identifier
2. Very close coordinates
3. Same normalized name within a small distance

When a likely duplicate exists, show a lightweight choice:

```text
This place is already in PlacePick.

Open Existing
Save Another
```

Do not silently merge or discard the import.

---

# Failure and Fallback Behavior

Import must never fail merely because extraction is weak.

## No Shared Text

Open Add Place with an empty search field.

## Unusable URL

Ignore the URL for extraction and allow manual search.

## No MapKit Results

Allow the user to revise the query.

## Multiple Possible Branches

Show Apple Maps results and require selection.

## Extension Error

Preserve any text already captured when possible and provide a manual Add Place path.

## Offline

The main app remains usable, but new place resolution may require network access.

Do not create an unresolved Place as a substitute.

---

# AI Enhancement — Future, Not MVP

A future version may use a lightweight model when deterministic extraction produces poor search text.

Possible AI output:

```text
Candidate name
City hint
Neighborhood hint
Category hint
```

AI must not:

- Create a Place directly
- Choose a branch without confirmation
- Invent an address
- Import a social-media photo
- Become required for the standard import flow

The fallback must always remain:

```text
Manual MapKit Search
        ↓
User Confirmation
```

---

# Privacy

PlacePick should minimize imported source data.

Rules:

- Store only the temporary content needed to complete import.
- Do not retain entire social-media posts after successful save.
- Do not upload shared text to a third-party AI service in MVP.
- Do not import social-media images.
- Do not preserve source-platform identity as part of the Place.
- Delete completed or expired `PendingImport` records.

The permanent record should contain the resolved Place and the user's own relationship data—not a copy of the social post.

---

# Performance Requirements

The Share Extension should feel immediate.

Targets:

- Capture the shared payload without unnecessary network work.
- Avoid blocking on parsing.
- Open the main app quickly.
- Pre-fill the search before the user begins typing.
- Keep the user-confirmation step obvious.

Advanced interpretation must never make the basic flow slower or less reliable.

---

# Telemetry Boundaries

MVP does not require analytics for imported social content.

If product analytics are added later, measure only coarse events such as:

- Import started
- Search pre-filled
- Place confirmed
- Import abandoned
- Manual query correction used

Do not log:

- Full shared text
- Personal notes
- Exact memory-photo content
- Sensitive source payloads

---

# Implementation Boundaries

Claude or another implementation agent must not:

- Turn import into automatic saving
- Add a permanent source field without approval
- Scrape social networks
- Introduce third-party AI as an MVP dependency
- Store unresolved posts as Places
- Require notes or photos during capture
- Add global search to the main map
- Treat extracted category as authoritative
- Skip Apple Maps confirmation

---

# MVP Success Criteria

The import pipeline succeeds when:

1. Sharing from another app is faster than manually copying a place name.
2. The best obvious phrase is already in the Apple Maps search field.
3. The user can correct imperfect extraction easily.
4. The saved result is a reliable Apple Maps place.
5. Failed extraction never blocks manual saving.
6. No advanced AI is required for the core experience.

---

# Final Principle

> **Import should remove typing, not remove judgment.**

PlacePick helps the user reach the correct Apple Maps result faster.

The user remains the final authority on which place is saved.
