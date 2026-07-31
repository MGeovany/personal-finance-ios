import Foundation
import Observation

/// Drives the setup flow: which question is showing, what the draft holds, and when
/// it is complete enough to save.
///
/// The flow is not a fixed list of screens. Steps that would ask about something the
/// user has already ruled out are dropped from the path, so somebody with no debts
/// and no commitments walks a visibly shorter setup than somebody with both. And
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
        case .commitmentAmounts:
            !draft.commitments.isEmpty || !draft.customCommitments.isEmpty
        case .debtAmounts:
            !draft.debts.isEmpty || draft.wantsCreditCards
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
        case .debtAmounts:
            creditCardsReady && draft.debts.filter { $0.kind != .creditCard }.allSatisfy(\.isValid)
        default: true
        }
    }

    private var creditCardsReady: Bool {
        let cards = draft.debts.filter { $0.kind == .creditCard }
        return !draft.wantsCreditCards || (!cards.isEmpty && cards.allSatisfy(\.isValid))
    }

    /// Why the user cannot move on yet, shown under the button rather than as an
    /// error, because they have not done anything wrong. They are not done.
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
            if draft.wantsCreditCards, !draft.debts.contains(where: { $0.kind == .creditCard && $0.isValid }) {
                return "Agrega al menos una tarjeta de crédito."
            }
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
    // that has to stay consistent across two fields. A debt's suggested minimum
    // following its balance. Belongs on this side of the line.

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
            if template == .streaming { draft.streamingDetails = [] }
        } else {
            draft.commitments.insert(template)
        }
    }

    func amount(for template: CommitmentTemplate) -> Money {
        if template == .streaming, !draft.streamingDetails.isEmpty {
            return draft.streamingDetails.reduce(Money.zero) { $0 + $1.monthlyAmount }
        }
        return draft.commitmentAmounts[template] ?? 0
    }

    func setAmount(_ amount: Money, for template: CommitmentTemplate) {
        // A single total and a broken-down list are mutually exclusive answers.
        if template == .streaming, !draft.streamingDetails.isEmpty {
            draft.streamingDetails = []
        }
        draft.commitmentAmounts[template] = amount
    }

    func addStreamingDetail(_ charge: ChargeDraft) {
        draft.commitmentAmounts[.streaming] = nil
        if let index = draft.streamingDetails.firstIndex(where: { $0.id == charge.id }) {
            draft.streamingDetails[index] = charge
        } else {
            draft.streamingDetails.append(charge)
        }
    }

    func removeStreamingDetail(_ charge: ChargeDraft) {
        draft.streamingDetails.removeAll { $0.id == charge.id }
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
    ///
    /// Credit cards are the exception: the user may have several, each named, so the
    /// amounts step opens an empty list and an "add card" action instead.
    func toggle(_ kind: DebtKind) {
        if kind == .creditCard {
            if draft.wantsCreditCards || draft.debts.contains(where: { $0.kind == .creditCard }) {
                draft.wantsCreditCards = false
                draft.debts.removeAll { $0.kind == .creditCard }
            } else {
                draft.hasNoDebts = false
                draft.wantsCreditCards = true
            }
            return
        }

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
        if kind == .creditCard {
            return draft.wantsCreditCards || draft.debts.contains { $0.kind == .creditCard }
        }
        return draft.debts.contains { $0.kind == kind }
    }

    func declareNoDebts() {
        draft.debts.removeAll()
        draft.wantsCreditCards = false
        draft.hasNoDebts = true
    }

    func addCreditCard(_ card: DebtDraft) {
        draft.hasNoDebts = false
        draft.wantsCreditCards = true
        if let index = draft.debts.firstIndex(where: { $0.id == card.id }) {
            draft.debts[index] = card
        } else {
            draft.debts.append(card)
        }
    }

    func removeCreditCard(_ card: DebtDraft) {
        draft.debts.removeAll { $0.id == card.id }
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
            var goal = GoalDraft(
                name: template.label,
                icon: template.icon,
                currency: draft.currency
            )
            // Debt freedom is the sum already declared. There is nothing left to invent.
            if template == .debtFree {
                goal.targetAmount = draft.totalDebt
            }
            draft.goals.append(goal)
        }
    }

    func hasGoal(_ template: GoalTemplate) -> Bool {
        draft.goals.contains { $0.name == template.label }
    }

    func setTarget(_ amount: Money, for goal: GoalDraft) {
        guard let index = draft.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        draft.goals[index].targetAmount = amount
    }

    /// Nil clears the date, for a goal the user has in mind without a day attached.
    func setTargetDate(_ date: Date?, for goal: GoalDraft) {
        guard let index = draft.goals.firstIndex(where: { $0.id == goal.id }) else { return }
        draft.goals[index].targetDate = date
    }

    // MARK: Payday

    /// Picking a frequency fills in a sensible day for it, so the question is answered
    /// by one tap and the day below is a correction rather than a second question.
    func selectPaydayFrequency(_ frequency: PaydayFrequency) {
        guard draft.paydaySchedule?.frequency != frequency else { return }
        draft.paydaySchedule = .default(for: frequency, anchor: Date())
    }

    func setPaydayPrimaryDay(_ day: Int) {
        draft.paydaySchedule?.primaryDay = day
    }

    func setPaydaySecondaryDay(_ day: Int) {
        draft.paydaySchedule?.secondaryDay = day
    }

    func setPaydayAnchor(_ date: Date) {
        draft.paydaySchedule?.anchor = date
    }

    func clearPayday() {
        draft.paydaySchedule = nil
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
        case .debtKinds: draft.debts.isEmpty && !draft.wantsCreditCards && !draft.hasNoDebts
        case .savings: draft.emergencyFund == 0 && draft.savings == 0
        case .goals: draft.goals.isEmpty && !draft.hasNoGoals
        case .payday: draft.paydaySchedule == nil
        default: false
        }
    }
}
