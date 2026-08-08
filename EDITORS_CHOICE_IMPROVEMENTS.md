# PlacePick — Editor's Choice Improvement Plan

Status: Proposal, not started
Date: 2026-08-01

---

## Context

PlacePick has strong positioning and disciplined App Store copy ("A place is a fact. What happened there is a memory."), but the visual execution isn't yet at Editor's Choice bar. Current App Store screenshots lean on stock MapKit chrome and default SwiftUI components rather than showing designed moments.

Confirmed by reading the actual views — there is no design system in the codebase: no `Theme.swift` / `Colors.swift` / `Fonts.swift`, no custom color sets in `Assets.xcassets`, all typography is system fonts (`.headline`, `.subheadline`), all colors are system semantic (`.primary`, `.secondary`, `Color.accentColor`). The custom `VStack`/`HStack` card layouts already in place (`MemoryCard`, `PlaceDetailSheet`, `MemoryRow`) are a reasonable foundation — they just carry no visual polish (no shadow, no card background, ad hoc `cornerRadius: 12` repeated by hand instead of a shared token).

The `EmotionPicker` — the headline differentiator ("a feeling, not a score") — is currently three `Text(emoji)` views at `.title2`, dimmed by opacity when unselected. No selection ring, no scale, no color, no animation.

## Gaps vs. Editor's Choice bar

1. Screenshots show system UI (Apple Maps tiles, default sheets), not designed moments.
2. The emotion picker — the app's core differentiator — looks like a placeholder, not a considered interaction.
3. No screenshot shows Collections or sharing, so the listing undersells the app's actual depth.
4. No timely/platform hook (widget, Live Activity, etc.) to give a reviewer a "why now."

## Plan

**1. Minimal design system** (`Theme.swift` or similar)
Small set of constants: 2–3 accent colors (could build on the emotion concept — warm tone for "amazed," neutral gray for "neutral"), one corner-radius scale (e.g. 12/16/20), one shadow style. Every other change below depends on this existing first.

**2. Redesign `EmotionPicker`**
Replace bare `Text(emoji)` with circular backgrounds sized to `.title` emoji, a real selected state (scale + colored ring/fill, not just opacity), spring animation on selection (`withAnimation(.spring)`). Self-contained, ~40-line rewrite in `PersonalInfoForm.swift` / reused in `MemoryDetailScreen.swift`. Highest visual payoff for the lowest risk — do this first after the theme file.

**3. Card treatment for `MemoryCard` / `PlaceDetailSheet` / `MemoryRow`**
Background fill, corner radius from theme constants, subtle shadow. Small diffs, benefits every screenshot at once.

**4. Photo-first calendar month view**
Reference: Day One's month grid shows a photo thumbnail in each day cell that has an entry, instead of a plain dot. Adapted (not copied) for PlacePick:

- `CalendarScreen.swift:103-125` (`dayCell`) currently renders `Text(day)` + a 5×5 accent dot when `hasVisits`. When the day's representative Visit has a photo, replace the dot with a photo thumbnail using the existing `PhotoAssetThumbnailView` / `PhotoAssetLoader` pipeline (already used for cover photos in `DayDetailScreen.swift:300,313`) — no new photo infra needed.
- **A photo is not guaranteed.** Confirmed in code: `Visit.photos` is optional and defaults to empty (`Shared/Models/Visit.swift:44`), and the `PersonalInfoForm`/`AddPlaceScreen` creation flow has no photo step at all — only Collection is required to save. So photo-less visit days are a real, common case, not an edge case: those cells keep today's number-+-dot treatment, they don't get a placeholder image.
- `daysWithVisits` (lines 16-18) currently collapses to a bare `Set<Date>`, discarding the `Visit` objects; needs to instead map each day to its representative `Visit`(s) — photo (if any), count, and dominant emotion — mirroring `DayDetailScreen`'s existing `coverPhotoIdentifier` logic.
- **Count badge**: small overlay badge (top-right or bottom-right corner of the cell, iOS-native badge style) showing the memory count, shown only when a day has more than one Visit. Sits on top of the photo fill (or the plain-number cell, if no photo) — independent of whether the cell has a photo, so no coexistence conflict.
- **Feeling tint, using dominant emotion** (the most frequent `PlaceEmotion` among that day's visits, not last-logged — last-logged is arbitrary when a day has multiple memories and doesn't reflect what the day was actually like). Rendered as a thin accent ring traced around the cell edge.
- **Ring conflict, resolved**: feeling-tint and "today" both initially wanted a ring around the cell — they can't share it. Feeling-tint keeps the ring (it's core product content). "Today" moves to a small corner dot/mark instead of its current filled-circle-behind-the-number treatment, since a filled circle would also obscure a photo cell.
- Grid is a fixed single month (`LazyVGrid`, ~35-42 cells max, no infinite scroll), so bounded thumbnail loading is not a performance concern.

**5. One bespoke motion moment**
Best candidate: emotion selection spring + haptic, or a `matchedGeometryEffect` transition from map pin to place detail sheet. Pick one, not both — keep scope tight. Only pursue if steps 1–4 still feel insufficient.

**6. Reshoot App Store screenshots**
After 1–4 land, with real data. Add a Collections/sharing screenshot to show product range beyond map/list/detail. The photo-first calendar (step 4) is a strong new "designed moment" screenshot candidate.

## Sequencing

Theme file → EmotionPicker rewrite → card styling → photo-first calendar → reshoot screenshots. Hold the `matchedGeometryEffect` transition (step 5) until after seeing whether 1–4 close the gap.

## Reference apps

- **Day One** — studied for month-grid calendar (photo-first day cells vs. plain dots). Source: user-provided screenshot, 2026-08-06.
