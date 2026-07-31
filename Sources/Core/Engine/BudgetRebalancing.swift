import Foundation

/// Where the money for a bigger budget can come from.
///
/// Raising a category has to be paid for by something. Either the freedom date moves, or
/// the same amount comes out of somewhere else. The app should not pick for the user, so it
/// works out the second option and lets them choose.
protocol BudgetRebalancing: Sendable {
    /// - Parameters:
    ///   - key: the category being raised.
    ///   - amount: what it should become.
    ///   - plan: the plan as it stands, which is where the current amounts come from.
    func rebalance(
        raising key: String,
        to amount: Money,
        in plan: FinancialPlan,
        snapshot: FinancialSnapshot
    ) -> BudgetRebalance
}

/// A way to fund a budget increase without moving the date.
struct BudgetRebalance: Equatable, Sendable {
    /// How much has to be found.
    let needed: Money
    /// The categories that would shrink, and by how much.
    let cuts: [CategoryCut]
    /// Taken out of what goals receive this month, once the categories run out of slack.
    let fromGoals: Money
    /// What could not be found anywhere. Above zero means keeping the date is not possible.
    let shortfall: Money

    var isPossible: Bool { shortfall == 0 && needed > 0 }

    var fromCategories: Money {
        cuts.reduce(Money.zero) { $0 + $1.amount }
    }

    /// Nothing to fund, because the change is not an increase.
    static let none = BudgetRebalance(needed: 0, cuts: [], fromGoals: 0, shortfall: 0)
}
