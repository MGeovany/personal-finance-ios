import Foundation
import Observation

/// Drives the payment sheet: which debt, how much, and what happens when a debt
/// reaches zero.
@MainActor
@Observable
final class RegisterPaymentViewModel {
    private let debts: DebtRepositing
    private let planStore: PlanStore
    private let dateProvider: DateProviding

    var selectedDebtID: UUID?
    var amount: Money = 0
    var date: Date
    var note: String = ""

    /// Set when a payment clears a debt, which is worth marking.
    private(set) var clearedDebt: DebtEntity?
    private(set) var lastImpact: PlanImpact?

    init(debts: DebtRepositing, planStore: PlanStore, dateProvider: DateProviding = SystemDateProvider()) {
        self.debts = debts
        self.planStore = planStore
        self.dateProvider = dateProvider
        self.date = dateProvider.now

        // Opens on the debt the plan says to attack, with the amount it recommends.
        let plan = planStore.activePlan
        self.selectedDebtID = plan.nextTargetDebtID ?? debts.all().first(where: { $0.balance > 0 })?.uuid
        self.amount = plan.monthlyDebtPayment
    }

    var currency: CurrencyCode { planStore.currency }

    var payableDebts: [DebtEntity] {
        debts.all().filter { $0.status.participatesInProjection && $0.balance > 0 }
    }

    var selectedDebt: DebtEntity? {
        selectedDebtID.flatMap { debts.debt(withID: $0) }
    }

    var isRecommendedAmount: Bool {
        amount == planStore.activePlan.monthlyDebtPayment
    }

    var canSave: Bool {
        amount > 0 && selectedDebt != nil
    }

    /// True when the amount would settle the debt completely.
    var wouldClearDebt: Bool {
        guard let debt = selectedDebt else { return false }
        return amount >= debt.balance
    }

    /// The next debt in line, for the "move this payment along" offer.
    var nextDebtAfterClearing: DebtEntity? {
        let order = planStore.activePlan.attackOrder
        guard let currentID = selectedDebtID,
              let index = order.firstIndex(of: currentID),
              let nextID = order.dropFirst(index + 1).first
        else { return nil }
        return debts.debt(withID: nextID)
    }

    /// What the payment does to the plan, measured before it is written.
    var projectedImpact: PlanImpact? {
        guard amount > 0, let debtID = selectedDebtID else { return nil }
        let extra = (amount - planStore.activePlan.cashFlow.minimumPayments).nonNegative
        guard extra > 0 else { return nil }
        return planStore.impact(of: .oneTimePayment(extra, debtID: debtID)).impact
    }

    func save() {
        guard let debt = selectedDebt else { return }
        let impact = projectedImpact

        debts.registerPayment(amount, on: debt, date: date, note: note, wasRecommended: isRecommendedAmount)
        planStore.refresh()

        lastImpact = impact
        // Balance is re-read after the write: the repository decides when a debt
        // counts as settled, not this view model.
        clearedDebt = debt.balance == 0 ? debt : nil
    }

    // MARK: - What to do with a debt that reached zero

    func keepActive(_ debt: DebtEntity) {
        debt.status = .active
        finishClearing()
    }

    func markForClosure(_ debt: DebtEntity) {
        debt.status = .pendingClosure
        finishClearing()
    }

    func restrictSpending(_ debt: DebtEntity) {
        debt.status = .doNotUse
        finishClearing()
    }

    private func finishClearing() {
        debts.save()
        planStore.refresh()
        clearedDebt = nil
    }

    func dismissCelebration() {
        clearedDebt = nil
    }
}
