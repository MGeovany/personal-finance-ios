import Foundation

/// Applies hypothetical decisions to a plan request, producing a new request.
protocol ScenarioApplying: Sendable {
    func apply(_ mutations: [ScenarioMutation], to request: PlanRequest) -> PlanRequest
}

extension ScenarioApplying {
    func apply(_ mutation: ScenarioMutation, to request: PlanRequest) -> PlanRequest {
        apply([mutation], to: request)
    }
}
