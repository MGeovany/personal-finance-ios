import Foundation

/// A recurring amount being entered or edited: a fixed expense, a utility or a
/// subscription.
///
/// The three are different rows in storage but identical to fill in, so they
/// share one draft and one editor rather than three near-copies.
struct ChargeDraft: Identifiable, Equatable {
    var id = UUID()
    var name: String = ""
    var amount: Money = 0
    var currency: CurrencyCode = .hnl
    var frequency: ChargeFrequency = .monthly
    var day: Int?
    /// Only meaningful for subscriptions: whether the user considers it worth keeping.
    var isNecessary: Bool = true

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }

    var monthlyAmount: Money { frequency.monthlyEquivalent(of: amount) }
}

extension ChargeDraft {
    init(_ entity: FixedExpenseEntity) {
        self.init(
            id: entity.uuid,
            name: entity.name,
            amount: entity.amount,
            currency: entity.currency,
            frequency: entity.frequency,
            day: entity.dueDay
        )
    }

    init(_ entity: UtilityEntity) {
        self.init(
            id: entity.uuid,
            name: entity.name,
            amount: entity.estimatedAmount,
            currency: entity.currency,
            frequency: entity.frequency,
            day: entity.dueDay
        )
    }

    init(_ entity: SubscriptionEntity) {
        self.init(
            id: entity.uuid,
            name: entity.name,
            amount: entity.amount,
            currency: entity.currency,
            frequency: entity.frequency,
            day: entity.chargeDay,
            isNecessary: entity.isNecessary
        )
    }
}
