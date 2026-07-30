import Foundation

/// Splits the available money between lifestyle, buffer, goals, extra debt
/// payment and free margin.
protocol SurplusAllocating: Sendable {
    func allocate(
        available: Money,
        snapshot: FinancialSnapshot,
        tuning: PlanTuning
    ) -> SurplusAllocation
}
