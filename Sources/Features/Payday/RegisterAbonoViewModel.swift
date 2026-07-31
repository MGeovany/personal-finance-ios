import Foundation
import Observation

/// Works through the payday checklist, one movement at a time.
///
/// The list is the point. Registering a payment used to mean picking a card from a menu
/// and typing a number that was written on the card behind it. Here the next thing the
/// plan is waiting for is already selected with its amount filled in, and saving moves to
/// the one after it, so five movements are five taps rather than five forms.
@MainActor
@Observable
final class RegisterAbonoViewModel {
    private let debts: DebtRepositing
    private let savings: SavingsRepositing
    private let goals: GoalRepositing
    private let planStore: PlanStore
    private let dateProvider: DateProviding

    /// Everything the plan asked for this payday, as it stood when the sheet opened.
    private let instructions: [PaydayInstruction]
    /// Registered during this sitting. Kept apart from the instruction's own flag, which
    /// was captured before any of these saves happened.
    private var registeredHere: Set<String> = []

    private(set) var current: PaydayInstruction?
    var amount: Money = 0
    var date: Date
    /// Set after a save so the sheet can confirm what happened before moving on.
    private(set) var lastSaved: PaydayInstruction?

    init(
        instructions: [PaydayInstruction],
        debts: DebtRepositing,
        savings: SavingsRepositing,
        goals: GoalRepositing,
        planStore: PlanStore,
        dateProvider: DateProviding = SystemDateProvider()
    ) {
        self.instructions = instructions
        self.debts = debts
        self.savings = savings
        self.goals = goals
        self.planStore = planStore
        self.dateProvider = dateProvider
        self.date = dateProvider.now
        selectNext()
    }

    var currency: CurrencyCode { planStore.currency }

    /// What is still waiting, in the plan's own order.
    var pending: [PaydayInstruction] {
        instructions.filter { !$0.isRegistered && !registeredHere.contains($0.id) }
    }

    var isFinished: Bool { pending.isEmpty }

    /// Position in the list, for the "3 de 5" the sheet shows.
    var progress: (done: Int, total: Int) {
        let done = instructions.filter { $0.isRegistered || registeredHere.contains($0.id) }.count
        return (done, instructions.count)
    }

    // MARK: - Limits

    /// The most this movement can possibly be.
    ///
    /// A card cannot receive more than is owed on it, and a goal cannot take more than it
    /// still needs. The cushion has no ceiling: saving more than planned is never a
    /// mistake. The planned amount is *not* the cap, because somebody with extra money
    /// this month should be able to record paying more, which is the whole point of the
    /// app.
    var maximum: Money? {
        guard let current else { return nil }

        switch current.kind {
        case .debt(let id):
            return debts.debt(withID: id)?.balance
        case .goal(let id):
            return goals.goal(withID: id)?.remaining
        case .emergencyFund:
            return nil
        }
    }

    /// True when the user is entering more than the plan asked for. Worth saying, not
    /// worth blocking.
    var exceedsPlanned: Bool {
        guard let current else { return false }
        return amount > current.amount
    }

    var canSave: Bool {
        guard amount > 0, current != nil else { return false }
        guard let maximum else { return true }
        return amount <= maximum
    }

    // MARK: - Moving through the list

    func select(_ instruction: PaydayInstruction) {
        current = instruction
        // Prefilled with what the plan asked for, clamped in case the balance is now
        // lower than the plan's number, which happens on the last payment of a card.
        amount = maximum.map { min(instruction.amount, $0) } ?? instruction.amount
        lastSaved = nil
    }

    private func selectNext() {
        guard let next = pending.first else {
            current = nil
            return
        }
        select(next)
    }

    /// Records the current movement and moves to the next one waiting.
    ///
    /// - Returns: whether anything is still pending, so the caller knows to stay open.
    @discardableResult
    func save() -> Bool {
        guard canSave, let current else { return !isFinished }

        switch current.kind {
        case .debt(let id):
            if let debt = debts.debt(withID: id) {
                debts.registerPayment(
                    amount,
                    on: debt,
                    date: date,
                    note: "",
                    wasRecommended: amount == current.amount
                )
            }

        case .emergencyFund:
            savings.contributeToEmergencyFund(amount, on: date, note: "")

        case .goal(let id):
            if let goal = goals.goal(withID: id) {
                savings.contribute(amount, to: goal, on: date, note: "")
            }
        }

        registeredHere.insert(current.id)
        planStore.refresh()

        lastSaved = current
        let saved = current
        selectNext()
        // `selectNext` clears it, so it is put back for the confirmation line.
        lastSaved = saved

        return !isFinished
    }
}
