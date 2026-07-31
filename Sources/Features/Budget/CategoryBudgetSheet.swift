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
        ModalScaffold(
            title: consumption.categoryName,
            primary: ModalAction("Guardar", isEnabled: amount != consumption.budget) {
                model.setBudget(amount, forKey: consumption.categoryKey)
                dismiss()
            },
            secondary: isPinned
                ? ModalAction("Dejar que el plan lo calcule") {
                    model.clearOverride(forKey: consumption.categoryKey)
                    dismiss()
                }
                : nil
        ) {
            CardSection(
                footer: "Ahora tienes \(format(consumption.budget)) y has gastado \(format(consumption.spent))."
            ) {
                MoneyField(title: "Presupuesto mensual", amount: $amount, currency: model.currency)
            }

            if amount != consumption.budget {
                CardSection(header: "Consecuencia") {
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
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if isPinned {
                Text("Fijaste este presupuesto a mano, así que los planes ya no lo ajustan por velocidad.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .modalPresentation()
    }

    private var isPinned: Bool {
        model.category(forKey: consumption.categoryKey)?.budgetOverride != nil
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: model.currency)
    }
}
