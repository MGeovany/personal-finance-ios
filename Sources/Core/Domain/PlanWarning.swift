import Foundation

/// Something the user should know about a plan.
///
/// Warnings carry data, not sentences: the engine stays free of language and
/// formatting, and `PlanWarningPresenter` turns each case into Spanish. That also
/// means the same warning can be phrased differently on a card and in a list.
struct PlanWarning: Identifiable, Equatable, Sendable {
    enum Severity: Int, Comparable, Sendable {
        case info, caution, critical

        static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let kind: PlanWarningKind
    let severity: Severity

    var id: String { kind.id }
}

enum PlanWarningKind: Equatable, Sendable {
    /// Income does not cover the committed expenses.
    case deficit(Money)
    /// Even at their floors, the everyday budgets do not fit.
    case budgetShortfall(Money)
    /// The payment never outruns the interest.
    case neverPaysOff
    /// Interest this plan costs above the fastest one.
    case extraInterest(Money, versusPlanNamed: String)
    /// Savings worth throwing at debt, given the rate.
    case savingsOpportunity(Money, annualRate: Double)
    /// Goals pushing the freedom date out.
    case goalsDelaying(names: [String], days: Int)
    /// Goals this plan pauses.
    case goalsPaused(count: Int)
    /// Emergency fund below what the plan recommends.
    case emergencyFundLow(gap: Money)
    /// A category the user consistently overspends.
    case categoryUnderBudgeted(name: String, suggested: Money)
    /// Card purchases with no money set aside for them.
    case unbackedCardSpending(Money)

    var id: String {
        switch self {
        case .deficit: "deficit"
        case .budgetShortfall: "shortfall"
        case .neverPaysOff: "never-pays-off"
        case .extraInterest: "extra-interest"
        case .savingsOpportunity: "savings-opportunity"
        case .goalsDelaying: "goals-delaying"
        case .goalsPaused: "goals-paused"
        case .emergencyFundLow: "emergency-low"
        case .categoryUnderBudgeted(let name, _): "category-under-\(name)"
        case .unbackedCardSpending: "unbacked-card"
        }
    }
}
