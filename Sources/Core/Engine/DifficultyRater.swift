import Foundation

/// Rates a plan from two things the user will actually feel: how much their
/// everyday budgets were cut, and how much of the leftover leaves for debt.
struct DifficultyRater: DifficultyRating {
    func rate(allocation: SurplusAllocation, cashFlow: CashFlow, snapshot: FinancialSnapshot) -> PlanDifficulty {
        // A month that does not close, or budgets already at their floor with
        // money still missing, is as hard as it gets.
        if cashFlow.isDeficit || allocation.isUnderfunded { return .veryDemanding }

        let score = cutSeverity(allocation) * 0.6 + debtIntensity(allocation, cashFlow: cashFlow) * 0.4

        switch score {
        case ..<0.15: return .comfortable
        case ..<0.35: return .moderate
        case ..<0.60: return .demanding
        default: return .veryDemanding
        }
    }

    /// Weighted by baseline, so cutting a large category counts for more than
    /// cutting a small one.
    private func cutSeverity(_ allocation: SurplusAllocation) -> Double {
        let relevant = allocation.categories.filter { $0.flexibility != .buffer && $0.baseline > 0 }
        let totalBaseline = relevant.reduce(Money.zero) { $0 + $1.baseline }
        guard totalBaseline > 0 else { return 0 }

        let weightedCut = relevant.reduce(0.0) { total, category in
            total + category.cutFraction * (category.baseline / totalBaseline).doubleValue
        }
        return min(1, weightedCut)
    }

    private func debtIntensity(_ allocation: SurplusAllocation, cashFlow: CashFlow) -> Double {
        guard cashFlow.available > 0 else { return 1 }
        return min(1, (allocation.extraDebtPayment / cashFlow.available).doubleValue)
    }
}
