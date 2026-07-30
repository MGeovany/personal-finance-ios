import Foundation
import Observation

/// Holds the current plan and recomputes it whenever the data changes.
///
/// Every screen reads the plan from here, so there is exactly one plan in the app
/// at any moment. Features mutate their own repository and call `refresh()`; they
/// never compute a plan themselves.
@MainActor
@Observable
final class PlanStore {
    private let assembler: SnapshotAssembling
    private let planSetBuilding: PlanSetBuilding
    private let impactEvaluating: ImpactEvaluating
    private let targetDateSolving: TargetDateSolving
    private let profiles: ProfileProviding
    private let dateProvider: DateProviding

    /// The inputs the current plan was built from. Simulations branch off this.
    private(set) var request: PlanRequest
    /// All three plans, so switching speed is instant and comparison is free.
    private(set) var planSet: PlanSet

    init(
        assembler: SnapshotAssembling,
        profiles: ProfileProviding,
        planSetBuilding: PlanSetBuilding = PlanSetBuilder(),
        impactEvaluating: ImpactEvaluating = ImpactEvaluator(),
        targetDateSolving: TargetDateSolving = TargetDateSolver(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.assembler = assembler
        self.profiles = profiles
        self.planSetBuilding = planSetBuilding
        self.impactEvaluating = impactEvaluating
        self.targetDateSolving = targetDateSolving
        self.dateProvider = dateProvider

        let request = assembler.planRequest(referenceDate: dateProvider.now)
        self.request = request
        self.planSet = planSetBuilding.buildAll(from: request, names: profiles.profile().planNames)
    }

    /// The plan the user chose to live by.
    var activePlan: FinancialPlan {
        planSet.plan(for: request.speed) ?? planSet.plans[0]
    }

    var currency: CurrencyCode { request.snapshot.currency }
    var snapshot: FinancialSnapshot { request.snapshot }

    /// Rebuilds the snapshot from storage and recalculates all three plans.
    ///
    /// Cheap enough to call after every edit: the projection is arithmetic over a
    /// handful of debts, and doing it eagerly is what keeps the freedom date on
    /// screen always true.
    func refresh() {
        request = assembler.planRequest(referenceDate: dateProvider.now)
        planSet = planSetBuilding.buildAll(from: request, names: profiles.profile().planNames)
    }

    /// What a decision would do, without writing anything.
    func impact(of mutations: [ScenarioMutation]) -> ScenarioResult {
        impactEvaluating.evaluate(mutations, against: request)
    }

    func impact(of mutation: ScenarioMutation) -> ScenarioResult {
        impact(of: [mutation])
    }

    /// The app's verdict on a date the user proposed.
    func assess(targetDate: Date) -> TargetDateAssessment {
        targetDateSolving.assess(targetDate: targetDate, request: request)
    }

    /// Extra interest a given speed costs versus the cheapest plan.
    func extraInterest(for speed: PlanSpeed) -> Money {
        planSet.extraInterest(for: speed)
    }

    func plan(for speed: PlanSpeed) -> FinancialPlan? {
        planSet.plan(for: speed)
    }
}
