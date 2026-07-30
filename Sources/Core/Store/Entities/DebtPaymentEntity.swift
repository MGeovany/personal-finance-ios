import Foundation
import SwiftData

/// A payment made against a debt.
@Model
final class DebtPaymentEntity {
    var amount: Money
    var date: Date
    var note: String
    /// Whether this was the plan's recommended payment or something the user
    /// decided on the spot. Used by the monthly close to compare plan to reality.
    var wasRecommended: Bool
    var debt: DebtEntity?

    init(amount: Money, date: Date = Date(), note: String = "", wasRecommended: Bool = false) {
        self.amount = amount
        self.date = date
        self.note = note
        self.wasRecommended = wasRecommended
    }
}
