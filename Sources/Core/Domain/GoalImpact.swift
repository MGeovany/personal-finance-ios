import Foundation

/// What funding a goal costs in payoff time, so the trade-off is never hidden.
struct GoalImpact: Identifiable, Equatable, Sendable {
    let goalID: UUID
    let goalName: String
    let mode: GoalMode
    let fundedMonthly: Money
    let requestedMonthly: Money
    /// Days the freedom date moves later because of this goal. Zero when paused.
    let daysDelayed: Int
    /// When the goal would be reached at this funding rate.
    let projectedCompletion: Date?

    var id: UUID { goalID }

    var isFullyFunded: Bool { fundedMonthly >= requestedMonthly }

    var delaysPlan: Bool { daysDelayed > 0 }
}
