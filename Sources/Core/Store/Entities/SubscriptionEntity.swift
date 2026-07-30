import Foundation
import SwiftData

/// A recurring subscription, with the card it is charged to and enough usage
/// signal to tell the user when they are paying for something they forgot about.
@Model
final class SubscriptionEntity {
    /// Stable identity shared with the snapshot, so "cancel this subscription"
    /// in the simulator can be matched back to this row.
    var uuid: UUID
    var name: String
    var amount: Money
    var currencyRaw: String
    var frequencyRaw: String
    /// Day of the month the charge lands.
    var chargeDay: Int?
    var statusRaw: String
    /// The card or account it is charged to, so the debt screen can show it.
    var debtID: UUID?
    /// Last time the user said they used it; drives the unused-subscription hint.
    var lastUsedAt: Date?
    /// The user's own call on whether this is worth keeping. Unnecessary
    /// subscriptions stay in the plan but get surfaced as an opportunity.
    var isNecessary: Bool
    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        name: String,
        amount: Money,
        currency: CurrencyCode = .hnl,
        frequency: ChargeFrequency = .monthly,
        chargeDay: Int? = nil,
        status: SubscriptionStatus = .active,
        debtID: UUID? = nil,
        lastUsedAt: Date? = nil,
        isNecessary: Bool = true,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.amount = amount
        self.currencyRaw = currency.rawValue
        self.frequencyRaw = frequency.rawValue
        self.chargeDay = chargeDay
        self.statusRaw = status.rawValue
        self.debtID = debtID
        self.lastUsedAt = lastUsedAt
        self.isNecessary = isNecessary
        self.createdAt = createdAt
    }
}

extension SubscriptionEntity {
    var currency: CurrencyCode {
        get { CurrencyCode(rawValue: currencyRaw) ?? .hnl }
        set { currencyRaw = newValue.rawValue }
    }

    var frequency: ChargeFrequency {
        get { ChargeFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    var status: SubscriptionStatus {
        get { SubscriptionStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var monthlyCost: Money { frequency.monthlyEquivalent(of: amount) }
    var annualCost: Money { frequency.annualEquivalent(of: amount) }

    /// Charged this month, so it counts against the plan.
    var isCharging: Bool { status == .active }

    /// Nothing recorded for two months reads as "probably not using this".
    func looksUnused(now: Date, calendar: Calendar = .current) -> Bool {
        guard isCharging else { return false }
        guard let lastUsedAt else { return calendar.days(from: createdAt, to: now) > 60 }
        return calendar.days(from: lastUsedAt, to: now) > 60
    }
}
