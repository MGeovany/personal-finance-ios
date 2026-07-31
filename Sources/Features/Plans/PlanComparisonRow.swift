import Foundation

/// One line of the plan comparison table.
///
/// The comparison is defined as data so all three plans are guaranteed to show
/// the same rows in the same order. A column that silently omitted a row would
/// make the comparison dishonest.
struct PlanComparisonRow: Identifiable {
    let id: String
    let label: String
    let value: (FinancialPlan) -> String
    var isHighlighted: Bool = false

    static func all(
        money: MoneyFormatting,
        dates: PlanDateFormatting,
        currency: CurrencyCode,
        extraInterest: @escaping (PlanSpeed) -> Money
    ) -> [PlanComparisonRow] {
        func amount(_ value: Money) -> String { money.string(value, currency: currency) }

        return [
            PlanComparisonRow(
                id: "freedom-date",
                label: "Fecha libre de deudas",
                value: { plan in plan.freedomDate.map { dates.dayAndMonth($0, relativeTo: Date()) } ?? "Sin fecha" },
                isHighlighted: true
            ),
            PlanComparisonRow(
                id: "months",
                label: "Tiempo estimado",
                value: { plan in dates.horizon(months: plan.monthsToFreedom) }
            ),
            PlanComparisonRow(
                id: "monthly-payment",
                label: "Pago mensual recomendado",
                value: { plan in amount(plan.monthlyDebtPayment) },
                isHighlighted: true
            ),
            PlanComparisonRow(
                id: "monthly-variable",
                label: "Presupuesto variable mensual",
                value: { plan in amount(plan.monthlyVariableBudget) }
            ),
            PlanComparisonRow(
                id: "weekly",
                label: "Presupuesto semanal",
                value: { plan in amount(plan.weekly.averageWeekly) },
                isHighlighted: true
            ),
            PlanComparisonRow(
                id: "groceries",
                label: "Supermercado",
                value: { plan in amount(plan.budget(forCategoryKey: CategoryKeys.groceries)) }
            ),
            PlanComparisonRow(
                id: "transport",
                label: "Transporte",
                value: { plan in amount(plan.budget(forCategoryKey: CategoryKeys.transport)) }
            ),
            PlanComparisonRow(
                id: "outings",
                label: "Salidas",
                value: { plan in amount(plan.budget(forCategoryKey: CategoryKeys.outings)) }
            ),
            PlanComparisonRow(
                id: "buffer",
                label: "Imprevistos",
                value: { plan in amount(plan.allocation.buffer) }
            ),
            PlanComparisonRow(
                id: "emergency",
                label: "Fondo de emergencia recomendado",
                value: { plan in amount(plan.emergency.recommended) }
            ),
            PlanComparisonRow(
                id: "interest",
                label: "Intereses totales estimados",
                value: { plan in amount(plan.totalInterest) }
            ),
            PlanComparisonRow(
                id: "extra-interest",
                label: "Intereses de más",
                value: { plan in
                    let extra = extraInterest(plan.speed)
                    return extra > 0 ? "+" + amount(extra) : "···"
                }
            ),
            PlanComparisonRow(
                id: "after-freedom",
                label: "Disponible al terminar",
                value: { plan in amount(plan.monthlyMoneyAfterFreedom) }
            ),
            PlanComparisonRow(
                id: "goals",
                label: "Metas secundarias",
                value: { plan in
                    guard plan.allocation.goalFunding > 0 else { return "En pausa" }
                    let delayed = plan.delayedGoals.reduce(0) { $0 + $1.daysDelayed }
                    return delayed > 0
                        ? "\(amount(plan.allocation.goalFunding)) · +\(dates.days(delayed))"
                        : amount(plan.allocation.goalFunding)
                }
            ),
            PlanComparisonRow(
                id: "difficulty",
                label: "Nivel de dificultad",
                value: { plan in plan.difficulty.label }
            ),
        ]
    }
}
