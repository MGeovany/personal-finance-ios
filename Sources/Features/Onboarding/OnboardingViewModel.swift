import Foundation
import Observation

/// Drives the setup flow: which step is showing, what the draft holds, and when
/// it is complete enough to save.
@MainActor
@Observable
final class OnboardingViewModel {
    private let committer: OnboardingCommitting
    private let preferences: PlanPreferencing

    var draft = OnboardingDraft()
    private(set) var step: OnboardingStep = .welcome
    /// Set once the draft is saved, which is what hands control to plan selection.
    private(set) var hasFinished = false

    init(committer: OnboardingCommitting, preferences: PlanPreferencing) {
        self.committer = committer
        self.preferences = preferences
    }

    // MARK: - Navigation

    var canAdvance: Bool {
        switch step {
        case .income: draft.primaryIncome > 0
        default: true
        }
    }

    var advanceTitle: String {
        switch step {
        case .welcome: "Empezar"
        case .review: "Ver mis planes"
        default: draft.isEmpty(at: step) && step.isOptional ? "Omitir" : "Continuar"
        }
    }

    func advance() {
        guard let next = step.next else {
            finish()
            return
        }
        step = next
    }

    func goBack() {
        guard let previous = step.previous else { return }
        step = previous
    }

    /// Saves the draft and marks setup done. The plan is calculated as part of
    /// committing, so the next screen already has three plans to compare.
    func finish() {
        committer.commit(draft)
        preferences.completeOnboarding()
        hasFinished = true
    }

    /// Clears the flow so it can be walked again from the beginning.
    ///
    /// Needed when the store is emptied: without this the old draft would still be
    /// here and `hasFinished` would immediately send the user past setup again.
    func restart() {
        draft = OnboardingDraft()
        step = .welcome
        hasFinished = false
    }

    // MARK: - Draft editing
    //
    // Kept here rather than in the views so each step view stays a layout.

    func addCharge(_ charge: ChargeDraft, to purpose: ChargeEditorSheet.Purpose) {
        switch purpose {
        case .income: draft.otherIncomes.append(charge)
        case .fixedExpense: draft.fixedExpenses.append(charge)
        case .utility: draft.utilities.append(charge)
        case .subscription: draft.subscriptions.append(charge)
        }
    }

    func updateCharge(_ charge: ChargeDraft, in purpose: ChargeEditorSheet.Purpose) {
        switch purpose {
        case .income: replace(charge, in: &draft.otherIncomes)
        case .fixedExpense: replace(charge, in: &draft.fixedExpenses)
        case .utility: replace(charge, in: &draft.utilities)
        case .subscription: replace(charge, in: &draft.subscriptions)
        }
    }

    func removeCharge(_ charge: ChargeDraft, from purpose: ChargeEditorSheet.Purpose) {
        switch purpose {
        case .income: draft.otherIncomes.removeAll { $0.id == charge.id }
        case .fixedExpense: draft.fixedExpenses.removeAll { $0.id == charge.id }
        case .utility: draft.utilities.removeAll { $0.id == charge.id }
        case .subscription: draft.subscriptions.removeAll { $0.id == charge.id }
        }
    }

    func upsertDebt(_ debt: DebtDraft) {
        if draft.debts.contains(where: { $0.id == debt.id }) {
            replace(debt, in: &draft.debts)
        } else {
            draft.debts.append(debt)
        }
    }

    func removeDebt(_ debt: DebtDraft) {
        draft.debts.removeAll { $0.id == debt.id }
    }

    func upsertGoal(_ goal: GoalDraft) {
        if draft.goals.contains(where: { $0.id == goal.id }) {
            replace(goal, in: &draft.goals)
        } else {
            draft.goals.append(goal)
        }
    }

    func removeGoal(_ goal: GoalDraft) {
        draft.goals.removeAll { $0.id == goal.id }
    }

    func baseline(for key: String) -> Money {
        draft.categoryBaselines[key] ?? 0
    }

    func setBaseline(_ amount: Money, for key: String) {
        draft.categoryBaselines[key] = amount
    }

    private func replace<T: Identifiable>(_ element: T, in array: inout [T]) where T.ID == UUID {
        guard let index = array.firstIndex(where: { $0.id == element.id }) else { return }
        array[index] = element
    }
}

private extension OnboardingDraft {
    /// Whether the current step still has nothing in it, which turns "Continuar"
    /// into "Omitir" so skipping never feels like a mistake.
    func isEmpty(at step: OnboardingStep) -> Bool {
        switch step {
        case .fixedExpenses: fixedExpenses.isEmpty
        case .utilities: utilities.isEmpty
        case .subscriptions: subscriptions.isEmpty
        case .lifestyle: categoryBaselines.values.allSatisfy { $0 == 0 }
        case .savings: emergencyFund == 0 && savings == 0
        case .debts: debts.isEmpty
        case .goals: goals.isEmpty
        default: false
        }
    }
}
