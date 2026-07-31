import Foundation

/// How an expense was paid. The distinction matters because a card purchase is
/// not a settled expense until the money behind it exists.
enum PaymentMethod: String, CaseIterable, Codable, Identifiable, Sendable {
    case cash
    case debit
    case creditCard
    case transfer

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cash: "Efectivo"
        case .debit: "Débito"
        case .creditCard: "Tarjeta de crédito"
        case .transfer: "Transferencia"
        }
    }

    var icon: String {
        switch self {
        case .cash: "banknote"
        case .debit: "creditcard.and.123"
        case .creditCard: "creditcard"
        case .transfer: "arrow.left.arrow.right"
        }
    }

    /// Only credit-card purchases raise the question of whether the money exists.
    var requiresBackingQuestion: Bool { self == .creditCard }
}

/// Whether a card purchase has money set aside for it.
enum ExpenseBacking: String, CaseIterable, Codable, Sendable {
    /// Paid outright. Nothing to reserve.
    case settled
    /// On the card, but the money is reserved and no longer spendable.
    case reserved
    /// On the card with no money behind it: this is new debt.
    case financed

    var label: String {
        switch self {
        case .settled: "Pagado"
        case .reserved: "Respaldado"
        case .financed: "Financiado"
        }
    }

    var explanation: String {
        switch self {
        case .settled: "Salió de tu dinero disponible."
        case .reserved: "El dinero está reservado para pagar la tarjeta antes de la fecha límite."
        case .financed: "Se sumó a tu deuda y generará intereses."
        }
    }
}
