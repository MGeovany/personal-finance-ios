import Foundation

/// An expense being entered.
///
/// The backing is derived rather than asked for directly: the user answers
/// "¿ya tienes el dinero?" and this turns that answer into the accounting
/// consequence.
struct ExpenseDraft: Equatable {
    var amount: Money = 0
    var currency: CurrencyCode = .hnl
    var date: Date = Date()
    var merchant: String = ""
    var categoryKey: String = CategoryKeys.groceries
    var paymentMethod: PaymentMethod = .cash
    var debtID: UUID?
    var note: String = ""
    var isRecurring: Bool = false
    var goalID: UUID?
    /// The answer to whether the money for a card purchase already exists.
    var hasMoneySetAside: Bool = true

    var isValid: Bool {
        amount > 0 && !categoryKey.isEmpty && (paymentMethod != .creditCard || debtID != nil)
    }

    /// Cash and debit leave immediately. A card purchase either consumes money the
    /// user already has — which must then be locked away — or becomes new debt.
    var backing: ExpenseBacking {
        guard paymentMethod == .creditCard else { return .settled }
        return hasMoneySetAside ? .reserved : .financed
    }

    var needsBackingQuestion: Bool { paymentMethod.requiresBackingQuestion }

    func makeEntity() -> ExpenseEntity {
        ExpenseEntity(
            amount: amount,
            currency: currency,
            date: date,
            merchant: merchant,
            categoryKey: categoryKey,
            paymentMethod: paymentMethod,
            debtID: debtID,
            note: note,
            isRecurring: isRecurring,
            goalID: goalID,
            backing: backing
        )
    }
}
