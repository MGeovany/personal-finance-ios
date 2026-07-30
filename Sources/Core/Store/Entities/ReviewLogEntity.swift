import Foundation
import SwiftData

/// A record that the user did their daily review, or closed a week or a month.
///
/// Stored so the app never asks twice for the same period, and so the weekly and
/// monthly closes know what has already been decided.
@Model
final class ReviewLogEntity {
    /// `daily-2026-07-30`, `weekly-2026-W31`, `monthly-2026-07`.
    var key: String
    var kindRaw: String
    var completedAt: Date
    /// Whether the user confirmed they checked Wallet and their banking apps.
    var checkedExternalApps: Bool
    /// What the user chose to do with the period's leftover money.
    var surplusDestinationRaw: String?
    var surplusAmount: Money

    init(
        key: String,
        kind: ReviewKind,
        completedAt: Date = Date(),
        checkedExternalApps: Bool = false,
        surplusDestination: SurplusDestination? = nil,
        surplusAmount: Money = 0
    ) {
        self.key = key
        self.kindRaw = kind.rawValue
        self.completedAt = completedAt
        self.checkedExternalApps = checkedExternalApps
        self.surplusDestinationRaw = surplusDestination?.rawValue
        self.surplusAmount = surplusAmount
    }
}

extension ReviewLogEntity {
    var kind: ReviewKind {
        get { ReviewKind(rawValue: kindRaw) ?? .daily }
        set { kindRaw = newValue.rawValue }
    }

    var surplusDestination: SurplusDestination? {
        get { surplusDestinationRaw.flatMap(SurplusDestination.init(rawValue:)) }
        set { surplusDestinationRaw = newValue?.rawValue }
    }
}

/// The three review rhythms the app runs on.
enum ReviewKind: String, CaseIterable, Codable, Sendable {
    case daily
    case weekly
    case monthly

    var label: String {
        switch self {
        case .daily: "Revisión diaria"
        case .weekly: "Cierre semanal"
        case .monthly: "Cierre mensual"
        }
    }
}
