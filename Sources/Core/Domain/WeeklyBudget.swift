import Foundation

/// One week's slice of the monthly budget.
struct BudgetWeek: Identifiable, Equatable, Sendable {
    let index: Int
    let start: Date
    let end: Date
    let amount: Money

    var id: Int { index }

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

/// The monthly budget cut into weeks. The parts always sum back to the whole:
/// the remainder from integer division lands on the last week rather than
/// disappearing.
struct WeeklyBudget: Equatable, Sendable {
    let monthly: Money
    let weeks: [BudgetWeek]

    var weekCount: Int { weeks.count }

    var averageWeekly: Money {
        weeks.isEmpty ? 0 : monthly / weeks.count
    }

    func week(containing date: Date) -> BudgetWeek? {
        weeks.first { $0.contains(date) }
    }

    /// Guards the invariant that the weekly slices reconstruct the month.
    var sumsToMonthly: Bool {
        weeks.reduce(Money.zero) { $0 + $1.amount } == monthly
    }

    static var empty: WeeklyBudget { WeeklyBudget(monthly: 0, weeks: []) }
}
