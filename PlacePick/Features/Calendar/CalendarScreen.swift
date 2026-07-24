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
        Set(visits.filter { $0.deletedAt == nil }.map { calendar.startOfDay(for: $0.startedAt) })
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
        let hasVisits = daysWithVisits.contains(calendar.startOfDay(for: day))

        return Button {
            guard hasVisits else { return }
            selectedDay = SelectedDay(date: day)
        } label: {
            VStack(spacing: 4) {
                Text(day, format: .dateTime.day())
                    .font(.subheadline.weight(isToday ? .bold : .regular))
                    .foregroundStyle(hasVisits ? .primary : .secondary)
                    .frame(width: 32, height: 32)
                    .background(isToday ? Circle().fill(Color.accentColor.opacity(0.15)) : nil)

                Circle()
                    .fill(hasVisits ? Color.accentColor : .clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
        .disabled(!hasVisits)
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

#Preview {
    CalendarScreen()
        .modelContainer(for: [Place.self, PlaceCollection.self, Visit.self, VisitPhoto.self], inMemory: true)
}
