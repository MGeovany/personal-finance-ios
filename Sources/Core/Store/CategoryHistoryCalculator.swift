import Foundation

/// Averages what each category actually costs, from recorded expenses.
@MainActor
protocol CategoryHistoryCalculating {
    /// Average monthly spend per category key, over the last complete months.
    func monthlyAverages(before date: Date) -> [String: Money]

    /// What one purchase in a category has typically cost, rather than the month's
    /// total. What turns a delivery budget into a number of orders.
    ///
    /// Nil until there is enough history to mean anything, so the caller can say it is
    /// using a default instead of presenting a guess as observation.
    func typicalExpense(inCategory key: String, before date: Date, minimumSamples: Int) -> Money?
}

/// Looks at the months that have already closed, not the current one: a month
/// three days in would otherwise look like a very cheap month and drag the
/// average down.
@MainActor
struct CategoryHistoryCalculator: CategoryHistoryCalculating {
    private let expenses: ExpenseRepositing
    private let calendar: Calendar
    private let monthsConsidered: Int

    init(expenses: ExpenseRepositing, calendar: Calendar = .current, monthsConsidered: Int = 3) {
        self.expenses = expenses
        self.calendar = calendar
        self.monthsConsidered = monthsConsidered
    }

    func monthlyAverages(before date: Date) -> [String: Money] {
        let currentMonthStart = calendar.startOfMonth(for: date)
        let windowStart = calendar.addingMonths(-monthsConsidered, to: currentMonthStart)

        let records = expenses.expenses(from: windowStart, to: currentMonthStart).filter(\.consumesBudget)
        guard !records.isEmpty else { return [:] }

        // Divide by the months that actually had spending, so a user who has only
        // used the app for one month is not averaged over three.
        let monthsWithData = Set(records.map { calendar.startOfMonth(for: $0.date) }).count
        let divisor = max(1, monthsWithData)

        return records
            .reduce(into: [String: Money]()) { totals, expense in
                totals[expense.categoryKey, default: 0] += expense.amount
            }
            .mapValues { ($0 / divisor).rounded }
    }

    /// Includes the current month, unlike `monthlyAverages`. A partial month is a bad
    /// sample of a monthly total but a fine sample of what one purchase costs, and
    /// waiting for the month to close would leave a new user without an answer.
    func typicalExpense(inCategory key: String, before date: Date, minimumSamples: Int = 3) -> Money? {
        let windowStart = calendar.addingMonths(-monthsConsidered, to: calendar.startOfMonth(for: date))
        let amounts = expenses.expenses(from: windowStart, to: date)
            .filter { $0.categoryKey == key && $0.consumesBudget && $0.amount > 0 }
            .map(\.amount)

        guard amounts.count >= minimumSamples else { return nil }
        return (amounts.reduce(Money.zero, +) / amounts.count).rounded
    }
}
