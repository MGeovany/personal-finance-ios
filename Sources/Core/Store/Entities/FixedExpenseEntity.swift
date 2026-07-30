import Foundation
import SwiftData

/// A committed expense that is neither a utility nor a subscription: rent,
/// tuition, insurance.
@Model
final class FixedExpenseEntity {
    var uuid: UUID
    var name: String
    var amount: Money
    var currencyRaw: String
    var frequencyRaw: String
    var dueDay: Int?
    var isActive: Bool
    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        name: String,
        amount: Money,
        currency: CurrencyCode = .hnl,
        frequency: ChargeFrequency = .monthly,
        dueDay: Int? = nil,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.amount = amount
        self.currencyRaw = currency.rawValue
        self.frequencyRaw = frequency.rawValue
        self.dueDay = dueDay
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

extension FixedExpenseEntity {
    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .hnl }
        set { currencyRaw = newValue.rawValue }
    }

    var frequency: ChargeFrequency {
        get { ChargeFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    var monthlyAmount: Money { frequency.monthlyEquivalent(of: amount) }
}
