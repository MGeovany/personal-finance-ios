import Foundation

/// Writes the one-sentence summary of a plan, and the sentence that describes an
/// impact. Every recommendation in the app comes with a short explanation, and
/// this is where those sentences live.
struct PlanNarrator: Sendable {
    private let money: MoneyFormatting
    private let dates: PlanDateFormatting
    private let currency: CurrencyCode

    init(money: MoneyFormatting, dates: PlanDateFormatting, currency: CurrencyCode) {
        self.money = money
        self.dates = dates
        self.currency = currency
    }

    /// The headline sentence for a plan, as shown on the comparison screen.
    func summary(for plan: FinancialPlan, extraInterest: Money) -> String {
        guard plan.projection.isFeasible else {
            return "Con este ritmo la deuda no llega a cero. Necesitas subir el pago mensual."
        }
        let horizon = dates.horizon(months: plan.monthsToFreedom)

        switch plan.speed {
        case .loose:
            let interest = extraInterest > 0 ? " y pagarías \(format(extraInterest)) más en intereses" : ""
            return "Este plan te deja más flexibilidad cada semana, pero terminarías de pagar aproximadamente \(horizon)\(interest)."
        case .balanced:
            return "Este plan te permite vivir con un presupuesto razonable y quedar libre de deudas aproximadamente \(horizon)."
        case .aggressive:
            return "Este plan requiere reducir tus gastos durante los próximos meses, pero podrías quedar libre de deudas aproximadamente \(horizon)."
        }
    }

    /// What a decision does, in one line. Used after registering an expense, on
    /// subscription rows, and in the simulator.
    func impact(_ impact: PlanImpact) -> String {
        if impact.breaksPlan {
            return "Con este cambio el plan deja de cerrar. Tendrías que ajustar otra categoría."
        }
        guard impact.movesDate else {
            return "Tu fecha estimada no cambia."
        }
        if impact.isImprovement {
            return "Adelanta tu fecha libre de deuda \(dates.days(impact.daysEarlier))."
        }
        return "Retrasa tu fecha libre de deuda \(dates.days(impact.daysLater))."
    }

    /// The fuller version, naming both dates: used where the change is the point
    /// of the screen rather than a side note.
    func datedImpact(_ impact: PlanImpact) -> String {
        guard let before = impact.baselineDate, let after = impact.newDate, impact.movesDate else {
            return self.impact(impact)
        }
        let verb = impact.isImprovement ? "adelanta" : "mueve"
        return "Esto \(verb) tu fecha libre de deuda del \(dates.dayAndMonth(before)) al \(dates.dayAndMonth(after))."
    }

    /// The app's answer to a target date the user proposed.
    func assessment(_ assessment: TargetDateAssessment, recommended: PlanDateOption?) -> String {
        if assessment.isAchievable {
            return "Para quedar libre de deudas en \(dates.month(assessment.requestedDate)) necesitarías pagar \(format(assessment.requiredMonthlyPayment)) mensuales y limitar tus gastos variables a \(format(assessment.allowedMonthlyVariable))."
        }
        guard let recommended, let date = recommended.date else {
            return "Esa fecha no es alcanzable con tus ingresos actuales, ni usando tus ahorros."
        }
        return "Esa fecha no es alcanzable ni con el ritmo más exigente. Nuestra fecha recomendada es \(dates.month(date)), con pagos de \(format(recommended.monthlyPayment)) y un presupuesto más sostenible."
    }

    private func format(_ value: Money) -> String {
        money.string(value, currency: currency)
    }
}
