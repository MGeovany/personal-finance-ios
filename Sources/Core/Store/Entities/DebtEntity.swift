import Foundation
import SwiftData

/// A stored debt: card, loan, instalment plan or a family arrangement.
@Model
final class DebtEntity {
    /// Stable identifier shared with `DebtSnapshot`, so plans can point back here.
    var uuid: UUID
    var name: String
    var institution: String
    var kindRaw: String
    var balance: Money
    var currencyRaw: String
    var creditLimit: Money?
    /// Annual rate as a fraction: 0.48 is 48 %.
    var annualRate: Double
    var minimumPayment: Money
    var statementDay: Int?
    var dueDay: Int?
    var statusRaw: String
    /// Position for the custom payoff strategy; zero means unpinned.
    var manualPriority: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DebtPaymentEntity.debt)
    var payments: [DebtPaymentEntity] = []

    init(
        uuid: UUID = UUID(),
        name: String,
        institution: String = "",
        kind: DebtKind = .creditCard,
        balance: Money,
        currency: CurrencyCode = .hnl,
        creditLimit: Money? = nil,
        annualRate: Double = 0,
        minimumPayment: Money = 0,
        statementDay: Int? = nil,
        dueDay: Int? = nil,
        status: DebtStatus = .active,
        manualPriority: Int = 0,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.institution = institution
        self.kindRaw = kind.rawValue
        self.balance = balance
        self.currencyRaw = currency.rawValue
        self.creditLimit = creditLimit
        self.annualRate = annualRate
        self.minimumPayment = minimumPayment
        self.statementDay = statementDay
        self.dueDay = dueDay
        self.statusRaw = status.rawValue
        self.manualPriority = manualPriority
        self.createdAt = createdAt
    }
}

extension DebtEntity {
    var kind: DebtKind {
        get { DebtKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .hnl }
        set { currencyRaw = newValue.rawValue }
    }

    var status: DebtStatus {
        get { DebtStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var availableCredit: Money? {
        guard let creditLimit, kind.isRevolving else { return nil }
        return (creditLimit - balance).nonNegative
    }

    var totalPaid: Money {
        payments.reduce(Money.zero) { $0 + $1.amount }
    }

    var sortedPayments: [DebtPaymentEntity] {
        payments.sorted { $0.date > $1.date }
    }
}
