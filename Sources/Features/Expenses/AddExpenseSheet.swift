import SwiftUI

/// Records an expense, then says what it cost. Not just in money, but in days.
struct AddExpenseSheet: View {
    let dependencies: AppDependencies
    @State private var model: AddExpenseViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: AddExpenseViewModel(
                expenses: dependencies.expenses,
                categories: dependencies.categories,
                debts: dependencies.debts,
                progress: BudgetProgressCalculator(expenses: dependencies.expenses),
                planStore: dependencies.planStore
            )
        )
    }

    var body: some View {
        Group {
            if let outcome = model.outcome {
                ExpenseOutcomeView(
                    outcome: outcome,
                    categoryName: categoryName,
                    amount: model.draft.amount,
                    dependencies: dependencies,
                    onAddAnother: { model.reset() },
                    onDone: { dismiss() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.canvas)
            } else {
                form
            }
        }
        .modalPresentation()
    }

    private var form: some View {
        ModalScaffold(
            title: "Agregar gasto",
            primary: ModalAction("Guardar", isEnabled: model.canSave) { model.save() }
        ) {
            CardSection {
                MoneyField(title: "Monto", amount: $model.draft.amount, currency: model.draft.currency)
                CeroTextField(title: "Comercio", text: $model.draft.merchant, placeholder: "Supermercado")
                RowDivider()
                DateRow(title: "Fecha", date: $model.draft.date)
            }

            CardSection(header: "Categoría") {
                SelectRow(
                    title: "Categoría",
                    selection: $model.draft.categoryKey,
                    options: model.availableCategories.map(\.key),
                    label: { key in model.availableCategories.first { $0.key == key }?.name ?? key },
                    icon: { key in model.availableCategories.first { $0.key == key }?.icon }
                )
            }

            CardSection(header: "Forma de pago") {
                SelectRow(
                    title: "Pagué con",
                    selection: $model.draft.paymentMethod,
                    options: PaymentMethod.allCases,
                    label: \.label,
                    icon: { $0.icon }
                )

                if model.draft.paymentMethod == .creditCard {
                    RowDivider()
                    cardPicker
                }
            }

            if model.draft.needsBackingQuestion, model.draft.debtID != nil {
                backingSection
            }

            CardSection {
                CeroToggle(title: "Es un gasto recurrente", isOn: $model.draft.isRecurring)
                RowDivider()
                CeroTextField(title: "Nota", text: $model.draft.note, placeholder: "Opcional")
            }

            if let impact = model.projectedImpact, impact.movesDate || impact.breaksPlan {
                CardSection(header: "Si registras este gasto") {
                    ImpactBadge(
                        impact: impact,
                        dates: dependencies.dates,
                        showsInterest: true,
                        currency: model.currency,
                        money: dependencies.money
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var cardPicker: some View {
        if model.availableCards.isEmpty {
            Text("No tienes tarjetas disponibles para gastar.")
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)
        } else {
            SelectRow(
                title: "Tarjeta",
                selection: Binding(
                    get: { model.draft.debtID ?? model.availableCards.first?.uuid },
                    set: { model.draft.debtID = $0 }
                ),
                options: model.availableCards.map { Optional($0.uuid) },
                label: { id in model.availableCards.first { $0.uuid == id }?.name ?? "Elegir" }
            )
        }
    }

    /// The question that keeps credit from being mistaken for money.
    private var backingSection: some View {
        CardSection(
            header: "¿Ya tienes el dinero para esta compra?",
            footer: model.draft.hasMoneySetAside
                ? "Vamos a reservar ese dinero para pagar la tarjeta antes de la fecha límite. Dejará de aparecer como disponible."
                : "Se va a sumar a tu deuda y generará intereses. Te mostramos cuánto mueve tu fecha."
        ) {
            SegmentedSelector(
                selection: $model.draft.hasMoneySetAside,
                options: [true, false],
                label: { $0 ? "Sí, ya lo tengo" : "No" }
            )
        }
    }

    private var categoryName: String {
        model.availableCategories.first { $0.key == model.draft.categoryKey }?.name ?? "esta categoría"
    }
}
