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
            VStack(spacing: 0) {
                monthHeader
                weekdayHeader
                monthGrid
                Spacer()
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
    }

    private var monthGrid: some View {
        let days = daysInGrid(for: displayedMonth)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func dayCell(_ day: Date) -> some View {
        let isToday = calendar.isDateInToday(day)
        let summary = daySummaries[calendar.startOfDay(for: day)]

        return Button {
            guard summary != nil else { return }
            selectedDay = SelectedDay(date: day)
        } label: {
            DayCellContent(day: day, isToday: isToday, summary: summary)
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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let summary, let coverPhotoIdentifier = summary.coverPhotoIdentifier {
                PhotoAssetThumbnailView(localAssetIdentifier: coverPhotoIdentifier, fallbackIcon: "photo")
                    .frame(height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        if let dominantEmotion = summary.dominantEmotion {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(dominantEmotion.tintColor, lineWidth: 2)
                        }
                    }
                    .overlay(alignment: .bottomLeading) {
                        dayNumber
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                            .padding(4)
                    }
            } else {
                VStack(spacing: 4) {
                    dayNumber
                        .foregroundStyle(summary == nil ? .secondary : .primary)

                    Circle()
                        .fill(summary == nil ? .clear : Color.accentColor)
                        .frame(width: 5, height: 5)
                }
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .overlay {
                    if let dominantEmotion = summary?.dominantEmotion {
                        Circle()
                            .strokeBorder(dominantEmotion.tintColor, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }
                }
            }

            if let summary, summary.visitCount > 1 {
                countBadge(summary.visitCount)
                    .offset(x: 6, y: -6)
            }
        }
    }

    /// "Today" is a small trailing dot beside the number rather than the previous
    /// filled-circle-behind-the-number treatment — a fill would sit on top of and obscure a
    /// Photo cell. It also can't reuse the ring used for dominantEmotion below, since a cell
    /// can be both today and carry an Emotion tint at once.
    private var dayNumber: some View {
        HStack(spacing: 2) {
            Text(day, format: .dateTime.day())
                .font(.subheadline.weight(isToday ? .semibold : .regular))
            if isToday {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 4, height: 4)
            }
        }
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(4)
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

    fileprivate var tintColor: Color {
        switch self {
        case .neutral: return .gray
        case .happy: return .yellow
        case .amazed: return .orange
        }
    }
}

#Preview {
    CalendarScreen()
        .modelContainer(for: [Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self], inMemory: true)
}
