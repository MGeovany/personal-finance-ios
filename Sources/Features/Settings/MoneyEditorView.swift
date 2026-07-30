import SwiftUI

/// Edits the standing amounts: income, cushion, savings, currency.
///
/// Each save recalculates the plan, so the freedom date on the previous screen is
/// already updated by the time the user goes back.
struct MoneyEditorView: View {
    let dependencies: AppDependencies

    @State private var income: Money
    @State private var emergencyFund: Money
    @State private var savings: Money
    @State private var currency: CurrencyCode
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        let profile = dependencies.profile
        self._income = State(initialValue: profile.primaryIncome)
        self._emergencyFund = State(initialValue: profile.emergencyFund)
        self._savings = State(initialValue: profile.savings)
        self._currency = State(initialValue: profile.currency)
    }

    var body: some View {
        Form {
            Section {
                MoneyField(title: "Ingreso mensual", amount: $income, currency: currency)
            }

            Section {
                MoneyField(title: "Fondo de emergencia", amount: $emergencyFund, currency: currency)
                MoneyField(title: "Otros ahorros", amount: $savings, currency: currency)
            }

            Section {
                Picker("Moneda principal", selection: $currency) {
                    ForEach(CurrencyCode.allCases) { code in
                        Text("\(code.symbol) · \(code.displayName)").tag(code)
                    }
                }
            } footer: {
                Text("Los montos en otras monedas se convierten a tu moneda principal para calcular el plan.")
            }

            Section {
                NavigationLink {
                    IncomeListView(dependencies: dependencies)
                } label: {
                    Text("Otros ingresos")
                }
            }
        }
        .navigationTitle("Tu dinero")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar", action: save)
            }
        }
    }

    private func save() {
        let preferences = dependencies.preferences
        preferences.setPrimaryIncome(income)
        preferences.setEmergencyFund(emergencyFund)
        preferences.setSavings(savings)
        preferences.setCurrency(currency)
        dismiss()
    }
}
