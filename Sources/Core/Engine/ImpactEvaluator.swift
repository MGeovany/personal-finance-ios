import Foundation

/// Builds both plans and subtracts them.
///
/// This is the single place the app's central sentence comes from — "this moves
/// your date by X days" — so every screen showing a consequence, from the expense
/// sheet to the subscription list, gets the same number by the same route.
struct ImpactEvaluator: ImpactEvaluating {
    private let planBuilding: PlanBuilding
    private let scenarioApplying: ScenarioApplying
    private let calendar: Calendar

    init(
        planBuilding: PlanBuilding = PlanBuilder(),
        scenarioApplying: ScenarioApplying = ScenarioApplier(),
        calendar: Calendar = Calendar.current
    ) {
        self.planBuilding = planBuilding
        self.scenarioApplying = scenarioApplying
        self.calendar = calendar
    }

    func evaluate(_ mutations: [ScenarioMutation], against request: PlanRequest) -> ScenarioResult {
        let current = planBuilding.build(request)
        let simulated = planBuilding.build(scenarioApplying.apply(mutations, to: request))

        return ScenarioResult(current: current, simulated: simulated, impact: delta(from: current, to: simulated))
    }

    private func delta(from current: FinancialPlan, to simulated: FinancialPlan) -> PlanImpact {
        PlanImpact(
            baselineDate: current.freedomDate,
            newDate: simulated.freedomDate,
            daysEarlier: daysEarlier(from: current.freedomDate, to: simulated.freedomDate),
            interestSaved: current.totalInterest - simulated.totalInterest,
            baselineWeeklyBudget: current.weekly.averageWeekly,
            newWeeklyBudget: simulated.weekly.averageWeekly,
            baselineExtraPayment: current.allocation.extraDebtPayment,
            newExtraPayment: simulated.allocation.extraDebtPayment,
            breaksPlan: !simulated.isFeasible && current.isFeasible
        )
    }

    /// Positive when the new date is sooner. A plan that stops paying off at all
    /// counts as no movement rather than a nonsense number; `breaksPlan` carries
    /// that information instead.
    private func daysEarlier(from baseline: Date?, to new: Date?) -> Int {
        guard let baseline, let new else { return 0 }
        return calendar.days(from: new, to: baseline)
    }
}
