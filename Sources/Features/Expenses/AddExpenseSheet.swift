import SwiftUI

/// Records an expense, then says what it cost — not just in money, but in days.
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
        NavigationStack {
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
                } else {
                    form
                }
            }
            .navigationTitle(model.outcome == nil ? "Agregar gasto" : "Registrado")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.outcome == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") { model.save() }
                            .disabled(!model.canSave)
                    }
                }
            }
        }
    }

    private var form: some View {
        Form {
            Section {
                MoneyField(title: "Monto", amount: $model.draft.amount, currency: model.draft.currency)
                TextField("Comercio", text: $model.draft.merchant)
                DatePicker("Fecha", selection: $model.draft.date, displayedComponents: .date)
            }

            Section("Categoría") {
                Picker("Categoría", selection: $model.draft.categoryKey) {
                    ForEach(model.availableCategories) { category in
                        Label(category.name, systemImage: category.icon).tag(category.key)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Forma de pago") {
                Picker("Forma de pago", selection: $model.draft.paymentMethod) {
                    ForEach(PaymentMethod.allCases) { method in
                        Label(method.label, systemImage: method.icon).tag(method)
                    }
                }
                .pickerStyle(.navigationLink)

                if model.draft.paymentMethod == .creditCard {
                    cardPicker
                }
            }

            if model.draft.needsBackingQuestion, model.draft.debtID != nil {
                backingSection
            }

            Section {
                Toggle("Es un gasto recurrente", isOn: $model.draft.isRecurring)
                TextField("Nota (opcional)", text: $model.draft.note)
            }

            if let impact = model.projectedImpact, impact.movesDate || impact.breaksPlan {
                Section {
                    ImpactBadge(
                        impact: impact,
                        dates: dependencies.dates,
                        showsInterest: true,
                        currency: model.currency,
                        money: dependencies.money
                    )
                } header: {
                    Text("Si registras este gasto")
                }
            }
        }
    }

    private var cardPicker: some View {
        Group {
            if model.availableCards.isEmpty {
                Text("No tienes tarjetas disponibles para gastar.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
            } else {
                Picker("Tarjeta", selection: Binding(
                    get: { model.draft.debtID ?? model.availableCards.first?.uuid },
                    set: { model.draft.debtID = $0 }
                )) {
                    ForEach(model.availableCards) { card in
                        Text(card.name).tag(Optional(card.uuid))
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
    }

    /// The question that keeps credit from being mistaken for money.
    private var backingSection: some View {
        Section {
            Picker("", selection: $model.draft.hasMoneySetAside) {
                Text("Sí, ya lo tengo").tag(true)
                Text("No").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        } header: {
            Text("¿Ya tienes el dinero para esta compra?")
        } footer: {
            Text(
                model.draft.hasMoneySetAside
                    ? "Vamos a reservar ese dinero para pagar la tarjeta antes de la fecha límite. Dejará de aparecer como disponible."
                    : "Se va a sumar a tu deuda y generará intereses. Te mostramos cuánto mueve tu fecha."
            )
        }
    }

    private var categoryName: String {
        model.availableCategories.first { $0.key == model.draft.categoryKey }?.name ?? "esta categoría"
    }
}
