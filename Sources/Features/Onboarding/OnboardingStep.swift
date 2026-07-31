import Foundation

/// The setup flow, one question per screen.
///
/// Each step asks for exactly one thing and, wherever possible, answers it with a
/// tap. The order builds the arithmetic in front of the user: what comes in, what is
/// already promised, what daily life costs, what is owed. By the last screen they
/// have watched the money get spoken for rather than being handed a verdict.
enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case name
    case currency
    case income
    case commitments
    case commitmentAmounts
    case groceries
    case transport
    case outings
    case debtKinds
    case debtAmounts
    case savings
    case goals
    case reminders
    case review

    var id: Int { rawValue }

    /// The question, addressed to the user. Some are completed with their name by
    /// the view model, which is why a few end without punctuation here.
    var question: String {
        switch self {
        case .welcome: "Cero"
        case .name: "¿Cómo te llamas?"
        case .currency: "¿Cuál quieres como moneda por defecto?"
        case .income: "¿Cuánto es tu ingreso total mensual?"
        case .commitments: "¿Cuáles de estos pagas cada mes?"
        case .commitmentAmounts: "¿Cuánto pagas de cada uno?"
        case .groceries: "¿Cuánto gastas en supermercado?"
        case .transport: "¿Y en transporte?"
        case .outings: "¿Y en salidas y restaurantes?"
        case .debtKinds: "¿Qué deudas tienes?"
        case .debtAmounts: "¿Cuánto debes en cada una?"
        case .savings: "¿Tienes algo ahorrado?"
        case .goals: "¿Hay algo que quieras lograr?"
        case .reminders: "¿Te recordamos cada noche?"
        case .review: "Esto es lo que entendimos"
        }
    }

    var help: String? {
        switch self {
        case .welcome:
            "Vamos a ver cuánto debes, cuánto puedes gastar y cuándo podrías quedar libre de deudas."
        case .name:
            "Solo para saber cómo llamarte. Se queda en tu teléfono."
        case .currency:
            "Siempre vas a poder cambiar en cada monto. Esta es solo la moneda por defecto de tus planes."
        case .income:
            "Lo que recibes al mes en total, después de deducciones."
        case .commitments:
            "Marca todo lo que se te va cada mes. Los montos los preguntamos después."
        case .commitmentAmounts:
            "Un aproximado está bien. Si falta alguno, agrégalo aquí."
        case .groceries, .transport, .outings:
            "Elige lo que más se parezca. Lo vamos a corregir con tus gastos reales en pocas semanas."
        case .debtKinds:
            "Marca las que tengas. Si no tienes ninguna, dilo y seguimos."
        case .debtAmounts:
            "Elige un tamaño. Ya pusimos la tasa y el mínimo que suelen tener; cámbialos si sabes los tuyos."
        case .savings:
            "Nunca vamos a recomendarte quedarte sin colchón. Solo necesitamos saber con qué cuentas."
        case .goals:
            "Opcional. Te vamos a mostrar cuántos días te cuesta cada meta."
        case .reminders:
            "Un recordatorio en la noche para anotar lo que gastaste. Puedes apagarlo después."
        case .review:
            nil
        }
    }

    /// Steps that move on by themselves once answered, because the answer is a
    /// single tap and stopping to press Continue would only add a step.
    var advancesOnAnswer: Bool {
        switch self {
        case .currency, .transport, .outings, .savings, .reminders: true
        default: false
        }
    }

    var isFirst: Bool { self == .welcome }
    var isLast: Bool { self == .review }

    /// Steps outside the counted path: the cover and the summary are not questions.
    var countsTowardProgress: Bool { !isFirst && !isLast }
}
