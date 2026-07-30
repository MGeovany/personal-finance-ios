import Foundation

/// Measures what a decision does to the plan.
protocol ImpactEvaluating: Sendable {
    /// The difference between the plan as it stands and the plan after the
    /// mutations, without writing anything.
    func evaluate(_ mutations: [ScenarioMutation], against request: PlanRequest) -> ScenarioResult
}

extension ImpactEvaluating {
    func evaluate(_ mutation: ScenarioMutation, against request: PlanRequest) -> ScenarioResult {
        evaluate([mutation], against: request)
    }
}

/// Both plans plus the delta between them, so a simulation screen can show the
/// new numbers and the difference side by side.
struct ScenarioResult: Equatable, Sendable {
    let current: FinancialPlan
    let simulated: FinancialPlan
    let impact: PlanImpact
}
