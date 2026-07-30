import Foundation

/// What the emergency fund should look like under a given plan, and whether the
/// plan thinks part of the savings is better used against high-interest debt.
struct EmergencyFundAdvice: Equatable, Sendable {
    let current: Money
    let recommended: Money
    /// Monthly amount routed to the fund until it reaches the recommendation.
    let monthlyContribution: Money
    /// Savings the plan suggests throwing at debt, above the recommended cushion.
    let suggestedSavingsToDebt: Money
    /// Rate that justifies the suggestion, so the app can explain itself.
    let justifyingAnnualRate: Double?

    var gap: Money { (recommended - current).nonNegative }

    var isFunded: Bool { current >= recommended }

    var progress: Double {
        guard recommended > 0 else { return 1 }
        return min(1, (current / recommended).doubleValue)
    }
}
