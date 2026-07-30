import Foundation

/// A secondary goal — a trip, a car, an emergency cushion — as the engine sees it.
struct GoalSnapshot: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var targetAmount: Money
    var savedAmount: Money
    /// What the user would like to put in every month, before the plan decides
    /// how much of that is affordable.
    var requestedMonthly: Money
    var targetDate: Date?
    var mode: GoalMode
    var priority: Int

    var remaining: Money { (targetAmount - savedAmount).nonNegative }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, (savedAmount / targetAmount).doubleValue)
    }

    var isComplete: Bool { savedAmount >= targetAmount && targetAmount > 0 }

    /// What this goal asks for once its mode is taken into account.
    var effectiveMonthly: Money {
        guard !isComplete else { return 0 }
        return requestedMonthly.scaled(by: mode.fundingFactor).nonNegative
    }
}
