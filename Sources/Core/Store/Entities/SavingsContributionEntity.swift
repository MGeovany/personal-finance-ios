import Foundation
import SwiftData

/// Money moved into savings, with the day it happened.
///
/// Goals and the emergency fund only ever stored a running total, which is enough to
/// draw a progress bar and not enough to answer "did you do anything since payday?".
/// Without a date, somebody who faithfully transfers to their savings account and never
/// touches a card would be nagged as though they had ignored the plan.
@Model
final class SavingsContributionEntity {
    var uuid: UUID
    var amount: Money
    var date: Date
    var destinationRaw: String
    /// Set when the destination is a goal, so the entry can be traced back to it.
    var goalID: UUID?
    var note: String

    init(
        uuid: UUID = UUID(),
        amount: Money,
        date: Date = Date(),
        destination: SavingsDestination,
        goalID: UUID? = nil,
        note: String = ""
    ) {
        self.uuid = uuid
        self.amount = amount
        self.date = date
        self.destinationRaw = destination.rawValue
        self.goalID = goalID
        self.note = note
    }
}

extension SavingsContributionEntity {
    var destination: SavingsDestination {
        get { SavingsDestination(rawValue: destinationRaw) ?? .emergencyFund }
        set { destinationRaw = newValue.rawValue }
    }
}

/// The two places savings can go. Kept separate from `SurplusDestination`, which is about
/// what to do with money left over; this is about where money that already moved landed.
enum SavingsDestination: String, CaseIterable, Codable, Sendable {
    case emergencyFund
    case goal

    var label: String {
        switch self {
        case .emergencyFund: "Fondo de emergencia"
        case .goal: "Meta"
        }
    }
}
