import Foundation

/// Cuts a monthly amount into the weeks of a month.
protocol WeeklyBudgetSplitting: Sendable {
    func split(monthly: Money, containing date: Date) -> WeeklyBudget
}
