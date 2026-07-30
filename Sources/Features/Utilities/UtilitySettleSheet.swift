import SwiftUI

/// Records what a utility actually cost this month and where the leftover goes.
struct UtilitySettleSheet: View {
    let utility: UtilityEntity
    let recommendedDestination: SurplusDestination
    let money: MoneyFormatting
    let onSettle: (Money?, Bool, SurplusDestination) -> Void

    @State private var actual: Money
    @State private var paidBySomeoneElse = false
    @State private var destination: SurplusDestination
    @Environment(\.dismiss) private var dismiss

    init(
        utility: UtilityEntity,
        recommendedDestination: SurplusDestination,
        money: MoneyFormatting,
        onSettle: @escaping (Money?, Bool, SurplusDestination) -> Void
    ) {
        self.utility = utility
        self.recommendedDestination = recommendedDestination
        self.money = money
        self.onSettle = onSettle
        self._actual = State(initialValue: utility.estimatedAmount)
        self._destination = State(initialValue: recommendedDestination)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Este mes lo pagó otra persona", isOn: $paidBySomeoneElse)

                    if !paidBySomeoneElse {
                        MoneyField(title: "Monto real", amount: $actual, currency: utility.currency)
                    }
                } footer: {
                    Text("Reservaste \(money.string(utility.estimatedAmount, currency: utility.currency)) para \(utility.name.lowercased()) este mes.")
                }

                if surplus > 0 {
                    Section {
                        Picker("Destino", selection: $destination) {
                            ForEach(SurplusDestination.allCases) { option in
                                Label(option.label, systemImage: option.icon).tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } header: {
                        Text("Te sobran \(money.string(surplus, currency: utility.currency))")
                    } footer: {
                        Text(
                            destination == recommendedDestination
                                ? "Es lo que recomendamos mientras tengas deuda con intereses altos."
                                : "Puedes elegir otro destino, pero abonar a la deuda es lo que más te ahorra."
                        )
                    }
                } else if difference < 0 {
                    Section {
                        Text("La factura salió \(money.string(abs(difference), currency: utility.currency)) más alta de lo reservado. Sale del presupuesto de imprevistos.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.caution)
                    }
                }
            }
            .navigationTitle(utility.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSettle(paidBySomeoneElse ? nil : actual, paidBySomeoneElse, destination)
                        dismiss()
                    }
                }
            }
        }
    }

    /// When someone else pays, the whole reserve is free.
    private var difference: Money {
        paidBySomeoneElse ? utility.estimatedAmount : utility.estimatedAmount - actual
    }

    private var surplus: Money { difference.nonNegative }
}
