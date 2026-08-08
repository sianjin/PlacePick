import SwiftUI

/// Lets the user jump directly to any month instead of stepping one month at a time.
/// Tapping the Calendar's month title opens this; picking a month returns to CalendarScreen
/// already showing that month.
struct YearMonthPickerScreen: View {
    let daysWithVisits: Set<Date>
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayedYear: Int
    /// Measured via yearHeader's own background GeometryReader — used to size the
    /// swipeable region below the header to fill the rest of the screen, same pattern as
    /// CalendarScreen.monthHeaderHeight.
    @State private var yearHeaderHeight: CGFloat = 56
    /// The LazyVGrid's own measured height, via its background GeometryReader — used
    /// together with yearHeaderHeight to size the trailing blank-space swipe region,
    /// same pattern as CalendarScreen.gridContentHeight.
    @State private var gridContentHeight: CGFloat = 0

    private let calendar = Calendar.current

    init(initialMonth: Date, daysWithVisits: Set<Date>, onSelect: @escaping (Date) -> Void) {
        self.daysWithVisits = daysWithVisits
        self.onSelect = onSelect
        _displayedYear = State(initialValue: Calendar.current.component(.year, from: initialMonth))
    }

    private var monthsWithVisits: Set<Int> {
        let calendar = self.calendar
        return Set(
            daysWithVisits
                .filter { calendar.component(.year, from: $0) == displayedYear }
                .map { calendar.component(.month, from: $0) }
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { screenProxy in
                VStack(spacing: 0) {
                    yearHeader
                        .background {
                            GeometryReader { proxy in
                                Color.clear.onAppear { yearHeaderHeight = proxy.size.height }
                                    .onChange(of: proxy.size.height) { _, newHeight in yearHeaderHeight = newHeight }
                            }
                        }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(1...12, id: \.self) { month in
                            monthCell(month)
                        }
                    }
                    .padding()
                    .background {
                        GeometryReader { proxy in
                            Color.clear.onAppear { gridContentHeight = proxy.size.height }
                                .onChange(of: proxy.size.height) { _, newHeight in gridContentHeight = newHeight }
                        }
                    }

                    // Matches CalendarScreen's own swipe-to-navigate gesture — here a
                    // horizontal swipe moves a year at a time, the same as tapping the
                    // chevrons in yearHeader.
                    //
                    // This sits in the blank space *below* the LazyVGrid, not on top of
                    // it: overlaying the grid itself was tried (with a
                    // UIGestureRecognizerDelegate declaring simultaneous recognition, and
                    // separately with cancelsTouchesInView = false) and still ended up
                    // blocking taps on the month-cell Buttons underneath on device — see
                    // HorizontalSwipeRecognizerView's own doc comment. A month cell is
                    // therefore tap-only; swipe works from this trailing blank region,
                    // sized to fill the rest of the screen below the grid using
                    // gridContentHeight and yearHeaderHeight, both real measurements
                    // rather than guessed constants.
                    Color.clear
                        .frame(minHeight: max(0, screenProxy.size.height - yearHeaderHeight - gridContentHeight))
                        .overlay {
                            HorizontalSwipeRecognizerView { leftward in
                                withAnimation {
                                    displayedYear += leftward ? 1 : -1
                                }
                            }
                        }
                }
            }
            .navigationTitle("Choose a Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var yearHeader: some View {
        HStack {
            Button {
                displayedYear -= 1
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(String(displayedYear))
                .font(.title3.weight(.semibold))

            Spacer()

            Button {
                displayedYear += 1
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func monthCell(_ month: Int) -> some View {
        let hasVisits = monthsWithVisits.contains(month)
        let isCurrentMonth = calendar.component(.year, from: .now) == displayedYear
            && calendar.component(.month, from: .now) == month
        let monthDate = calendar.date(from: DateComponents(year: displayedYear, month: month, day: 1))

        return Button {
            guard let monthDate else { return }
            onSelect(monthDate)
            dismiss()
        } label: {
            VStack(spacing: 6) {
                Text(monthSymbol(month))
                    .font(.subheadline.weight(isCurrentMonth ? .bold : .regular))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Circle()
                            .fill(isCurrentMonth ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                    )

                Circle()
                    .fill(hasVisits ? Color.accentColor : .clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
    }

    private func monthSymbol(_ month: Int) -> String {
        calendar.shortMonthSymbols[month - 1]
    }
}
