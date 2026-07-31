import Foundation
import Observation

/// Drives the add-expense sheet: the draft, the live impact of the amount typed,
/// and what to say once it is saved.
@MainActor
@Observable
final class AddExpenseViewModel {
    private let expenses: ExpenseRepositing
    private let categories: CategoryRepositing
    private let debts: DebtRepositing
    private let progress: BudgetProgressCalculating
    private let planStore: PlanStore
    private let dateProvider: DateProviding

    var draft: ExpenseDraft
    /// Set after saving: what the expense did to the plan.
    private(set) var outcome: Outcome?

    /// The consequences the app reports back, exactly as promised: what is left in
    /// the category, in the week and in the month, and whether the date moved.
    struct Outcome: Equatable {
        let categoryRemaining: Money
        let weekRemaining: Money
        let monthRemaining: Money
        let impact: PlanImpact
        let isWithinPlan: Bool
        let becameDebt: Bool
        let reservedAmount: Money?
    }

    init(
        expenses: ExpenseRepositing,
        categories: CategoryRepositing,
        debts: DebtRepositing,
        progress: BudgetProgressCalculating,
        planStore: PlanStore,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.expenses = expenses
        self.categories = categories
        self.debts = debts
        self.progress = progress
        self.planStore = planStore
        self.dateProvider = dateProvider
        self.draft = ExpenseDraft(currency: planStore.currency, date: dateProvider.now)
    }

    var currency: CurrencyCode { planStore.currency }
    var availableCategories: [CategoryEntity] { categories.visible() }
    /// Only accounts that may still be spent on: a card marked "no utilizar"
    /// should not be offered.
    var availableCards: [DebtEntity] {
        debts.all().filter { $0.status.allowsNewSpending && $0.kind.isRevolving }
    }

    var canSave: Bool { draft.isValid }

    /// What the plan looks like *before* saving, so the sheet can warn while the
    /// user is still deciding.
    var projectedImpact: PlanImpact? {
        guard draft.amount > 0 else { return nil }

        if draft.paymentMethod == .creditCard, let debtID = draft.debtID {
            return planStore.impact(
                of: .cardPurchase(draft.amount, debtID: debtID, backed: false)
            ).impact
        }

        // Cash spending only moves the date through the category budget it comes
        // out of, which is what raising that budget models.
        let currentBudget = planStore.activePlan.budget(forCategoryKey: draft.categoryKey)
        let spent = spentInCategory()
        guard spent + draft.amount > currentBudget else { return nil }

        return planStore.impact(
            of: .changeCategoryBudget(key: draft.categoryKey, to: spent + draft.amount)
        ).impact
    }

    func save() {
        guard canSave else { return }

        let entity = draft.makeEntity()
        expenses.add(entity)

        // An unbacked card purchase is new debt, so the balance has to move too.
        if draft.backing == .financed, let debtID = draft.debtID, let debt = debts.debt(withID: debtID) {
            debts.addCharge(draft.amount, to: debt)
        }

        let impact = projectedImpactAfterSaving()
        planStore.refresh()

        outcome = makeOutcome(impact: impact)
    }

    // MARK: - Outcome

    private func projectedImpactAfterSaving() -> PlanImpact {
        // Captured before the refresh, so it compares the plan as it was against
        // the plan as it now is.
        projectedImpact ?? .neutral
    }

    private func makeOutcome(impact: PlanImpact) -> Outcome {
        let plan = planStore.activePlan
        let now = dateProvider.now
        let category = progress.monthlyProgress(plan: plan, on: now).first { $0.categoryKey == draft.categoryKey }
        let week = progress.weekTotal(plan: plan, on: now)
        let month = progress.monthTotal(plan: plan, on: now)

        return Outcome(
            categoryRemaining: category?.remaining ?? 0,
            weekRemaining: week.remaining,
            monthRemaining: month.remaining,
            impact: impact,
            isWithinPlan: !(category?.isOverBudget ?? false) && !week.isOverBudget,
            becameDebt: draft.backing == .financed,
            reservedAmount: draft.backing == .reserved ? draft.amount : nil
        )
    }

    private func spentInCategory() -> Money {
        progress
            .monthlyProgress(plan: planStore.activePlan, on: dateProvider.now)
            .first { $0.categoryKey == draft.categoryKey }?
            .spent ?? 0
    }

    /// Prepares the sheet for another entry without closing it.
    func reset() {
        draft = ExpenseDraft(currency: planStore.currency, date: dateProvider.now)
        outcome = nil
    }
}
