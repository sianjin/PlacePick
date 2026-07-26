# PlacePick

A personal memory layer built on top of Apple Maps.

Apple Maps already knows where a place is, what it's called, and how to get there.
PlacePick remembers why it mattered — how it felt, what happened there, and the
photos that prove it.

## What it does

- **Map** — browse your saved Places by *where* they are.
- **Calendar** — browse your Memories by *when* they happened.
- **New Place** — save a Place from an Apple Maps search, organized into a Collection.
- **Photo Memory** — turn a batch of photos into one or more Memories: PlacePick groups
  them by time/location, suggests an Apple Maps place for each group (with a
  tappable mini-map as a second way to pick), and lets you assign a Collection —
  all reviewable in a single screen before anything is saved.
- **Share** — send a Place or a whole Collection to another PlacePick user via the
  Share Extension or a share sheet; receiving one dedups against places you already
  have.
- **iCloud sync** — Places, Collections, Visits, and Photos metadata sync across a
  user's own devices automatically. No login, no sync button.

See `MANIFESTO.md` for the product philosophy and `MVP.md` / `UI_STRUCTURE.md` for
the full feature scope.

## Architecture

- **SwiftUI + SwiftData**, iOS 17+.
- **CloudKit** (private database) backs the SwiftData store for cross-device sync —
  see `PlacePick/App/PlacePickApp.swift` and `DATA_MODEL.md` §23.
- **MapKit** for place search/resolution (`MapSearchService`,
  `NearbyPlaceSearchService`) — PlacePick never invents place identity; every Place
  is anchored to a resolved `MKMapItem`.
- **Data model**: `Place` (identity + Favorite) → `Visit` (one visit's Emotion, Note,
  time range) → `VisitPhoto` (photos attached to a Visit). A Place can have many
  Visits, since the same place can feel different across different visits. Full
  schema in `DATA_MODEL.md`.
- **Share Extension** (`PlacePickShareExtension`) lets other apps hand a URL, text,
  or a PlacePick-exported Place/Collection file to PlacePick.
- Project files are generated from `project.yml` via [XcodeGen](https://github.com/yonaskolb/XcodeGen)
  — the `.xcodeproj` is not committed; regenerate it after pulling changes or editing
  `project.yml`.

## Building

```bash
xcodegen generate
xcodebuild build -project PlacePick.xcodeproj -scheme PlacePick \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Testing

```bash
xcodebuild test -project PlacePick.xcodeproj -scheme PlacePick \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Releasing to TestFlight

```bash
fastlane ios beta
```

Uses manual release signing and a local build-number counter
(`fastlane/build_number.txt`) that's immune to App Store Connect's processing-state
lag. See `fastlane/Fastfile`.

## Documentation

Product philosophy, data model, and design docs live at the repo root:

| Doc | Covers |
| --- | --- |
| `MANIFESTO.md` | Why PlacePick exists, what it chooses not to be |
| `MVP.md` | Scope of the initial product |
| `UI_STRUCTURE.md` | Navigation and interaction flow |
| `DATA_MODEL.md` | Full SwiftData schema and CloudKit considerations |
| `MEMORY_CREATION.md` | The Photo Memory capture flow, stage by stage |
| `MEMORY_DETAIL.md` | The Memory detail screen |
| `DAY_DETAIL.md` | Calendar's day view |
| `PLACE_CREATION.md` | The New Place capture flow |
| `COLLECTIONS.md` | Collections model and sharing |
| `IMPORT_PIPELINE.md` | Share Extension / external content import boundary |
| `RECOMMENDATION_MODEL.md` | How Place importance is scored and presented on the map |
| `DESIGN_PRINCIPLES.md` / `DESIGN_LANGUAGE.md` | Visual and interaction design rules |
| `IMPLEMENTATION_GUIDE.md` | Engineering conventions for this codebase |
