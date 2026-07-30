import Foundation

/// Turns engine warnings into Spanish.
///
/// Kept apart from the engine so the calculation never carries wording, and so
/// the tone can be reviewed in one file. The rule for every sentence here: state
/// the fact and what it costs, never judge the user.
struct PlanWarningPresenter: Sendable {
    private let money: MoneyFormatting
    private let dates: PlanDateFormatting
    private let currency: CurrencyCode

    init(money: MoneyFormatting, dates: PlanDateFormatting, currency: CurrencyCode) {
        self.money = money
        self.dates = dates
        self.currency = currency
    }

    func message(for warning: PlanWarning) -> String {
        switch warning.kind {
        case .deficit(let gap):
            return "Tus gastos comprometidos superan tus ingresos en \(format(gap)) al mes. Antes de elegir un plan hay que cerrar esa diferencia."

        case .budgetShortfall(let gap):
            return "Faltan \(format(gap)) para cubrir lo mínimo de tus categorías. Este ritmo todavía no es sostenible."

        case .extraInterest(let extra, let planName):
            return "A este ritmo pagarías \(format(extra)) más en intereses que con el plan \(planName)."

        case .neverPaysOff:
            return "Con el pago actual los intereses crecen más rápido que el abono. Hay que subir el pago para que la deuda baje."

        case .savingsOpportunity(let usable, let rate):
            return "Tienes \(format(usable)) en ahorros y una deuda al \(percent(rate)) anual. Abonarlos te ahorraría más de lo que ganan guardados."

        case .goalsDelaying(let names, let days):
            return "\(names.joined(separator: ", ")) retrasa tu fecha libre de deuda \(dates.days(days))."

        case .goalsPaused(let count):
            return count == 1
                ? "Este plan pausa 1 meta hasta que termines de pagar."
                : "Este plan pausa \(count) metas hasta que termines de pagar."

        case .emergencyFundLow(let gap):
            return "Tu fondo de emergencia está \(format(gap)) por debajo de lo recomendado para este plan."

        case .categoryUnderBudgeted(let name, let suggested):
            return "Tu presupuesto de \(name.lowercased()) parece demasiado bajo. ¿Quieres subirlo a \(format(suggested)) y recalcular tu fecha libre de deuda?"

        case .unbackedCardSpending(let total):
            return "Tienes \(format(total)) en compras con tarjeta sin dinero reservado. Eso ya cuenta como deuda nueva."
        }
    }

    private func format(_ value: Money) -> String {
        money.string(value, currency: currency)
    }

    private func percent(_ rate: Double) -> String {
        "\(Int((rate * 100).rounded()))%"
    }
}
