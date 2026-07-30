import Foundation
import SwiftData

/// A utility with its own reserve: electricity, water, internet, phone.
///
/// Utilities are estimated in advance and reconciled with the real bill, so they
/// never touch the flexible budget. Whatever the estimate over-reserved is a real
/// surplus the user gets to place.
@Model
final class UtilityEntity {
    var uuid: UUID
    var name: String
    var icon: String
    /// What the app sets aside each period before the bill arrives.
    var estimatedAmount: Money
    var currencyRaw: String
    var frequencyRaw: String
    var dueDay: Int?
    var isActive: Bool
    var order: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \UtilityReadingEntity.utility)
    var readings: [UtilityReadingEntity] = []

    init(
        uuid: UUID = UUID(),
        name: String,
        icon: String = "bolt",
        estimatedAmount: Money,
        currency: CurrencyCode = .hnl,
        frequency: ChargeFrequency = .monthly,
        dueDay: Int? = nil,
        isActive: Bool = true,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.icon = icon
        self.estimatedAmount = estimatedAmount
        self.currencyRaw = currency.rawValue
        self.frequencyRaw = frequency.rawValue
        self.dueDay = dueDay
        self.isActive = isActive
        self.order = order
        self.createdAt = createdAt
    }
}

extension UtilityEntity {
    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .hnl }
        set { currencyRaw = newValue.rawValue }
    }

    var frequency: ChargeFrequency {
        get { ChargeFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    var monthlyReserve: Money { frequency.monthlyEquivalent(of: estimatedAmount) }

    func reading(forMonth key: String) -> UtilityReadingEntity? {
        readings.first { $0.monthKey == key }
    }

    /// Average of the bills actually recorded, which is a better estimate than
    /// the one the user guessed at setup.
    var historicalAverage: Money? {
        let amounts = readings.compactMap(\.actualAmount)
        guard !amounts.isEmpty else { return nil }
        return amounts.reduce(Money.zero, +) / amounts.count
    }
}
