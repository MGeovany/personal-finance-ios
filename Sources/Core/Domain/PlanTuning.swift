import Foundation

/// The knobs that turn one algorithm into three plans.
///
/// Adding a fourth speed means adding a `PlanSpeed` case and a tuning here. No
/// engine code changes.
struct PlanTuning: Equatable, Sendable {
    /// Fraction of the lifestyle the user declared that the plan funds.
    /// Above 1 means the plan is more generous than what they reported.
    let lifestyleFactor: Double
    /// Extra squeeze applied only to discretionary categories, on top of
    /// `lifestyleFactor`. Essentials are protected from this.
    let discretionaryFactor: Double
    /// Share of what remains after lifestyle that becomes the unexpected-expense
    /// buffer.
    let bufferShare: Double
    /// Share of what remains that keeps funding secondary goals.
    let goalShare: Double
    /// Share of what remains left completely unassigned, so the month has slack.
    let freeMarginShare: Double
    /// Months of essential spending the emergency fund should cover.
    let emergencyMonths: Double
    /// Whether the plan suggests draining part of savings into high-interest debt.
    let suggestsUsingSavings: Bool
    /// APR above which using savings to pay debt is clearly worth it.
    let savingsRaidAPRThreshold: Double

    /// Everything not spent on lifestyle, buffer, goals or free margin goes to
    /// debt. Derived rather than stored so the shares can never sum above 1.
    var extraDebtShare: Double {
        max(0, 1 - bufferShare - goalShare - freeMarginShare)
    }

    static func forSpeed(_ speed: PlanSpeed) -> PlanTuning {
        switch speed {
        case .loose:
            PlanTuning(
                lifestyleFactor: 1.05,
                discretionaryFactor: 1.0,
                bufferShare: 0.25,
                goalShare: 0.25,
                freeMarginShare: 0.15,
                emergencyMonths: 3.0,
                suggestsUsingSavings: false,
                savingsRaidAPRThreshold: 1.0
            )
        case .balanced:
            PlanTuning(
                lifestyleFactor: 0.90,
                discretionaryFactor: 0.75,
                bufferShare: 0.12,
                goalShare: 0.10,
                freeMarginShare: 0.05,
                emergencyMonths: 1.5,
                suggestsUsingSavings: false,
                savingsRaidAPRThreshold: 0.45
            )
        case .aggressive:
            PlanTuning(
                lifestyleFactor: 0.78,
                discretionaryFactor: 0.35,
                bufferShare: 0.06,
                goalShare: 0.0,
                freeMarginShare: 0.0,
                emergencyMonths: 0.5,
                suggestsUsingSavings: true,
                savingsRaidAPRThreshold: 0.25
            )
        }
    }
}
