import Foundation
import SwiftData

/// One recorded expense.
///
/// `backing` is the field that keeps the app honest: a card purchase with money
/// set aside behaves like cash, while one without is new debt, and the two must
/// never be counted the same way.
@Model
final class ExpenseEntity {
    var uuid: UUID
    var amount: Money
    var currencyRaw: String
    var date: Date
    var merchant: String
    var categoryKey: String
    var paymentMethodRaw: String
    /// Card or account used, when the payment method implies one.
    var debtID: UUID?
    var note: String
    var isRecurring: Bool
    /// Set when the expense is part of a goal rather than everyday spending.
    var goalID: UUID?
    var backingRaw: String
    /// Expenses imported or auto-detected start uncategorised and show up in the
    /// daily review until the user places them.
    var needsReview: Bool
    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        amount: Money,
        currency: CurrencyCode = .hnl,
        date: Date = Date(),
        merchant: String = "",
        categoryKey: String,
        paymentMethod: PaymentMethod = .cash,
        debtID: UUID? = nil,
        note: String = "",
        isRecurring: Bool = false,
        goalID: UUID? = nil,
        backing: ExpenseBacking = .settled,
        needsReview: Bool = false,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.amount = amount
        self.currencyRaw = currency.rawValue
        self.date = date
        self.merchant = merchant
        self.categoryKey = categoryKey
        self.paymentMethodRaw = paymentMethod.rawValue
        self.debtID = debtID
        self.note = note
        self.isRecurring = isRecurring
        self.goalID = goalID
        self.backingRaw = backing.rawValue
        self.needsReview = needsReview
        self.createdAt = createdAt
    }
}

extension ExpenseEntity {
    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .hnl }
        set { currencyRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        set { paymentMethodRaw = newValue.rawValue }
    }

    var backing: ExpenseBacking {
        get { ExpenseBacking(rawValue: backingRaw) ?? .settled }
        set { backingRaw = newValue.rawValue }
    }

    /// Money promised to a future statement: no longer spendable, not yet debt.
    var isReservedForCard: Bool { backing == .reserved }

    /// Counts against this month's category budget. Financed card purchases do
    /// too. The spending happened. But they also raised the debt.
    var consumesBudget: Bool { goalID == nil }
}
