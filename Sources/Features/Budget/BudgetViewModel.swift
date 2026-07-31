import Foundation
import Observation

/// The budget screen: what each category has, what it has used, and what changing
/// it would cost.
@MainActor
@Observable
final class BudgetViewModel {
    private let categories: CategoryRepositing
    private let progress: BudgetProgressCalculating
    private let planStore: PlanStore
    private let preferences: PlanPreferencing
    private let rebalancer: BudgetRebalancing
    private let dateProvider: DateProviding

    init(
        categories: CategoryRepositing,
        progress: BudgetProgressCalculating,
        planStore: PlanStore,
        preferences: PlanPreferencing,
        rebalancer: BudgetRebalancing = BudgetRebalancer(),
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.categories = categories
        self.progress = progress
        self.planStore = planStore
        self.preferences = preferences
        self.rebalancer = rebalancer
        self.dateProvider = dateProvider
    }

    var plan: FinancialPlan { planStore.activePlan }
    var currency: CurrencyCode { planStore.currency }
    private var now: Date { dateProvider.now }

    var monthTotal: BudgetConsumption { progress.monthTotal(plan: plan, on: now) }
    var weekTotal: BudgetConsumption { progress.weekTotal(plan: plan, on: now) }
    var weeks: [BudgetWeek] { plan.weekly.weeks }
    var currentWeekIndex: Int? { plan.weekly.week(containing: now)?.index }
    var grocery: GroceryPlan { plan.grocery }

    /// Categories with a budget this month, biggest first. Where the money goes is
    /// the first thing worth seeing.
    var consumptions: [BudgetConsumption] {
        progress.monthlyProgress(plan: plan, on: now)
            .filter { $0.budget > 0 || $0.spent > 0 }
            .sorted { $0.budget > $1.budget }
    }

    /// Categories the user consistently overspends, which the app offers to raise
    /// rather than quietly keep recommending.
    var underBudgeted: [PlanWarning] {
        plan.warnings.filter {
            if case .categoryUnderBudgeted = $0.kind { return true }
            return false
        }
    }

    func category(forKey key: String) -> CategoryEntity? {
        categories.category(forKey: key)
    }

    /// What raising or lowering a category budget does to the freedom date.
    func impact(ofSetting amount: Money, forKey key: String) -> PlanImpact {
        planStore.impact(of: .changeCategoryBudget(key: key, to: amount)).impact
    }

    // MARK: - Paying for an increase
    //
    // Raising a category has to come from somewhere. The app works out the alternative to
    // moving the date and lets the user pick, rather than deciding for them.

    /// Where the money for a bigger budget could come from, if the date is to stay put.
    func rebalance(raising key: String, to amount: Money) -> BudgetRebalance {
        rebalancer.rebalance(raising: key, to: amount, in: plan, snapshot: planStore.snapshot)
    }

    /// Takes the increase and lets the date move. The plan absorbs it on its own, since the
    /// extra debt payment is whatever survives the budgets.
    func acceptLaterDate(raising key: String, to amount: Money) {
        setBudget(amount, forKey: key)
    }

    /// Takes the increase and holds the date by pinning the offsetting cuts.
    ///
    /// The cuts are pinned rather than merely suggested, because a plan that recalculates
    /// would otherwise hand the slack straight back and the date would move anyway.
    func keepDate(raising key: String, to amount: Money, using rebalance: BudgetRebalance) {
        guard rebalance.isPossible else { return }

        for cut in rebalance.cuts {
            categories.category(forKey: cut.categoryKey)?.budgetOverride = cut.to
        }
        categories.category(forKey: key)?.budgetOverride = amount
        categories.save()
        planStore.refresh()
    }

    /// Pins a budget the user chose. Plans stop scaling it from then on.
    func setBudget(_ amount: Money, forKey key: String) {
        guard let category = categories.category(forKey: key) else { return }
        category.budgetOverride = amount
        categories.save()
        planStore.refresh()
    }

    /// Hands the category back to the plan, which will size it by speed again.
    func clearOverride(forKey key: String) {
        guard let category = categories.category(forKey: key) else { return }
        category.budgetOverride = nil
        categories.save()
        planStore.refresh()
    }

    func setBaseline(_ amount: Money, forKey key: String) {
        guard let category = categories.category(forKey: key) else { return }
        category.baseline = amount
        categories.save()
        planStore.refresh()
    }

    func addCategory(name: String, icon: String, flexibility: CategoryFlexibility, baseline: Money) {
        let order = (categories.all().map(\.order).max() ?? 0) + 1
        categories.add(
            CategoryEntity(
                key: UUID().uuidString,
                name: name,
                icon: icon,
                baseline: baseline,
                flexibility: flexibility,
                order: order
            )
        )
        planStore.refresh()
    }

    func toggleHidden(_ category: CategoryEntity) {
        category.isHidden.toggle()
        categories.save()
        planStore.refresh()
    }

    func setGroceryMode(_ mode: GroceryMode, mainShare: Double) {
        preferences.setGroceryMode(mode, mainShare: mainShare)
    }
}
