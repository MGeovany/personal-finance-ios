import Foundation
import SwiftData

/// An income stream besides the main salary: freelance work, rent, a side job.
@Model
final class IncomeEntity {
    var uuid: UUID
    var name: String
    var amount: Money
    var currencyRaw: String
    /// How often it arrives, normalised to a month by `monthlyAmount`.
    var frequencyRaw: String
    var isActive: Bool
    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        name: String,
        amount: Money,
        currency: CurrencyCode = .hnl,
        frequency: ChargeFrequency = .monthly,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.amount = amount
        self.currencyRaw = currency.rawValue
        self.frequencyRaw = frequency.rawValue
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

extension IncomeEntity {
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
