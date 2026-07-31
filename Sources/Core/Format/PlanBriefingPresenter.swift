import Foundation

/// One line of the briefing: what it is, the number, and the sentence under it.
struct BriefingItem: Identifiable, Equatable {
    let id: String
    let icon: String
    /// The question this answers, as the user would ask it.
    let question: String
    /// The answer, big.
    let value: String
    /// The arithmetic behind the answer, or the reason for it.
    let detail: String
    /// Where the user goes to change this, when it is theirs to change.
    var editable: Editable?

    enum Editable: Equatable {
        /// A category budget, changed in the budget screen.
        case categoryBudget(key: String)
        /// The payoff strategy, changed in the debts screen.
        case strategy
    }
}

/// Writes the briefing in Spanish.
///
/// The engine produced counts; this decides how to say them. Kept apart so the tone
/// can be reviewed in one file, and so the same items can be rendered as a full screen
/// of cards or as a compact list without either copy drifting from the other.
struct PlanBriefingPresenter: Sendable {
    private let money: MoneyFormatting
    private let dates: PlanDateFormatting
    private let currency: CurrencyCode

    init(money: MoneyFormatting, dates: PlanDateFormatting, currency: CurrencyCode) {
        self.money = money
        self.dates = dates
        self.currency = currency
    }

    /// The opening card: what comes in, when this ends, and what it asks of the user.
    func opening(_ briefing: PlanBriefing, planName: String) -> BriefingItem {
        let date = briefing.freedomDate.map { dates.dayAndMonth($0, relativeTo: Date()) }

        return BriefingItem(
            id: "opening",
            icon: "flag.checkered",
            question: "Tu plan \(planName.lowercased())",
            value: date ?? "Sin fecha",
            detail: date == nil
                ? "Con lo que hay ahora la deuda no llega a cero. Vamos a ajustarlo juntos."
                : "Ganas \(format(briefing.monthlyIncome)) al mes. Si respetas los montos de las siguientes tarjetas, esa es tu fecha."
        )
    }

    /// The five answers, in the order the user asked for them. The two about debt drop
    /// out for somebody who has none, rather than showing a card that says zero.
    func items(_ briefing: PlanBriefing) -> [BriefingItem] {
        var result = [
            delivery(briefing.delivery),
            outings(briefing.outings),
            unexpected(briefing.unexpected),
        ]
        if let priority = priority(briefing) { result.append(priority) }
        if let payments = payments(briefing) { result.append(payments) }
        return result
    }

    // MARK: - 1. Delivery

    func delivery(_ allowance: PlanBriefing.OrderAllowance) -> BriefingItem {
        let price = format(allowance.assumedPrice)
        let source = allowance.priceFromHistory
            ? "Es lo que te han costado tus pedidos"
            : "Calculando \(price) por pedido"

        return BriefingItem(
            id: "delivery",
            icon: "bag",
            question: "¿Cuántos pedidos puedo hacer al mes?",
            value: allowance.orders == 1 ? "1 pedido" : "\(allowance.orders) pedidos",
            detail: allowance.orders == 0
                ? "Este plan no deja presupuesto para delivery. Puedes subirlo, y te mostramos cuántos días mueve tu fecha."
                : "\(format(allowance.monthlyBudget)) al mes. \(source).",
            editable: .categoryBudget(key: CategoryKeys.delivery)
        )
    }

    // MARK: - 2. Outings

    func outings(_ allowance: PlanBriefing.WeekendAllowance) -> BriefingItem {
        BriefingItem(
            id: "outings",
            icon: "party.popper",
            question: "¿Cuánto tengo para salir?",
            value: "\(format(allowance.perWeekend)) por fin de semana",
            detail: "\(format(allowance.monthly)) al mes, repartido en los \(allowance.weekends) fines de semana que tiene.",
            editable: .categoryBudget(key: CategoryKeys.outings)
        )
    }

    // MARK: - 3. The buffer

    func unexpected(_ amount: Money) -> BriefingItem {
        BriefingItem(
            id: "unexpected",
            icon: "exclamationmark.triangle",
            question: "¿Y para lo que no estaba planeado?",
            value: format(amount),
            detail: "Para lo que no entró en el super del mes: una medicina, jabón, una reparación. Si no lo usas, se va a tu deuda.",
            editable: .categoryBudget(key: CategoryKeys.unexpected)
        )
    }

    // MARK: - 4. Which card first

    func priority(_ briefing: PlanBriefing) -> BriefingItem? {
        guard let priority = briefing.priority else { return nil }

        return BriefingItem(
            id: "priority",
            icon: "target",
            question: "¿A cuál tarjeta le doy prioridad?",
            value: priority.name,
            detail: reason(for: priority),
            editable: .strategy
        )
    }

    private func reason(for payment: PlanBriefing.DebtPayment) -> String {
        let rate = Int((payment.annualRate * 100).rounded())
        let extra = payment.extra > 0 ? " Recibe \(format(payment.extra)) además de su mínimo." : ""

        guard rate > 0 else {
            return "Es la siguiente en tu plan.\(extra)"
        }
        return "Es la que más caro te cuesta, al \(rate)% anual. Todo lo que sobre va aquí primero.\(extra)"
    }

    // MARK: - 5. What each card gets

    func payments(_ briefing: PlanBriefing) -> BriefingItem? {
        guard briefing.hasDebt else { return nil }

        return BriefingItem(
            id: "payments",
            icon: "arrow.down.circle",
            question: "¿Cuánto le abono a cada tarjeta?",
            value: "\(format(briefing.totalMonthlyToDebt)) al mes",
            detail: briefing.payments
                .map { "\($0.name): \(format($0.monthly))" }
                .joined(separator: " · ")
        )
    }

    /// One line per debt, for the screens that show the split rather than the total.
    func paymentRows(_ briefing: PlanBriefing) -> [(payment: PlanBriefing.DebtPayment, value: String, detail: String)] {
        briefing.payments.map { payment in
            let payoff = payment.payoffDate.map { "Queda en cero el \(dates.dayAndMonth($0, relativeTo: Date()))" }
            let detail = payment.isPriority
                ? [payoff, "Mínimo \(format(payment.minimum)) más \(format(payment.extra))"].compactMap { $0 }.joined(separator: " · ")
                : [payoff, "Solo el mínimo"].compactMap { $0 }.joined(separator: " · ")

            return (payment, format(payment.monthly), detail)
        }
    }

    private func format(_ value: Money) -> String {
        amount(value)
    }

    /// Formatting an amount is needed by the payday instructions too, which are built in
    /// an extension, so this one is not private.
    func amount(_ value: Money) -> String {
        money.string(value, currency: currency)
    }
}
