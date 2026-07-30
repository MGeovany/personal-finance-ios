import Foundation

/// An immutable picture of one debt at the moment a plan is calculated.
///
/// The engine only ever sees snapshots, never persisted entities, which is what
/// lets simulations run on hypothetical numbers without touching real data.
/// Properties are `var` so a *copy* can be adjusted; the original is never
/// mutated in place.
struct DebtSnapshot: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var institution: String
    var kind: DebtKind
    /// Balance already converted to the user's main currency.
    var balance: Money
    var creditLimit: Money?
    /// Annual interest rate as a fraction: 0.42 means 42 %.
    var annualRate: Double
    var minimumPayment: Money
    var statementDay: Int?
    var dueDay: Int?
    var status: DebtStatus
    /// Position the user pinned for the custom strategy; lower attacks first.
    var manualPriority: Int

    init(
        id: UUID = UUID(),
        name: String,
        institution: String = "",
        kind: DebtKind = .creditCard,
        balance: Money,
        creditLimit: Money? = nil,
        annualRate: Double,
        minimumPayment: Money,
        statementDay: Int? = nil,
        dueDay: Int? = nil,
        status: DebtStatus = .active,
        manualPriority: Int = 0
    ) {
        self.id = id
        self.name = name
        self.institution = institution
        self.kind = kind
        self.balance = balance
        self.creditLimit = creditLimit
        self.annualRate = annualRate
        self.minimumPayment = minimumPayment
        self.statementDay = statementDay
        self.dueDay = dueDay
        self.status = status
        self.manualPriority = manualPriority
    }

    var monthlyRate: Double { annualRate / 12 }

    /// Credit that exists but is not the user's money. Surfaced only as context
    /// on the card itself, never as spendable balance.
    var availableCredit: Money? {
        guard let creditLimit, kind.isRevolving else { return nil }
        return (creditLimit - balance).nonNegative
    }

    var utilization: Double? {
        guard let creditLimit, creditLimit > 0 else { return nil }
        return min(1, (balance / creditLimit).doubleValue)
    }

    /// One month of interest at the current balance. The cost of standing still.
    var monthlyInterestCost: Money {
        balance.scaled(by: monthlyRate).nonNegative
    }
}
