# PlacePick — Editor's Choice Improvement Plan

Status: In progress — steps 2–4 shipped on `feature/editors-choice-ui`; step 5 effectively folded into step 2; step 1 dropped (see note); step 6 not started
Date: 2026-08-01, updated 2026-08-07

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

**1. Minimal design system — DROPPED, not needed**
Originally scoped as a prerequisite for everything else. In practice, steps 2–4 shipped without it, and the two small constant files that emerged along the way (`CardStyle.swift`, `PlaceEmotion+Style.swift`) already cover the actual cross-screen consistency needed — no `Theme.swift` or broader token system currently justified. Revisit only if a future surface needs shared styling that doesn't fit either existing file.

**2. Redesign `EmotionPicker` — SHIPPED** (`PersonalInfoForm.swift`, `PlaceEmotion+Style.swift`)
Selected emotion gets a colored ring (`PlaceEmotion.tintColor` — promoted out of `CalendarScreen.swift` into its own shared extension file so the emotion picker and the calendar's day-cell rings use identical colors) plus a spring scale-up (1.0 → 1.12, `response: 0.35, dampingFraction: 0.6`), and a light haptic tap via the existing `Haptics.selection()` helper. Unselected options still dim to 40% opacity once something is picked. Self-contained change to `EmotionPicker` in `PersonalInfoForm.swift`; `MemoryDetailScreen.swift` gets it for free since both use the same component.

**3. Card treatment for `MemoryCard` / `PlaceDetailSheet` / `MemoryRow` — SHIPPED** (`DayDetailScreen.swift`, `PlaceDetailSheet.swift`, `CardStyle.swift`)
Both now have a `secondarySystemBackground` fill, a rounded container (16pt outer / 10pt inner for nested photo corners), and a subtle shadow (12% black, 6pt radius, 2pt y-offset) — pulled from a new shared `CardStyle` enum rather than each hand-typing its own `cornerRadius`. `MemoryRow` sits in a plain `VStack(spacing: 10)`, not a native `List`, so the card treatment fits without fighting an existing list style.

**4. Photo-first calendar month view — SHIPPED** (`feature/editors-choice-ui`, `CalendarScreen.swift` / `YearMonthPickerScreen.swift` / `HorizontalSwipeRecognizerView.swift`)
Reference: Day One's month grid shows a photo thumbnail in each day cell that has an entry, instead of a plain dot. Adapted (not copied) for PlacePick — final shipped design diverges from the original proposal in a few places, noted below.

- Day cells show the day's cover photo (lowest-`sortOrder` active `VisitPhoto`) via `PhotoAssetThumbnailView`, falling back to the plain number treatment for photo-less visit days — confirmed a real, common case since `Visit.photos` is optional and the AddPlace flow never requires one.
- **Count badge** (top-trailing, accent-filled circle) shown when a day has more than one Visit, independent of whether the cell has a photo.
- **Feeling tint** uses dominant emotion (by count, ties broken toward the more positive emotion), rendered as an accent-colored ring around the cell.
- **"Today"** is a small accent dot beside the day number (not a ring — that's reserved for the emotion tint, and a filled circle would obscure a photo).
- **Cell sizing**: derived from measured screen width (`GeometryReader` + background measurement, not `UIScreen.main.bounds`), with near-edge-to-edge margins/column-spacing to maximize cell size — width, not height, is the binding constraint at 7 columns on a phone, so a parallel height-based sizing branch was added but is a no-op in practice. Day number, "today" dot, count badge, and emotion-ring stroke width all scale proportionally with cell size rather than staying fixed, so they stay visually balanced as cells grow/shrink.
- **Swipe-to-change-month/year**, added beyond the original scope after user request. Required a custom `UIViewRepresentable` (`HorizontalSwipeRecognizerView`) wrapping a real `UIPanGestureRecognizer` with `cancelsTouchesInView = false` — SwiftUI's own `.gesture`/`.simultaneousGesture`/`.highPriorityGesture` cannot out-arbitrate `ScrollView`'s native `UIScrollView.panGestureRecognizer`, which lives outside SwiftUI's gesture tree entirely. The swipe-catching overlay is deliberately **not** placed on top of day-cell/month-cell buttons (three attempts at making tap-and-swipe coexist on the same overlay all still broke tapping on-device) — it only covers the header area and the blank space below the grid. Vertical `ScrollView` scrolling is disabled whenever the month's content already fits the screen (the normal portrait case), since leaving it enabled produced vertical jitter/scrollbar-flash fighting the horizontal swipe.
- Grid is a fixed single month (`LazyVGrid`, ~35-42 cells max, no infinite scroll), so bounded thumbnail loading is not a performance concern.

Note: this project uses XcodeGen (`project.yml`) — any new Swift file needs `xcodegen generate` run before Xcode's build will see it; `Write`-ing the file alone is not sufficient.

**5. One bespoke motion moment — folded into step 2**
The emotion-picker spring + haptic (step 2) is this moment; the `matchedGeometryEffect` map-pin-to-detail-sheet transition remains an option but is on hold — revisit only if the app still feels flat after seeing 1–4 together in context.

**6. Reshoot App Store screenshots**
Not started. Deliberately held until v1.0 clears App Review — will use a TestFlight build with real production data (this session's local dev builds run against CloudKit's Development database, not the same data as production). Add a Collections/sharing screenshot to show product range beyond map/list/detail. The photo-first calendar (step 4) and the restyled cards (step 3) are strong new "designed moment" screenshot candidates.

**7. Place Detail revisit-history polish — SHIPPED** (`PlaceDetailSheet.swift`)
Added after studying Apple Journal (see Competitive positioning below) — Place Detail is the screen that proves "one place, many memories," a claim Journal's chronological-stream structure cannot replicate, so it deserved to look considered:
- Section heading changed from a bare "Memories" to "N Memories" — the visit count is the actual point of this screen and was previously invisible unless you scrolled and counted rows yourself.
- Each `MemoryRow`'s photo thumbnail now gets the same emotion-tint ring as the Calendar's day cells and `EmotionPicker`'s selected state (`PlaceEmotion.tintColor`), instead of a tiny inline emoji easy to miss — a visit's feeling now reads consistently everywhere it appears.

## Sequencing

~~Theme file~~ → EmotionPicker rewrite (2) → photo-first calendar (4) → card styling (3, using constants pulled out ad hoc rather than a separate upfront theme file) → Place Detail revisit-history polish (7) → remaining: step 6 (reshoot screenshots, blocked on v1.0 App Review).

## Competitive positioning (Apple Journal, studied 2026-08-07)

Apple Journal is visually more polished than Day One (gradient hero cards, native photo-collage stacking, on-device ML auto-titling, video support) — worth studying for craft, **not worth copying structurally**. Journal's information architecture is chronological-stream-first: every entry (a walk, a meal, a flight) sits in one undifferentiated timeline grouped by day. Its "Places" summary is just a count of unique pins — Places is metadata about the journal, not a way to browse it. There is no view in Journal showing "every time I've been to this specific place."

That gap is exactly PlacePick's structural bet (a Place is a persistent entity accumulating Visits over time; the Calendar is one lens onto that, not the primary structure) and is the concrete difference to lean into rather than blur:

- **Revisit history at a Place** (step 7 above) — Journal has no equivalent; you'd have to search and manually assemble it.
- **Structured per-visit Emotion**, not freeform prose — aggregable (the Calendar's dominant-emotion ring depends on this), unlike Journal's plain text.
- **Place names from Apple Maps**, not ML-guessed titles ("A day to Santa Cruz," "Evening outing near The Kitchen") — accurate, not inferred.

Explicitly decided **not** to chase: Journal's photo-collage/stacking layout (that's chronological-stream language; the Calendar's photo-first day cell already does the equivalent "what happened that day" job) and gradient hero cards (reads as "Apple system app," not differentiated if copied). Video support is a real capability gap worth a separate look, but the reason to add it should be "existing Memories deserve video too," not "match Journal's feature list" — not yet investigated.

## Reference apps

- **Day One** — studied for month-grid calendar (photo-first day cells vs. plain dots). Source: user-provided screenshots, 2026-08-06.
- **Apple Journal** — studied for visual craft and, more importantly, as a foil for PlacePick's Place-centric (vs. chronological-stream) structure. Source: user-provided screenshots, 2026-08-07.
