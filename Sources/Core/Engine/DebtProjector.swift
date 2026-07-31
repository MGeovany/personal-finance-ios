import Foundation

/// Walks the debts forward month by month until they reach zero.
///
/// Two behaviours matter for the rest of the app:
///
/// - **Rollover.** The monthly outlay stays constant. When a debt clears, its
///   minimum keeps being paid. Into the next debt in line. The user never has to
///   redirect anything by hand.
/// - **Day-level dates.** Money is assumed to arrive evenly through the month, so
///   the payoff date lands on a day rather than a month boundary. That is what
///   makes "this brings your date nine days closer" a real number instead of a jump
///   between whole months.
struct DebtProjector: DebtProjecting {
    private let prioritizerFactory: DebtPrioritizerFactory
    private let minimumRule: MinimumPaymentRule
    private let calendar: Calendar
    /// Fifty years is far past any real plan; reaching it means the payment does
    /// not keep up with interest.
    private let maxMonths: Int

    init(
        prioritizerFactory: DebtPrioritizerFactory = DebtPrioritizerFactory(),
        minimumRule: MinimumPaymentRule = MinimumPaymentRule(),
        calendar: Calendar = Calendar.current,
        maxMonths: Int = 600
    ) {
        self.prioritizerFactory = prioritizerFactory
        self.minimumRule = minimumRule
        self.calendar = calendar
        self.maxMonths = maxMonths
    }

    func project(
        debts: [DebtSnapshot],
        extraPayment: Money,
        lumpSum: Money,
        strategy: PayoffStrategy,
        from date: Date
    ) -> DebtProjection {
        let live = debts.filter { $0.status.participatesInProjection && $0.balance > 0 }
        guard !live.isEmpty else { return .debtFree }

        let prioritizer = prioritizerFactory.prioritizer(for: strategy)
        var state = ProjectionState(debts: live, calendar: calendar)
        var pendingLumpSum = lumpSum

        for index in 0..<maxMonths {
            let monthStart = calendar.addingMonths(index, to: date)
            let startingBalance = state.totalBalance
            guard startingBalance > 0 else { break }

            let interest = state.accrueInterest()
            let month = payMonth(
                index: index,
                monthStart: monthStart,
                startingBalance: startingBalance,
                interest: interest,
                extraPayment: extraPayment,
                lumpSum: pendingLumpSum,
                prioritizer: prioritizer,
                state: &state
            )
            pendingLumpSum = 0
            state.record(month)

            if state.totalBalance <= 0 { break }
            // The payment is not outrunning the interest: this never ends.
            if month.endingBalance >= startingBalance { return state.infeasibleResult() }
        }

        return state.result()
    }

    /// Charges one month: minimums first on every live debt, then everything left
    /// onto the priority debt.
    private func payMonth(
        index: Int,
        monthStart: Date,
        startingBalance: Money,
        interest: Money,
        extraPayment: Money,
        lumpSum: Money,
        prioritizer: DebtPrioritizing,
        state: inout ProjectionState
    ) -> ProjectedMonth {
        let minimums = state.liveDebts.reduce(into: [UUID: Money]()) { result, debt in
            result[debt.id] = minimumRule.minimum(for: debt, balance: state.balance(of: debt.id))
        }
        // Constant outlay: the original total of every minimum, even the ones
        // already cleared, is what keeps the rollover automatic.
        let budget = max(state.originalMinimumTotal, minimums.values.reduce(Money.zero, +))
            + extraPayment
            + lumpSum
        var remaining = budget
        var cleared: [UUID] = []

        for debt in state.liveDebts {
            let payment = min(minimums[debt.id] ?? 0, state.balance(of: debt.id), remaining)
            remaining -= payment
            state.apply(payment: payment, to: debt.id, monthStart: monthStart, budget: budget, consumed: budget - remaining, clearedInto: &cleared)
        }

        for debt in prioritizer.order(state.liveDebts) where remaining > 0 {
            let payment = min(remaining, state.balance(of: debt.id))
            remaining -= payment
            state.apply(payment: payment, to: debt.id, monthStart: monthStart, budget: budget, consumed: budget - remaining, clearedInto: &cleared)
        }

        let paid = budget - remaining
        return ProjectedMonth(
            index: index,
            date: monthStart,
            startingBalance: startingBalance,
            interestCharged: interest,
            totalPaid: paid,
            endingBalance: state.totalBalance,
            debtsClearedIDs: cleared
        )
    }
}
