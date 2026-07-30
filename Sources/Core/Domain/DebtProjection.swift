import Foundation

/// One month of the simulated payoff, kept so the UI can chart progress and the
/// monthly close can compare plan against reality.
struct ProjectedMonth: Identifiable, Equatable, Sendable {
    let index: Int
    let date: Date
    let startingBalance: Money
    let interestCharged: Money
    let totalPaid: Money
    let endingBalance: Money
    /// Debts that hit zero during this month.
    let debtsClearedIDs: [UUID]

    var id: Int { index }
    var principalPaid: Money { (totalPaid - interestCharged).nonNegative }
}

/// The result of simulating a payoff month by month.
struct DebtProjection: Equatable, Sendable {
    /// Months until every debt is at zero. Nil when the payment does not keep up
    /// with interest and the debt never clears.
    let monthsToFreedom: Int?
    let freedomDate: Date?
    let totalInterest: Money
    let totalPaid: Money
    /// When each debt individually reaches zero.
    let payoffDateByDebt: [UUID: Date]
    /// The order debts were cleared in, which is the plan's attack order.
    let payoffOrder: [UUID]
    let months: [ProjectedMonth]

    var isFeasible: Bool { monthsToFreedom != nil }

    /// The debt receiving the extra payment right now.
    var nextTargetDebtID: UUID? { payoffOrder.first }

    static var debtFree: DebtProjection {
        DebtProjection(
            monthsToFreedom: 0,
            freedomDate: nil,
            totalInterest: 0,
            totalPaid: 0,
            payoffDateByDebt: [:],
            payoffOrder: [],
            months: []
        )
    }
}
