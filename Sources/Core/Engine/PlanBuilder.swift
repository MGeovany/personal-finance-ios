import Foundation

/// Composes the whole calculation. This type decides the *order* of the steps and
/// nothing else. Every rule lives in the collaborator that owns it, so a change
/// to how budgets are cut or debts ordered never touches this file.
struct PlanBuilder: PlanBuilding {
    private let cashFlowCalculating: CashFlowCalculating
    private let emergencyAdvising: EmergencyFundAdvising
    private let surplusAllocating: SurplusAllocating
    private let projecting: DebtProjecting
    private let prioritizerFactory: DebtPrioritizerFactory
    private let goalImpactCalculating: GoalImpactCalculating
    private let weeklySplitting: WeeklyBudgetSplitting
    private let grocerySplitting: GroceryBudgetSplitting
    private let difficultyRating: DifficultyRating
    private let warningBuilding: PlanWarningBuilding

    init(
        cashFlowCalculating: CashFlowCalculating = CashFlowCalculator(),
        emergencyAdvising: EmergencyFundAdvising = EmergencyFundAdvisor(),
        surplusAllocating: SurplusAllocating = SurplusAllocator(),
        projecting: DebtProjecting = DebtProjector(),
        prioritizerFactory: DebtPrioritizerFactory = DebtPrioritizerFactory(),
        goalImpactCalculating: GoalImpactCalculating = GoalImpactCalculator(),
        weeklySplitting: WeeklyBudgetSplitting = WeeklyBudgetSplitter(),
        grocerySplitting: GroceryBudgetSplitting = GroceryBudgetSplitter(),
        difficultyRating: DifficultyRating = DifficultyRater(),
        warningBuilding: PlanWarningBuilding = PlanWarningBuilder()
    ) {
        self.cashFlowCalculating = cashFlowCalculating
        self.emergencyAdvising = emergencyAdvising
        self.surplusAllocating = surplusAllocating
        self.projecting = projecting
        self.prioritizerFactory = prioritizerFactory
        self.goalImpactCalculating = goalImpactCalculating
        self.weeklySplitting = weeklySplitting
        self.grocerySplitting = grocerySplitting
        self.difficultyRating = difficultyRating
        self.warningBuilding = warningBuilding
    }

    func build(_ request: PlanRequest) -> FinancialPlan {
        let snapshot = request.snapshot
        let tuning = request.tuning
        let date = snapshot.referenceDate

        let emergency = emergencyAdvising.advise(for: snapshot, tuning: tuning)
        let cashFlow = cashFlowCalculating.cashFlow(for: snapshot, emergencyContribution: emergency.monthlyContribution)
        let allocation = surplusAllocating.allocate(available: cashFlow.available, snapshot: snapshot, tuning: tuning)

        let projection = projecting.project(
            debts: snapshot.debts,
            extraPayment: allocation.extraDebtPayment,
            lumpSum: request.lumpSumFromSavings,
            strategy: request.strategy,
            from: date
        )

        let weekly = weeklySplitting.split(monthly: allocation.variableSpending, containing: date)
        let grocery = grocerySplitting.split(
            monthly: allocation.categories.allocation(forKey: CategoryKeys.groceries)?.monthly ?? 0,
            mode: request.groceryMode,
            mainShare: request.groceryMainShare,
            weeks: weekly.weekCount
        )

        let goalImpacts = goalImpactCalculating.impacts(
            snapshot: snapshot,
            allocation: allocation,
            strategy: request.strategy,
            baselineProjection: projection,
            from: date
        )

        return FinancialPlan(
            speed: request.speed,
            name: request.name,
            strategy: request.strategy,
            cashFlow: cashFlow,
            allocation: allocation,
            emergency: emergency,
            projection: projection,
            weekly: weekly,
            grocery: grocery,
            goalImpacts: goalImpacts,
            difficulty: difficultyRating.rate(allocation: allocation, cashFlow: cashFlow, snapshot: snapshot),
            attackOrder: prioritizerFactory
                .prioritizer(for: request.strategy)
                .order(snapshot.activeDebts)
                .map(\.id),
            warnings: warningBuilding.warnings(
                snapshot: snapshot,
                cashFlow: cashFlow,
                allocation: allocation,
                emergency: emergency,
                projection: projection,
                goalImpacts: goalImpacts
            )
        )
    }
}
