import Foundation
import Observation

/// Drives the setup flow: which question is showing, what the draft holds, and when
/// it is complete enough to save.
///
/// The flow is not a fixed list of screens. Steps that would ask about something the
/// user has already ruled out are dropped from the path, so somebody with no debts
/// and no commitments walks a visibly shorter setup than somebody with both — and
/// the progress bar tells the truth for each of them.
@MainActor
@Observable
final class OnboardingViewModel {
    private let committer: OnboardingCommitting
    private let preferences: PlanPreferencing

    var draft = OnboardingDraft()
    private(set) var step: OnboardingStep = .welcome
    /// Which way the last move went, so the frame can slide the right way.
    private(set) var isMovingForward = true
    /// Set once the draft is saved, which is what hands control to plan selection.
    private(set) var hasFinished = false

    init(committer: OnboardingCommitting, preferences: PlanPreferencing) {
        self.committer = committer
        self.preferences = preferences
    }

    // MARK: - The path

    /// The steps this particular user will actually see.
    var path: [OnboardingStep] {
        OnboardingStep.allCases.filter(isRelevant)
    }

    private func isRelevant(_ step: OnboardingStep) -> Bool {
        switch step {
        case .debtAmounts:
            !draft.debts.isEmpty
        default:
            true
        }
    }

    /// Position in the progress bar, counting only the questions.
    var progress: (index: Int, total: Int) {
        let questions = path.filter(\.countsTowardProgress)
        let index = questions.firstIndex(of: step).map { $0 + 1 } ?? questions.count
        return (index, questions.count)
    }

    // MARK: - Navigation

    /// Whether the current question has an answer good enough to move on.
    var canAdvance: Bool {
        switch step {
        case .name: !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        case .income: draft.primaryIncome > 0
        case .commitmentAmounts: draft.commitmentsMissingAmounts.isEmpty
        case .debtAmounts: draft.debts.allSatisfy(\.isValid)
        default: true
        }
    }

    /// Why the user cannot move on yet, shown under the button rather than as an
    /// error, because they have not done anything wrong — they are not done.
    var blockedReason: String? {
        guard !canAdvance else { return nil }
        switch step {
        case .name:
            return nil
        case .income:
            return "Necesitamos tu ingreso mensual para calcular cualquier plan."
        case .commitmentAmounts:
            let missing = draft.commitmentsMissingAmounts
            guard let first = missing.first else { return nil }
            return missing.count == 1
                ? "Falta el monto de \(first.label.lowercased())."
                : "Faltan \(missing.count) montos."
        case .debtAmounts:
            return "Cada deuda necesita al menos su saldo."
        default:
            return nil
        }
    }

    var advanceTitle: String {
        switch step {
        case .welcome: "Empezar"
        case .review: "Ver mis planes"
        default: isCurrentStepEmpty ? "Omitir" : "Continuar"
        }
    }

    func advance() {
        guard let next = step(after: step) else {
            finish()
            return
        }
        isMovingForward = true
        step = next
    }

    func goBack() {
        guard let previous = step(before: step) else { return }
        isMovingForward = false
        step = previous
    }

    /// Moves on because a question was answered rather than because Continue was
    /// pressed. The pause is what makes the choice register: the mark fills in, and
    /// only then does the screen change.
    func advanceAfterAnswer() {
        guard step.advancesOnAnswer, canAdvance else { return }
        let answered = step
        Task {
            try? await Task.sleep(for: .milliseconds(320))
            // The user may have moved themselves, or changed their answer, while the
            // pause was running.
            guard step == answered else { return }
            advance()
        }
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
        isMovingForward = true
        hasFinished = false
    }

    private func step(after current: OnboardingStep) -> OnboardingStep? {
        let path = path
        guard let index = path.firstIndex(of: current), index + 1 < path.count else { return nil }
        return path[index + 1]
    }

    private func step(before current: OnboardingStep) -> OnboardingStep? {
        let path = path
        guard let index = path.firstIndex(of: current), index > 0 else { return nil }
        return path[index - 1]
    }

    // MARK: - Answers
    //
    // Kept here rather than in the views so each step view stays a layout. Anything
    // that has to stay consistent across two fields — a debt's suggested minimum
    // following its balance — belongs on this side of the line.

    var greetingName: String {
        draft.name.trimmingCharacters(in: .whitespaces)
    }

    func setCurrency(_ currency: CurrencyCode) {
        draft.currency = currency
    }

    // MARK: Commitments

    func toggle(_ template: CommitmentTemplate) {
        if draft.commitments.contains(template) {
            draft.commitments.remove(template)
            draft.commitmentAmounts[template] = nil
        } else {
            draft.commitments.insert(template)
        }
    }

    func amount(for template: CommitmentTemplate) -> Money {
        draft.commitmentAmounts[template] ?? 0
    }

    func setAmount(_ amount: Money, for template: CommitmentTemplate) {
        draft.commitmentAmounts[template] = amount
    }

    func addCustomCommitment(_ charge: ChargeDraft) {
        draft.customCommitments.append(charge)
    }

    func removeCustomCommitment(_ charge: ChargeDraft) {
        draft.customCommitments.removeAll { $0.id == charge.id }
    }

    // MARK: Income

    func addOtherIncome(_ charge: ChargeDraft) {
        draft.otherIncomes.append(charge)
    }

    func removeOtherIncome(_ charge: ChargeDraft) {
        draft.otherIncomes.removeAll { $0.id == charge.id }
    }

    // MARK: Lifestyle

    func baseline(for key: String) -> Money {
        draft.categoryBaselines[key] ?? 0
    }

    func setBaseline(_ amount: Money, for key: String) {
        draft.categoryBaselines[key] = amount
    }

    // MARK: Debts

    /// Ticking a kind of debt creates it already filled in with the rate such debts
    /// usually carry, so the amounts step only has to ask for the balance.
    func toggle(_ kind: DebtKind) {
        if let existing = draft.debts.first(where: { $0.kind == kind }) {
            draft.debts.removeAll { $0.id == existing.id }
        } else {
            draft.hasNoDebts = false
            draft.debts.append(
                DebtDraft(
                    name: kind.suggestedName,
                    kind: kind,
                    currency: draft.currency,
                    annualRatePercent: kind.assumedRate
                )
            )
        }
    }

    func hasDebt(ofKind kind: DebtKind) -> Bool {
        draft.debts.contains { $0.kind == kind }
    }

    func declareNoDebts() {
        draft.debts.removeAll()
        draft.hasNoDebts = true
    }

    /// Keeps the suggested minimum payment in step with the balance until the user
    /// types a minimum of their own, at which point theirs is left alone.
    func setBalance(_ balance: Money, for debt: DebtDraft) {
        update(debt) { updated in
            let suggested = Self.suggestedMinimum(for: updated.balance, kind: updated.kind)
            let isUntouched = updated.minimumPayment == suggested || updated.minimumPayment == 0
            updated.balance = balance
            if isUntouched {
                updated.minimumPayment = Self.suggestedMinimum(for: balance, kind: updated.kind)
            }
        }
    }

    func setRate(_ percent: Double, for debt: DebtDraft) {
        update(debt) { $0.annualRatePercent = percent }
    }

    func setMinimum(_ amount: Money, for debt: DebtDraft) {
        update(debt) { $0.minimumPayment = amount }
    }

    private static func suggestedMinimum(for balance: Money, kind: DebtKind) -> Money {
        guard balance > 0 else { return 0 }
        return balance.scaled(by: kind.typicalPaymentShare).rounded
    }

    private func update(_ debt: DebtDraft, _ change: (inout DebtDraft) -> Void) {
        guard let index = draft.debts.firstIndex(where: { $0.id == debt.id }) else { return }
        change(&draft.debts[index])
    }

    // MARK: Goals

    func toggle(_ template: GoalTemplate) {
        if let existing = draft.goals.first(where: { $0.name == template.label }) {
            draft.goals.removeAll { $0.id == existing.id }
        } else {
            draft.hasNoGoals = false
            draft.goals.append(
                GoalDraft(
                    name: template.label,
                    icon: template.icon,
                    currency: draft.currency
                )
            )
        }
    }

    func hasGoal(_ template: GoalTemplate) -> Bool {
        draft.goals.contains { $0.name == template.label }
    }

    func setTarget(_ amount: Money, for goal: GoalDraft) {
        guard let index = draft.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        draft.goals[index].targetAmount = amount
    }

    func declareNoGoals() {
        draft.goals.removeAll()
        draft.hasNoGoals = true
    }

    // MARK: - Skipping

    /// Whether the current question is still unanswered, which turns "Continuar"
    /// into "Omitir" so skipping never feels like a mistake.
    private var isCurrentStepEmpty: Bool {
        switch step {
        case .commitments: draft.commitments.isEmpty
        case .commitmentAmounts:
            draft.commitments.isEmpty && draft.customCommitments.isEmpty
        case .groceries: baseline(for: CategoryKeys.groceries) == 0
        case .transport: baseline(for: CategoryKeys.transport) == 0
        case .outings: baseline(for: CategoryKeys.outings) == 0
        case .debtKinds: draft.debts.isEmpty && !draft.hasNoDebts
        case .savings: draft.emergencyFund == 0 && draft.savings == 0
        case .goals: draft.goals.isEmpty && !draft.hasNoGoals
        default: false
        }
    }
}
