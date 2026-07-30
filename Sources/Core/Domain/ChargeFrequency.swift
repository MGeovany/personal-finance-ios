import Foundation

/// How often a charge or an income repeats. Everything the engine sees is
/// monthly, so this is the one place the conversion happens.
enum ChargeFrequency: String, CaseIterable, Codable, Identifiable, Sendable {
    case weekly
    case biweekly
    case monthly
    case bimonthly
    case quarterly
    case semiannual
    case annual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: "Semanal"
        case .biweekly: "Cada quince días"
        case .monthly: "Mensual"
        case .bimonthly: "Cada dos meses"
        case .quarterly: "Trimestral"
        case .semiannual: "Semestral"
        case .annual: "Anual"
        }
    }

    /// Charges per month. Weekly is 52/12 rather than 4, which matters over a year.
    var timesPerMonth: Double {
        switch self {
        case .weekly: 52.0 / 12.0
        case .biweekly: 26.0 / 12.0
        case .monthly: 1
        case .bimonthly: 1.0 / 2.0
        case .quarterly: 1.0 / 3.0
        case .semiannual: 1.0 / 6.0
        case .annual: 1.0 / 12.0
        }
    }

    func monthlyEquivalent(of amount: Money) -> Money {
        amount.scaled(by: timesPerMonth)
    }

    func annualEquivalent(of amount: Money) -> Money {
        amount.scaled(by: timesPerMonth * 12)
    }
}
