import Foundation

/// An expense being entered.
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

    var isValid: Bool {
        amount > 0 && !categoryKey.isEmpty && (paymentMethod != .creditCard || debtID != nil)
    }

    /// Cash and debit leave immediately. A credit-card charge becomes debt until
    /// it is paid; the sheet no longer asks whether the money is already set aside.
    var backing: ExpenseBacking {
        paymentMethod == .creditCard ? .financed : .settled
    }

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
