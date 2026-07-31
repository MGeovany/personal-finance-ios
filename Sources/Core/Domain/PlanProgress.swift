import Foundation

/// How the plan is actually going, as opposed to how it is supposed to go.
///
/// Every other screen shows the plan: what to pay, what is allowed, when this ends. None
/// of them answer "is this working?". That question needs history, and history is what the
/// dated ledgers now provide.
///
/// The distinction between measured and projected is kept explicit, because presenting an
/// estimate as a result is the one thing that would make this screen dishonest.
struct PlanProgress: Equatable, Sendable {
    /// When setup was finished. Nil for a store that predates the app recording it.
    let startedOn: Date?
    let daysIn: Int

    // MARK: Measured, from the ledgers

    /// Everything registered against a debt since the plan started. Exact.
    let paidToDebt: Money
    /// Everything moved into the cushion and into goals since then. Exact.
    let saved: Money
    /// What was owed when the plan started, if the app was there to see it.
    let debtAtStart: Money?
    let debtNow: Money
    /// Number of payday cycles where something was registered, out of those that passed.
    let paydaysHonoured: Int
    let paydaysPassed: Int

    // MARK: Projected, from the engine

    let freedomDate: Date?
    let monthsToFreedom: Int?
    /// Interest the plan is expected to avoid compared with paying only the minimums.
    ///
    /// A projection, not a receipt: it is about interest that has not been charged yet.
    /// Every screen that shows it has to say so.
    let interestAvoided: Money
    /// Total interest still ahead under the current plan.
    let interestAhead: Money

    /// How much of the original debt is gone, when there is a baseline to compare with.
    var debtCleared: Money? {
        guard let debtAtStart else { return nil }
        return (debtAtStart - debtNow).nonNegative
    }

    var debtClearedFraction: Double? {
        guard let debtAtStart, debtAtStart > 0, let cleared = debtCleared else { return nil }
        return min(1, (cleared / debtAtStart).doubleValue)
    }

    /// Whether there is enough history for any of this to mean something.
    var hasHistory: Bool {
        paidToDebt > 0 || saved > 0
    }

    var faithfulness: Double? {
        guard paydaysPassed > 0 else { return nil }
        return min(1, Double(paydaysHonoured) / Double(paydaysPassed))
    }
}
