import SwiftUI

/// Currency, salary and any other income.
struct OnboardingIncomeStep: View {
    @Bindable var model: OnboardingViewModel
    let dependencies: AppDependencies

    @State private var editing: ChargeDraft?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    Picker("Moneda principal", selection: $model.draft.currency) {
                        ForEach(CurrencyCode.allCases) { currency in
                            Text("\(currency.symbol) · \(currency.displayName)").tag(currency)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    MoneyField(
                        title: "Ingreso mensual",
                        amount: $model.draft.primaryIncome,
                        currency: model.draft.currency
                    )
                }
            }

            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Otros ingresos", actionTitle: "Agregar") {
                    editing = ChargeDraft(currency: model.draft.currency)
                }

                if model.draft.otherIncomes.isEmpty {
                    Text("Trabajos por cuenta propia, alquileres, comisiones. Opcional.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                } else {
                    ForEach(model.draft.otherIncomes) { income in
                        ChargeSummaryRow(
                            charge: income,
                            money: dependencies.money,
                            onDelete: { model.draft.otherIncomes.removeAll { $0.id == income.id } }
                        )
                    }
                }
            }

            if model.draft.totalMonthlyIncome > 0 {
                DetailRow(
                    label: "Total mensual",
                    value: dependencies.money.string(model.draft.totalMonthlyIncome, currency: model.draft.currency),
                    tint: Palette.accent
                )
            }
        }
        .sheet(item: $editing) { draft in
            ChargeEditorSheet(
                purpose: .income,
                draft: draft,
                currencies: CurrencyCode.allCases
            ) { saved in
                model.draft.otherIncomes.append(saved)
            }
        }
    }
}
