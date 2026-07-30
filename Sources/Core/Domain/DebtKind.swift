import Foundation

/// The shape of an obligation. Revolving debts have a limit and available
/// credit; instalment debts have a fixed term.
enum DebtKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case creditCard
    case personalLoan
    case carLoan
    case instalments
    case familyLoan
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .creditCard: "Tarjeta de crédito"
        case .personalLoan: "Préstamo personal"
        case .carLoan: "Préstamo de vehículo"
        case .instalments: "Compra a cuotas"
        case .familyLoan: "Deuda familiar"
        case .other: "Otra obligación"
        }
    }

    var icon: String {
        switch self {
        case .creditCard: "creditcard"
        case .personalLoan: "building.columns"
        case .carLoan: "car"
        case .instalments: "square.stack.3d.up"
        case .familyLoan: "person.2"
        case .other: "doc.text"
        }
    }

    /// Only revolving debts expose a credit limit, and that limit must never be
    /// presented to the user as money they have.
    var isRevolving: Bool {
        self == .creditCard || self == .instalments
    }
}
