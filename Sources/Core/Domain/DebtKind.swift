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

    /// The rates setup offers for this kind of debt, as annual percentages.
    ///
    /// Almost nobody knows their interest rate, and sending them to find a statement
    /// is how setup gets abandoned. These are the rates such debts actually carry in
    /// Honduras, offered as a choice so a plausible plan can be built now and
    /// corrected later from the real number.
    var typicalRates: [Double] {
        switch self {
        case .creditCard: [45, 55, 65]
        case .instalments: [25, 35, 45]
        case .personalLoan: [16, 22, 30]
        case .carLoan: [11, 14, 18]
        case .familyLoan: [0]
        case .other: [0, 15, 25]
        }
    }

    /// The rate assumed until the user says otherwise: the middle of the range,
    /// which is the least wrong guess available.
    var assumedRate: Double {
        typicalRates[typicalRates.count / 2]
    }

    /// The share of the balance a monthly payment usually is, used to suggest a
    /// minimum payment once the balance is known.
    ///
    /// Cards state a minimum as a percentage of the balance; instalment debts state
    /// a fixed payment, which for a typical term works out to a similar fraction.
    var typicalPaymentShare: Double {
        switch self {
        case .creditCard: 0.05
        case .instalments: 0.09
        case .personalLoan: 0.05
        case .carLoan: 0.03
        case .familyLoan: 0.10
        case .other: 0.05
        }
    }

    /// What the kind is called when it is the only one of its sort, which is what
    /// setup names it before the user has a chance to be more specific.
    var suggestedName: String {
        switch self {
        case .creditCard: "Tarjeta"
        case .personalLoan: "Préstamo"
        case .carLoan: "Carro"
        case .instalments: "Cuotas"
        case .familyLoan: "Préstamo familiar"
        case .other: "Otra deuda"
        }
    }

    /// Plausible balances as shares of monthly income, for setup to turn into choices.
    var balanceShares: [(label: String, share: Double)] {
        switch self {
        case .creditCard:
            [
                ("Poco", 0.4),
                ("Un mes de sueldo", 1.0),
                ("Bastante", 2.0),
                ("Se me fue de las manos", 3.5),
            ]
        case .personalLoan:
            [
                ("Pequeño", 1.5),
                ("Normal", 3.0),
                ("Grande", 6.0),
            ]
        case .carLoan:
            [
                ("Casi terminado", 2.0),
                ("A mitad", 6.0),
                ("Recién empezado", 12.0),
            ]
        case .instalments:
            [
                ("Una compra", 0.5),
                ("Varias compras", 1.5),
                ("Bastante", 3.0),
            ]
        case .familyLoan, .other:
            [
                ("Poco", 0.5),
                ("Un mes de sueldo", 1.0),
                ("Bastante", 2.5),
            ]
        }
    }
}
