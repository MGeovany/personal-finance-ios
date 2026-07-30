import Foundation

/// Decides how big the cushion should be under a plan, and whether part of the
/// savings is better spent killing expensive debt.
protocol EmergencyFundAdvising: Sendable {
    func advise(for snapshot: FinancialSnapshot, tuning: PlanTuning) -> EmergencyFundAdvice
}
