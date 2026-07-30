import Foundation

/// Mutable bookkeeping for one run of `DebtProjector`.
///
/// Split out so the projector reads as the payment rules and this reads as the
/// accounting: balances, totals, and the day each debt reaches zero.
struct ProjectionState {
    private let debtsByID: [UUID: DebtSnapshot]
    private let order: [UUID]
    private let calendar: Calendar
    private var balances: [UUID: Money]
    private var payoffDates: [UUID: Date] = [:]
    private var payoffOrder: [UUID] = []
    private var months: [ProjectedMonth] = []
    private var totalInterest: Money = 0
    private var totalPaid: Money = 0

    let originalMinimumTotal: Money

    init(debts: [DebtSnapshot], calendar: Calendar) {
        self.calendar = calendar
        self.order = debts.map(\.id)
        self.debtsByID = Dictionary(uniqueKeysWithValues: debts.map { ($0.id, $0) })
        self.balances = Dictionary(uniqueKeysWithValues: debts.map { ($0.id, $0.balance) })
        self.originalMinimumTotal = debts.reduce(Money.zero) { $0 + $1.minimumPayment }
    }

    var totalBalance: Money {
        balances.values.reduce(Money.zero, +)
    }

    /// Debts that still owe something, carrying their current balance, in the
    /// order they were registered so results are reproducible.
    var liveDebts: [DebtSnapshot] {
        order.compactMap { id in
            guard let balance = balances[id], balance > 0, let debt = debtsByID[id] else { return nil }
            return debt.updating(balance: balance)
        }
    }

    func balance(of id: UUID) -> Money { balances[id] ?? 0 }

    /// Adds one month of interest to every live balance and returns the total charged.
    mutating func accrueInterest() -> Money {
        var charged = Money.zero
        for id in order {
            guard let balance = balances[id], balance > 0, let debt = debtsByID[id] else { continue }
            let interest = balance.scaled(by: debt.monthlyRate).nonNegative
            balances[id] = balance + interest
            charged += interest
        }
        totalInterest += charged
        return charged
    }

    /// Applies a payment and, if it clears the debt, dates the payoff inside the
    /// month in proportion to how much of the month's money it took.
    mutating func apply(
        payment: Money,
        to id: UUID,
        monthStart: Date,
        budget: Money,
        consumed: Money,
        clearedInto cleared: inout [UUID]
    ) {
        guard payment > 0, let balance = balances[id] else { return }
        let updated = (balance - payment).nonNegative
        balances[id] = updated
        totalPaid += payment

        guard updated <= 0, payoffDates[id] == nil else { return }
        payoffDates[id] = date(inside: monthStart, fraction: fraction(consumed, of: budget))
        payoffOrder.append(id)
        cleared.append(id)
    }

    mutating func record(_ month: ProjectedMonth) {
        months.append(month)
    }

    func result() -> DebtProjection {
        let allCleared = balances.values.allSatisfy { $0 <= 0 }
        return DebtProjection(
            monthsToFreedom: allCleared ? months.count : nil,
            freedomDate: allCleared ? payoffDates.values.max() : nil,
            totalInterest: totalInterest,
            totalPaid: totalPaid,
            payoffDateByDebt: payoffDates,
            payoffOrder: remainingOrder(),
            months: months
        )
    }

    /// The plan could not end: keep the numbers, drop the date.
    func infeasibleResult() -> DebtProjection {
        DebtProjection(
            monthsToFreedom: nil,
            freedomDate: nil,
            totalInterest: totalInterest,
            totalPaid: totalPaid,
            payoffDateByDebt: payoffDates,
            payoffOrder: remainingOrder(),
            months: months
        )
    }

    /// Cleared debts in the order they fell, then whatever is still outstanding.
    private func remainingOrder() -> [UUID] {
        let outstanding = order.filter { (balances[$0] ?? 0) > 0 }
        return payoffOrder + outstanding
    }

    private func fraction(_ consumed: Money, of budget: Money) -> Double {
        guard budget > 0 else { return 1 }
        return min(1, max(0, (consumed / budget).doubleValue))
    }

    private func date(inside monthStart: Date, fraction: Double) -> Date {
        let days = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        return calendar.addingDays(Int((Double(days) * fraction).rounded()), to: monthStart)
    }
}
