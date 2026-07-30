import SwiftUI

/// Edits one category's budget, showing the cost of the change while it is made.
///
/// This is the promise from the spec made concrete: raising outings from L1,200 to
/// L2,500 tells you, before you save, that your freedom date moves.
struct CategoryBudgetSheet: View {
    let consumption: BudgetConsumption
    let model: BudgetViewModel
    let dependencies: AppDependencies

    @State private var amount: Money
    @Environment(\.dismiss) private var dismiss

    init(consumption: BudgetConsumption, model: BudgetViewModel, dependencies: AppDependencies) {
        self.consumption = consumption
        self.model = model
        self.dependencies = dependencies
        self._amount = State(initialValue: consumption.budget)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MoneyField(title: "Presupuesto mensual", amount: $amount, currency: model.currency)
                } footer: {
                    Text("Ahora tienes \(format(consumption.budget)) y has gastado \(format(consumption.spent)).")
                }

                if amount != consumption.budget {
                    Section {
                        ImpactBadge(
                            impact: model.impact(ofSetting: amount, forKey: consumption.categoryKey),
                            dates: dependencies.dates,
                            showsInterest: true,
                            currency: model.currency,
                            money: dependencies.money
                        )
                        Text(dependencies.narrator.datedImpact(model.impact(ofSetting: amount, forKey: consumption.categoryKey)))
                            .font(Typography.caption)
                            .foregroundStyle(Palette.secondaryText)
                    } header: {
                        Text("Consecuencia")
                    }
                }

                if isPinned {
                    Section {
                        Button("Dejar que el plan lo calcule") {
                            model.clearOverride(forKey: consumption.categoryKey)
                            dismiss()
                        }
                    } footer: {
                        Text("Fijaste este presupuesto a mano, así que los planes ya no lo ajustan por velocidad.")
                    }
                }
            }
            .navigationTitle(consumption.categoryName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        model.setBudget(amount, forKey: consumption.categoryKey)
                        dismiss()
                    }
                    .disabled(amount == consumption.budget)
                }
            }
        }
    }

    private var isPinned: Bool {
        model.category(forKey: consumption.categoryKey)?.budgetOverride != nil
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: model.currency)
    }
}
