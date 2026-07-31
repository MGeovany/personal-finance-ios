import Foundation

/// The monthly payments setup offers as ready-made answers.
///
/// Asking "what do you pay every month?" with a blank form makes the user recall a
/// list from memory, and they will forget half of it. Showing the things almost
/// everybody pays turns recall into recognition: they tick what applies and the app
/// already knows which bucket each one belongs in.
enum CommitmentTemplate: String, CaseIterable, Identifiable {
    case rent
    case tuition
    case insurance
    case gym
    case electricity
    case water
    case internet
    case phone
    case tv
    case streaming
    case music
    case cloud

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rent: "Alquiler"
        case .tuition: "Colegiatura"
        case .insurance: "Seguro"
        case .gym: "Gimnasio"
        case .electricity: "Luz"
        case .water: "Agua"
        case .internet: "Internet"
        case .phone: "Teléfono"
        case .tv: "Cable"
        case .streaming: "Streaming"
        case .music: "Música"
        case .cloud: "Almacenamiento"
        }
    }

    var icon: String {
        switch self {
        case .rent: "house"
        case .tuition: "graduationcap"
        case .insurance: "lock.shield"
        case .gym: "figure.run"
        case .electricity: "bolt"
        case .water: "drop"
        case .internet: "wifi"
        case .phone: "phone"
        case .tv: "tv"
        case .streaming: "play.rectangle"
        case .music: "music.note"
        case .cloud: "icloud"
        }
    }

    /// Short guidance under the amount field when the bill is hard to pin to one
    /// figure. Electricity swings month to month, so an average is enough.
    var amountCaption: String? {
        switch self {
        case .electricity:
            "Pon un aproximado de lo que pagaste en meses anteriores."
        default:
            nil
        }
    }

    /// Where the amount ends up, which is what decides how the app treats it: a
    /// utility gets its own reserve and is settled against a real bill, a
    /// subscription is something the app may later suggest cancelling, and a fixed
    /// expense is simply taken off the top.
    var bucket: Bucket {
        switch self {
        case .rent, .tuition, .insurance, .gym: .fixedExpense
        case .electricity, .water, .internet, .phone, .tv: .utility
        case .streaming, .music, .cloud: .subscription
        }
    }

    enum Bucket: CaseIterable {
        case fixedExpense
        case utility
        case subscription

        /// The heading the amounts step groups its rows under.
        var heading: String {
            switch self {
            case .fixedExpense: "Gastos fijos"
            case .utility: "Servicios"
            case .subscription: "Suscripciones"
            }
        }
    }

    /// Presented in this order: the roof first, then the meters, then the small
    /// recurring charges, which is roughly how people remember them.
    static func all(in bucket: Bucket) -> [CommitmentTemplate] {
        allCases.filter { $0.bucket == bucket }
    }

    /// The amounts setup offers for this bill, so the user picks rather than invents.
    ///
    /// Fixed expenses are shares of income (rent scales with salary). Services and
    /// subscriptions are absolute, because a Netflix bill does not grow with pay.
    func amountChoices(income: Money, currency: CurrencyCode) -> [AmountChoice] {
        switch self {
        case .rent:
            AmountBands.shares(
                [
                    ("Comparto casa", 0.18),
                    ("Un apartamento sencillo", 0.28),
                    ("Algo cómodo", 0.38),
                    ("Se me va bastante", 0.50),
                ],
                of: income,
                currency: currency
            )
        case .tuition:
            AmountBands.shares(
                [
                    ("Una cuota pequeña", 0.06),
                    ("Lo normal", 0.12),
                    ("Varias personas", 0.20),
                ],
                of: income,
                currency: currency
            )
        case .insurance:
            AmountBands.absolute(
                [
                    ("Básico", currency.isSmallDenomination ? 25 : 500),
                    ("Normal", currency.isSmallDenomination ? 60 : 1_200),
                    ("Completo", currency.isSmallDenomination ? 120 : 2_500),
                ],
                currency: currency
            )
        case .gym:
            AmountBands.absolute(
                [
                    ("Básico", currency.isSmallDenomination ? 20 : 400),
                    ("Con clases", currency.isSmallDenomination ? 40 : 800),
                    ("Premium", currency.isSmallDenomination ? 70 : 1_400),
                ],
                currency: currency
            )
        case .electricity:
            AmountBands.absolute(
                [
                    ("Poco", currency.isSmallDenomination ? 40 : 800),
                    ("Normal", currency.isSmallDenomination ? 80 : 1_600),
                    ("Alto", currency.isSmallDenomination ? 150 : 3_000),
                ],
                currency: currency
            )
        case .water:
            AmountBands.absolute(
                [
                    ("Poco", currency.isSmallDenomination ? 10 : 200),
                    ("Normal", currency.isSmallDenomination ? 20 : 400),
                    ("Alto", currency.isSmallDenomination ? 40 : 800),
                ],
                currency: currency
            )
        case .internet:
            AmountBands.absolute(
                [
                    ("Básico", currency.isSmallDenomination ? 20 : 500),
                    ("Rápido", currency.isSmallDenomination ? 35 : 800),
                    ("Fibra", currency.isSmallDenomination ? 55 : 1_200),
                ],
                currency: currency
            )
        case .phone:
            AmountBands.absolute(
                [
                    ("Prepago", currency.isSmallDenomination ? 15 : 300),
                    ("Plan normal", currency.isSmallDenomination ? 30 : 600),
                    ("Plan alto", currency.isSmallDenomination ? 50 : 1_000),
                ],
                currency: currency
            )
        case .tv:
            AmountBands.absolute(
                [
                    ("Básico", currency.isSmallDenomination ? 15 : 350),
                    ("Con paquetes", currency.isSmallDenomination ? 30 : 700),
                    ("Premium", currency.isSmallDenomination ? 50 : 1_200),
                ],
                currency: currency
            )
        case .streaming:
            AmountBands.absolute(
                [
                    ("Una sola", currency.isSmallDenomination ? 8 : 200),
                    ("Dos o tres", currency.isSmallDenomination ? 20 : 450),
                    ("Varias", currency.isSmallDenomination ? 40 : 900),
                ],
                currency: currency
            )
        case .music:
            AmountBands.absolute(
                [
                    ("Individual", currency.isSmallDenomination ? 6 : 150),
                    ("Familiar", currency.isSmallDenomination ? 12 : 280),
                ],
                currency: currency
            )
        case .cloud:
            AmountBands.absolute(
                [
                    ("Básico", currency.isSmallDenomination ? 3 : 70),
                    ("Más espacio", currency.isSmallDenomination ? 10 : 250),
                ],
                currency: currency
            )
        }
    }
}
