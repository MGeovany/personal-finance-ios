import Foundation

/// Splits the month into seven-day slices, giving each week an amount in
/// proportion to the days it holds. The last, usually short, week gets the
/// rounding remainder so the weekly amounts always add back up to the month.
struct WeeklyBudgetSplitter: WeeklyBudgetSplitting {
    private let calendar: Calendar

    init(calendar: Calendar = Calendar.current) {
        self.calendar = calendar
    }

    func split(monthly: Money, containing date: Date) -> WeeklyBudget {
        let monthStart = calendar.startOfMonth(for: date)
        let dayCount = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let boundaries = stride(from: 0, to: dayCount, by: 7).map { $0 }

        var weeks: [BudgetWeek] = []
        var assigned = Money.zero

        for (index, startOffset) in boundaries.enumerated() {
            let endOffset = min(startOffset + 7, dayCount)
            let isLast = index == boundaries.count - 1
            let days = endOffset - startOffset
            let amount = isLast
                ? monthly - assigned // absorbs the remainder, keeping the sum exact
                : monthly.scaled(by: Double(days) / Double(dayCount)).rounded
            assigned += amount

            weeks.append(
                BudgetWeek(
                    index: index,
                    start: calendar.addingDays(startOffset, to: monthStart),
                    end: calendar.addingDays(endOffset, to: monthStart),
                    amount: amount
                )
            )
        }

        return WeeklyBudget(monthly: monthly, weeks: weeks)
    }
}
