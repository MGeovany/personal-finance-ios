import Foundation

/// Collects what the user should know about a plan, as data.
protocol PlanWarningBuilding: Sendable {
    func warnings(
        snapshot: FinancialSnapshot,
        cashFlow: CashFlow,
        allocation: SurplusAllocation,
        emergency: EmergencyFundAdvice,
        projection: DebtProjection,
        goalImpacts: [GoalImpact]
    ) -> [PlanWarning]
}
