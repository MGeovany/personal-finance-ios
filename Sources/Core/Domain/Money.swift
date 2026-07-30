import Foundation

/// Every monetary amount in the app. `Decimal` avoids the rounding drift that
/// `Double` introduces when hundreds of small amounts are summed.
typealias Money = Decimal

extension Money {
    /// Clamps an amount to zero, used pervasively: a budget or a balance can be
    /// depleted but never negative.
    var nonNegative: Money { self < 0 ? 0 : self }

    var isPositive: Bool { self > 0 }

    static func / (lhs: Money, rhs: Int) -> Money {
        rhs == 0 ? 0 : lhs / Money(rhs)
    }

    func scaled(by factor: Double) -> Money {
        self * Money(factor)
    }

    /// Rounds to whole currency units. Cents add noise to numbers meant to be
    /// read at a glance, so budgets and projections are presented rounded.
    var rounded: Money {
        var result = Money()
        var value = self
        NSDecimalRound(&result, &value, 0, .plain)
        return result
    }

    var doubleValue: Double { (self as NSDecimalNumber).doubleValue }
}
