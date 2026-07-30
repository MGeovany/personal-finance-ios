import Foundation
import SwiftData

/// What one utility actually cost in one month, and what happened to the
/// difference against the reserve.
@Model
final class UtilityReadingEntity {
    /// `yyyy-MM`, so a month can be looked up without date arithmetic.
    var monthKey: String
    var reservedAmount: Money
    var actualAmount: Money?
    /// Some months a housemate or relative covers the bill; the reserve is then
    /// entirely surplus.
    var paidBySomeoneElse: Bool
    var surplusDestinationRaw: String?
    var recordedAt: Date
    var utility: UtilityEntity?

    init(
        monthKey: String,
        reservedAmount: Money,
        actualAmount: Money? = nil,
        paidBySomeoneElse: Bool = false,
        surplusDestination: SurplusDestination? = nil,
        recordedAt: Date = Date()
    ) {
        self.monthKey = monthKey
        self.reservedAmount = reservedAmount
        self.actualAmount = actualAmount
        self.paidBySomeoneElse = paidBySomeoneElse
        self.surplusDestinationRaw = surplusDestination?.rawValue
        self.recordedAt = recordedAt
    }
}

extension UtilityReadingEntity {
    var surplusDestination: SurplusDestination? {
        get { surplusDestinationRaw.flatMap(SurplusDestination.init(rawValue:)) }
        set { surplusDestinationRaw = newValue?.rawValue }
    }

    /// Positive when the reserve was more than the bill.
    var difference: Money {
        guard !paidBySomeoneElse else { return reservedAmount }
        guard let actualAmount else { return 0 }
        return reservedAmount - actualAmount
    }

    var isSettled: Bool { actualAmount != nil || paidBySomeoneElse }
}
