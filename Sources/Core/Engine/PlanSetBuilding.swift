import Foundation

/// Builds the three comparable plans at once.
protocol PlanSetBuilding: Sendable {
    /// - Parameter names: display name per speed, since the user can rename plans.
    func buildAll(from request: PlanRequest, names: [PlanSpeed: String]) -> PlanSet
}

/// The three plans, plus the comparisons that only make sense across them.
struct PlanSet: Equatable, Sendable {
    let plans: [FinancialPlan]

    func plan(for speed: PlanSpeed) -> FinancialPlan? {
        plans.first { $0.speed == speed }
    }

    var ordered: [FinancialPlan] {
        PlanSpeed.displayOrder.compactMap { plan(for: $0) }
    }

    var recommended: FinancialPlan? { plan(for: .recommended) }

    /// The plan that pays the least interest, used as the reference when telling
    /// the user what a slower pace costs.
    var cheapest: FinancialPlan? {
        plans.filter { $0.projection.isFeasible }.min { $0.totalInterest < $1.totalInterest }
    }

    var fastest: FinancialPlan? {
        plans
            .compactMap { plan in plan.monthsToFreedom.map { (plan, $0) } }
            .min { $0.1 < $1.1 }?.0
    }

    /// Extra interest a plan costs compared with the cheapest one available.
    func extraInterest(for speed: PlanSpeed) -> Money {
        guard let plan = plan(for: speed), let cheapest, cheapest.speed != speed else { return 0 }
        return (plan.totalInterest - cheapest.totalInterest).nonNegative
    }

    /// The three dates the app always offers.
    var dateOptions: DateOptions? {
        guard let loose = plan(for: .loose),
              let balanced = plan(for: .balanced),
              let aggressive = plan(for: .aggressive)
        else { return nil }

        return DateOptions(
            fast: aggressive.dateOption(label: "Fecha rápida"),
            recommended: balanced.dateOption(label: "Fecha recomendada"),
            comfortable: loose.dateOption(label: "Fecha cómoda")
        )
    }
}

private extension FinancialPlan {
    func dateOption(label: String) -> PlanDateOption {
        PlanDateOption(
            speed: speed,
            label: label,
            date: freedomDate,
            monthlyPayment: monthlyDebtPayment,
            monthlyVariable: monthlyVariableBudget,
            difficulty: difficulty
        )
    }
}
