import Foundation

/// A secondary goal being entered or edited.
struct GoalDraft: Identifiable, Equatable {
    var id = UUID()
    var name: String = ""
    var icon: String = "target"
    var targetAmount: Money = 0
    var savedAmount: Money = 0
    var currency: CurrencyCode = .hnl
    var requestedMonthly: Money = 0
    var targetDate: Date?
    var mode: GoalMode = .parallel

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && targetAmount > 0
    }
}

extension GoalDraft {
    init(_ entity: GoalEntity) {
        self.init(
            id: entity.uuid,
            name: entity.name,
            icon: entity.icon,
            targetAmount: entity.targetAmount,
            savedAmount: entity.savedAmount,
            currency: entity.currency,
            requestedMonthly: entity.requestedMonthly,
            targetDate: entity.targetDate,
            mode: entity.mode
        )
    }

    func makeEntity(priority: Int) -> GoalEntity {
        GoalEntity(
            uuid: id,
            name: name,
            icon: icon,
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            currency: currency,
            requestedMonthly: requestedMonthly,
            targetDate: targetDate,
            mode: mode,
            priority: priority
        )
    }

    func apply(to entity: GoalEntity) {
        entity.name = name
        entity.icon = icon
        entity.targetAmount = targetAmount
        entity.savedAmount = savedAmount
        entity.currency = currency
        entity.requestedMonthly = requestedMonthly
        entity.targetDate = targetDate
        entity.mode = mode
    }
}

/// The goal kinds the app suggests, each with an icon so the list reads quickly.
enum GoalTemplate: String, CaseIterable, Identifiable {
    case debtFree, trip, car, emergency, computer, moving, education, event, purchase, custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .debtFree: "Dejar en 0 mis deudas"
        case .trip: "Viaje"
        case .car: "Carro"
        case .emergency: "Fondo de emergencia"
        case .computer: "Computadora"
        case .moving: "Mudanza"
        case .education: "Educación"
        case .event: "Evento"
        case .purchase: "Compra importante"
        case .custom: "Otra meta"
        }
    }

    var icon: String {
        switch self {
        case .debtFree: "equal.circle"
        case .trip: "airplane"
        case .car: "car"
        case .emergency: "shield"
        case .computer: "laptopcomputer"
        case .moving: "shippingbox"
        case .education: "book"
        case .event: "calendar"
        case .purchase: "bag"
        case .custom: "target"
        }
    }

    /// Debt freedom takes its target from what is owed; a trip asks for a typed
    /// amount rather than a guessed band.
    var usesAmountBands: Bool {
        switch self {
        case .debtFree, .trip: false
        default: true
        }
    }

    /// How to ask when the goal happens, or nothing when asking would be wrong.
    ///
    /// A trip, a car, a move, an event and a purchase all land on a day the user has
    /// in mind. A cushion and an education do not: they are ongoing, and inventing a
    /// deadline for them would be the app putting words in the user's mouth. Debt
    /// freedom has a date, but the plan is what works it out.
    var dateQuestion: String? {
        switch self {
        case .trip: "¿Cuándo es el viaje?"
        case .car: "¿Qué día piensas comprarlo?"
        case .computer: "¿Qué día piensas comprarla?"
        case .moving: "¿Qué día te mudas?"
        case .event: "¿Qué día es el evento?"
        case .purchase: "¿Qué día piensas comprarla?"
        case .debtFree, .emergency, .education, .custom: nil
        }
    }

    var asksForDate: Bool { dateQuestion != nil }
}
