import Foundation

/// Judges how hard a plan will be to live with.
protocol DifficultyRating: Sendable {
    func rate(allocation: SurplusAllocation, cashFlow: CashFlow, snapshot: FinancialSnapshot) -> PlanDifficulty
}
