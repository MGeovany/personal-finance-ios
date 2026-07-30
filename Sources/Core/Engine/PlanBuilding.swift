import Foundation

/// Builds one complete plan from a request.
protocol PlanBuilding: Sendable {
    func build(_ request: PlanRequest) -> FinancialPlan
}
