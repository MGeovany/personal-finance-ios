import Foundation

/// A committed monthly amount with a name: rent, electricity, a subscription.
///
/// The engine does not care which of the three it is. Only that it is owed
/// before any money can be called available.
struct RecurringCharge: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    /// Amount normalised to one month, in the user's main currency.
    let monthlyAmount: Money
    /// Day of the month it is charged, when known.
    let dueDay: Int?
    /// Subscriptions the user marked as not worth keeping are still charged, but
    /// the app can show what cancelling them would buy.
    let isNecessary: Bool

    init(
        id: UUID = UUID(),
        name: String,
        monthlyAmount: Money,
        dueDay: Int? = nil,
        isNecessary: Bool = true
    ) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.dueDay = dueDay
        self.isNecessary = isNecessary
    }
}

extension Array where Element == RecurringCharge {
    var totalMonthly: Money {
        reduce(Money.zero) { $0 + $1.monthlyAmount }
    }
}
