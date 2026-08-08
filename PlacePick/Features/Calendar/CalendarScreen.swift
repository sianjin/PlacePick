import SwiftUI
import SwiftData

/// Browse Memories by date. See UI_STRUCTURE.md "Calendar Flow": Calendar → Day Detail →
/// Memory Feed → Memory Detail. Answers "When did this happen?" the way Map answers "Where?"
struct CalendarScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var visits: [Visit]

    @State private var displayedMonth = Calendar.current.startOfDay(for: .now)
    @State private var selectedDay: SelectedDay?
    @State private var isPresentingYearMonthPicker = false
    /// Measured once by monthGrid's background GeometryReader and re-measured on rotation —
    /// nil only on the very first render before that measurement lands, when dayCell falls
    /// back to a reasonable default size rather than a jarring zero-width flash.
    @State private var gridWidth: CGFloat?
    /// Measured the same way as gridWidth, via monthHeader's own background
    /// GeometryReader — used to size the trailing blank-space swipe region to start right
    /// below monthHeader, without a hardcoded height.
    @State private var monthHeaderHeight: CGFloat = 56
    /// monthGrid's own measured height, via its background GeometryReader — used together
    /// with monthHeaderHeight to size the trailing blank-space swipe region to fill exactly
    /// what's left of the screen below the grid.
    @State private var gridContentHeight: CGFloat = 0
    /// weekdayHeader's own measured height, via its background GeometryReader — used
    /// together with monthHeaderHeight and screen height to derive cellSize from
    /// available height as well as width (see monthGrid's doc comment).
    @State private var weekdayHeaderHeight: CGFloat = 20

    private let calendar = Calendar.current

    private var daysWithVisits: Set<Date> {
        Set(daySummaries.keys)
    }

    /// One summary per day with at least one active Visit — cover photo (if any), Visit
    /// count, and dominant Emotion — computed once per grid render rather than per cell, so
    /// dayCell(_:) stays a pure lookup. Dominant, not most-recent, Emotion: a day's tint
    /// should reflect what the day was mostly like, not be arbitrarily decided by whichever
    /// Visit happened to be logged last.
    private var daySummaries: [Date: DaySummary] {
        let grouped = Dictionary(grouping: visits.filter { $0.deletedAt == nil }) {
            calendar.startOfDay(for: $0.startedAt)
        }
        return grouped.mapValues(summarize(visitsForDay:))
    }

    private func summarize(visitsForDay: [Visit]) -> DaySummary {
        let orderedVisits = visitsForDay.sorted { $0.startedAt < $1.startedAt }
        let coverPhotoIdentifier = orderedVisits.compactMap(firstActivePhotoIdentifier).first

        let emotionCounts: [PlaceEmotion: Int] = Dictionary(grouping: visitsForDay.compactMap(\.emotion), by: { $0 })
            .mapValues(\.count)
        let dominantEmotion = emotionCounts.max(by: isLessPreferred)?.key

        return DaySummary(visitCount: visitsForDay.count, coverPhotoIdentifier: coverPhotoIdentifier, dominantEmotion: dominantEmotion)
    }

    /// Tie-break rule for picking a day's dominant Emotion: more occurrences wins; on a
    /// count tie, the more positive Emotion wins, rather than an arbitrary/insertion-order
    /// pick.
    private func isLessPreferred(_ lhs: (key: PlaceEmotion, value: Int), _ rhs: (key: PlaceEmotion, value: Int)) -> Bool {
        if lhs.value != rhs.value {
            return lhs.value < rhs.value
        }
        return lhs.key.positivityRank < rhs.key.positivityRank
    }

    /// Matches VisitPhotoRepository.fetchPhotos' cover-photo convention (lowest sortOrder,
    /// not insertion order) — see VisitPhotoRepository.reorder, which is how "set as cover
    /// photo" is implemented.
    private func firstActivePhotoIdentifier(of visit: Visit) -> String? {
        let activePhotos = (visit.photos ?? []).filter { $0.deletedAt == nil }
        return activePhotos.min { $0.sortOrder < $1.sortOrder }?.localAssetIdentifier
    }

    var body: some View {
        NavigationStack {
            GeometryReader { screenProxy in
                // Scrolling only exists as a landscape/short-screen fallback for when a
                // month's rows genuinely don't fit. Leaving it enabled unconditionally
                // meant every portrait swipe-to-change-month gesture was also competing
                // with ScrollView's own vertical pan recognizer, which is what produced
                // the vertical jitter/scrollbar-flash the user reported — a swipe that's
                // slightly off pure-horizontal would get partially eaten as a scroll. With
                // scrolling off whenever content actually fits the screen (the normal
                // portrait case), there's no vertical pan gesture present to compete with
                // at all.
                let contentFits = monthHeaderHeight + gridContentHeight <= screenProxy.size.height
                let availableGridHeight = max(0, screenProxy.size.height - monthHeaderHeight - weekdayHeaderHeight)

                ScrollView {
                    VStack(spacing: 0) {
                        monthHeader

                        weekdayHeader
                        monthGrid(availableHeight: availableGridHeight)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.onAppear { gridContentHeight = proxy.size.height }
                                        .onChange(of: proxy.size.height) { _, newHeight in gridContentHeight = newHeight }
                                }
                            }

                        // Swipe-to-navigate reuses shiftMonth(by:), the same logic already
                        // wired to the chevron buttons, so behavior can't drift between
                        // the two ways of changing month.
                        //
                        // This sits in the blank space *below* monthGrid, not on top of
                        // it or of monthHeader — three attempts at overlaying the day-cell
                        // grid itself (plain hitTest passthrough, cancelsTouchesInView, a
                        // UIGestureRecognizerDelegate declaring simultaneous recognition)
                        // all still ended up blocking taps on the day-cell Buttons
                        // underneath on device, and the header's dropdown button had the
                        // same problem the first time this covered the whole screen. A
                        // day cell or month cell itself is therefore tap-only — swipe
                        // works from the header and from this trailing blank region, sized
                        // to fill the rest of the screen below the grid using
                        // gridContentHeight (monthGrid's own measured height) and
                        // monthHeaderHeight, both real measurements rather than guessed
                        // constants.
                        //
                        // None of SwiftUI's own gesture-priority modifiers (.gesture,
                        // .simultaneousGesture, .highPriorityGesture — all tried, all
                        // silently did nothing on device) can out-arbitrate a ScrollView's
                        // native UIScrollView.panGestureRecognizer, because that recognizer
                        // lives outside SwiftUI's gesture-composition tree entirely; those
                        // modifiers only arbitrate against other SwiftUI gestures.
                        // HorizontalSwipeRecognizerView wraps a real UIPanGestureRecognizer
                        // with a UIGestureRecognizerDelegate — the one API that actually
                        // arbitrates against a native recognizer — which is still needed
                        // here since this blank region also sits inside the same
                        // ScrollView.
                        Color.clear
                            .frame(minHeight: max(0, screenProxy.size.height - monthHeaderHeight - gridContentHeight))
                            .overlay {
                                HorizontalSwipeRecognizerView { leftward in
                                    withAnimation {
                                        shiftMonth(by: leftward ? 1 : -1)
                                    }
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
                .scrollDisabled(contentFits)
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedDay) { selection in
                DayDetailScreen(day: selection.date)
            }
            .sheet(isPresented: $isPresentingYearMonthPicker) {
                YearMonthPickerScreen(initialMonth: displayedMonth, daysWithVisits: daysWithVisits) { month in
                    displayedMonth = month
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Button {
                isPresentingYearMonthPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(displayedMonth, format: .dateTime.month(.wide).year())
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background {
            GeometryReader { proxy in
                Color.clear.onAppear { monthHeaderHeight = proxy.size.height }
                    .onChange(of: proxy.size.height) { _, newHeight in monthHeaderHeight = newHeight }
            }
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
        .background {
            GeometryReader { proxy in
                Color.clear.onAppear { weekdayHeaderHeight = proxy.size.height }
                    .onChange(of: proxy.size.height) { _, newHeight in weekdayHeaderHeight = newHeight }
            }
        }
    }

    /// A resizable Image's own aspect ratio can leak through GridItem(.flexible())'s
    /// proposed width inside a LazyVGrid — a wide source photo bled its column wider than
    /// its neighbors, visibly shifting the day number and, on edge columns with no
    /// neighbor to compress against, expanding freely. Reading the available width via
    /// GeometryReader and deriving one explicit cellSize removes that ambiguity: every
    /// cell gets the same hard .frame(width:height:), so no child's intrinsic content size
    /// can influence a cell's box.
    ///
    /// The GeometryReader lives in a zero-height .background rather than wrapping the grid
    /// directly — a GeometryReader wrapping content reports a *fixed* size to its children
    /// (it doesn't propagate their natural height back out), which previously forced this
    /// view into a separate, error-prone manually-computed height. Reading width via a
    /// background instead leaves LazyVGrid free to report its own natural content height,
    /// which is also what makes the enclosing ScrollView on the whole screen (added
    /// alongside this) actually able to scroll every row into view, including in landscape
    /// where the screen's height doesn't fit a full month without scrolling.
    ///
    /// cellSize is derived from BOTH available width and available height, taking
    /// whichever is smaller — deriving it from width alone (screenWidth / 7) left most of
    /// a typical portrait screen's height as unused blank space below the grid even after
    /// trimming spacing/margins, since those are small next to the screen's actual excess
    /// height. Taking the min of both means a short month (5 rows) gets larger cells than
    /// a long one (6 rows), since the same available height splits across fewer rows —
    /// intentional, so the grid always fills the screen rather than leaving dead space.
    private func monthGrid(availableHeight: CGFloat) -> some View {
        let days = daysInGrid(for: displayedMonth)
        // Column spacing stays tight so cells claim as much of the row's width as
        // possible; row spacing is larger than column spacing so weeks read as visually
        // distinct (user feedback: cells packed edge-to-edge vertically made the photos
        // feel dense and hard to make out).
        // LazyVGrid's own `spacing:` controls row gaps only once each GridItem carries its
        // own column spacing, so the two can differ.
        //
        // Width, not height, is the binding constraint on a phone (7 columns vs. 5-6
        // rows), so column spacing/margin — not row spacing — is the actual lever for
        // bigger cells; tightened further here (from 6pt/8pt margin to near edge-to-edge,
        // matching Day One's own calendar) after discovering the height-based branch of
        // cellSize below could only ever match or lose to the width-based one, never win,
        // since width was already the smaller number.
        let columnSpacing: CGFloat = 3
        let rowSpacing: CGFloat = 12

        let rowCount = CGFloat((days.count + 6) / 7)
        let widthBasedSize = gridWidth.map { ($0 - columnSpacing * 6) / 7 }
        let heightBasedSize = rowCount > 0 ? max(0, (availableHeight - rowSpacing * (rowCount - 1)) / rowCount) : nil
        let cellSize = [widthBasedSize, heightBasedSize].compactMap { $0 }.min() ?? 44

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: columnSpacing), count: 7), spacing: rowSpacing) {
            ForEach(days, id: \.self) { day in
                if let day {
                    dayCell(day, size: cellSize)
                } else {
                    Color.clear.frame(width: cellSize, height: cellSize)
                }
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear.onAppear { gridWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newWidth in gridWidth = newWidth }
            }
        }
        // Near edge-to-edge, matching Day One's own calendar — cellSize is screen width
        // minus this padding divided across 7 columns, so trimming the margin here is the
        // actual lever for larger cells (width is the binding constraint on a phone, not
        // height — see columnSpacing's comment above).
        .padding(.horizontal, 2)
        .padding(.top, 8)
    }

    private func dayCell(_ day: Date, size: CGFloat) -> some View {
        let isToday = calendar.isDateInToday(day)
        let summary = daySummaries[calendar.startOfDay(for: day)]

        return Button {
            guard summary != nil else { return }
            selectedDay = SelectedDay(date: day)
        } label: {
            DayCellContent(day: day, isToday: isToday, summary: summary, size: size)
        }
        .buttonStyle(.plain)
        .disabled(summary == nil)
    }

    /// Full weeks including leading/trailing days from adjacent months as nil placeholders
    /// so the grid always aligns to weekday columns.
    private func daysInGrid(for month: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeekOfMonth = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else { return [] }

        var days: [Date?] = []
        var current = firstWeekOfMonth.start
        while current < monthInterval.end {
            if current >= monthInterval.start {
                days.append(current)
            } else {
                days.append(nil)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? monthInterval.end
        }
        return days
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = newMonth
    }
}

private struct SelectedDay: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSinceReferenceDate }
}

private struct DaySummary {
    let visitCount: Int
    let coverPhotoIdentifier: String?
    let dominantEmotion: PlaceEmotion?
}

/// A single Calendar day cell. Shows the day's cover Photo when one exists — reusing
/// PhotoAssetThumbnailView, the same async PHAsset pipeline as MemoryCard and
/// PlaceDetailSheet — falling back to the plain number-and-dot treatment for days whose
/// Visits have no attached Photo (Visit.photos is optional and the AddPlace flow never
/// requires one, so this is a common case, not an edge case).
private struct DayCellContent: View {
    let day: Date
    let isToday: Bool
    let summary: DaySummary?
    /// Explicit, pre-computed square size from monthGrid's GeometryReader — every branch
    /// below must apply this as a hard .frame(width:height:), not .frame(maxWidth: .infinity),
    /// since a resizable Image's own aspect ratio can otherwise leak through a merely
    /// "flexible" proposal and inflate the cell (see monthGrid's doc comment).
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let summary, let coverPhotoIdentifier = summary.coverPhotoIdentifier {
                PhotoAssetThumbnailView(localAssetIdentifier: coverPhotoIdentifier, fallbackIcon: "photo")
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.14))
                    .overlay {
                        if let dominantEmotion = summary.dominantEmotion {
                            RoundedRectangle(cornerRadius: size * 0.14)
                                .strokeBorder(dominantEmotion.tintColor, lineWidth: max(2, size * 0.035))
                        }
                    }
            } else {
                Color.clear
                    .frame(width: size, height: size)
                    .overlay {
                        if let dominantEmotion = summary?.dominantEmotion {
                            Circle()
                                .strokeBorder(dominantEmotion.tintColor, lineWidth: max(2, size * 0.035))
                                .frame(width: size * 0.85, height: size * 0.85)
                        }
                    }
            }

            // Same top-leading position in every cell, photo or not, so the number doesn't
            // jump around as the eye scans a row mixing both cell types.
            dayNumber
                .foregroundStyle(summary?.coverPhotoIdentifier != nil ? .white : (summary == nil ? .secondary : .primary))
                .shadow(radius: summary?.coverPhotoIdentifier != nil ? 2 : 0)
                .padding(size * 0.09)

            if summary != nil, summary?.coverPhotoIdentifier == nil {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: size * 0.1, height: size * 0.1)
                    .frame(width: size, height: size, alignment: .bottom)
                    .padding(.bottom, size * 0.13)
            }

            if let summary, summary.visitCount > 1 {
                countBadge(summary.visitCount, size: size)
                    .frame(width: size, height: size, alignment: .topTrailing)
                    .offset(x: size * 0.12, y: -size * 0.12)
            }
        }
        .frame(width: size, height: size)
    }

    /// "Today" is a small trailing dot beside the number rather than the previous
    /// filled-circle-behind-the-number treatment — a fill would sit on top of and obscure a
    /// Photo cell. It also can't reuse the ring used for dominantEmotion below, since a cell
    /// can be both today and carry an Emotion tint at once.
    ///
    /// Font size and dot size scale with the cell's own size (proportional constants
    /// below) rather than staying fixed — a fixed font/dot size was invisible to the eye
    /// as cellSize changed elsewhere, since these are small elements relative to the whole
    /// cell; scaling them keeps the day number, "today" dot, ring stroke, and count badge
    /// all visually balanced as cells grow or shrink, and makes any future cell-size
    /// change actually visible rather than subtle.
    private var dayNumber: some View {
        HStack(spacing: 2) {
            Text(day, format: .dateTime.day())
                .font(.system(size: size * 0.32, weight: isToday ? .semibold : .regular))
            if isToday {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: size * 0.09, height: size * 0.09)
            }
        }
    }

    private func countBadge(_ count: Int, size: CGFloat) -> some View {
        Text("\(count)")
            .font(.system(size: max(9, size * 0.22), weight: .bold))
            .foregroundStyle(.white)
            .padding(size * 0.09)
            .background(Circle().fill(Color.accentColor))
    }
}

extension PlaceEmotion {
    /// Ordering used only to break emotion-count ties when computing a day's dominant
    /// Emotion (CalendarScreen.daySummaries) — favors the more positive Emotion rather than
    /// an arbitrary/insertion-order pick.
    fileprivate var positivityRank: Int {
        switch self {
        case .neutral: return 0
        case .happy: return 1
        case .amazed: return 2
        }
    }
}

#Preview {
    CalendarScreen()
        .modelContainer(for: [Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self], inMemory: true)
}
