import SwiftUI

/// Lets the user jump directly to any month instead of stepping one month at a time.
/// Tapping the Calendar's month title opens this; picking a month returns to CalendarScreen
/// already showing that month.
struct YearMonthPickerScreen: View {
    let daysWithVisits: Set<Date>
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayedYear: Int

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
            VStack(spacing: 0) {
                yearHeader

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...12, id: \.self) { month in
                        monthCell(month)
                    }
                }
                .padding()

                Spacer()
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
