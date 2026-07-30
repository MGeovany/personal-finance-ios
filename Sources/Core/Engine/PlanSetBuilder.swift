import Foundation

/// Builds the same request at all three speeds, then adds the one warning that
/// can only be known by comparing them: what the slower pace costs in interest.
struct PlanSetBuilder: PlanSetBuilding {
    private let planBuilding: PlanBuilding

    init(planBuilding: PlanBuilding = PlanBuilder()) {
        self.planBuilding = planBuilding
    }

    func buildAll(from request: PlanRequest, names: [PlanSpeed: String] = [:]) -> PlanSet {
        let plans = PlanSpeed.allCases.map { speed in
            planBuilding.build(request.with(speed: speed, name: names[speed]))
        }
        return annotated(PlanSet(plans: plans))
    }

    /// Adds the cross-plan interest comparison to each plan's warnings.
    private func annotated(_ set: PlanSet) -> PlanSet {
        guard let cheapest = set.cheapest else { return set }

        let annotated = set.plans.map { plan -> FinancialPlan in
            let extra = set.extraInterest(for: plan.speed)
            guard extra > 0 else { return plan }
            return plan.appending(
                PlanWarning(kind: .extraInterest(extra, versusPlanNamed: cheapest.name), severity: .info)
            )
        }
        return PlanSet(plans: annotated)
    }
}

private extension FinancialPlan {
    func appending(_ warning: PlanWarning) -> FinancialPlan {
        FinancialPlan(
            speed: speed,
            name: name,
            strategy: strategy,
            cashFlow: cashFlow,
            allocation: allocation,
            emergency: emergency,
            projection: projection,
            weekly: weekly,
            grocery: grocery,
            goalImpacts: goalImpacts,
            difficulty: difficulty,
            attackOrder: attackOrder,
            warnings: warnings + [warning]
        )
    }
}
