import Foundation

/// Budget versus reality for one category over one period.
struct BudgetConsumption: Identifiable, Equatable, Sendable {
    let categoryKey: String
    let categoryName: String
    let icon: String
    let budget: Money
    let spent: Money
    /// Historical monthly average, when there is enough history to mean anything.
    let historicalAverage: Money?
    /// The next charge the app expects in this category, if any is scheduled.
    let expectedNext: Money?

    var id: String { categoryKey }

    var remaining: Money { (budget - spent).nonNegative }

    var overspent: Money { (spent - budget).nonNegative }

    var isOverBudget: Bool { spent > budget }

    var usedFraction: Double {
        guard budget > 0 else { return spent > 0 ? 1 : 0 }
        return min(1, (spent / budget).doubleValue)
    }

    /// Crosses the line where a nudge is worth sending.
    var isNearLimit: Bool { usedFraction >= 0.8 && !isOverBudget }
}
