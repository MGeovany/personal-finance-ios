import SwiftUI

/// The debts themselves — the step the whole app is built around.
struct OnboardingDebtsStep: View {
    @Bindable var model: OnboardingViewModel
    let dependencies: AppDependencies

    @State private var editing: DebtDraft?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            ForEach(model.draft.debts) { debt in
                DebtDraftRow(
                    debt: debt,
                    money: dependencies.money,
                    currency: model.draft.currency,
                    onTap: { editing = debt },
                    onDelete: { model.removeDebt(debt) }
                )
            }

            Button {
                editing = DebtDraft(currency: model.draft.currency)
            } label: {
                Label("Agregar deuda", systemImage: "plus")
            }
            .secondaryButton()

            if !model.draft.debts.isEmpty {
                CardContainer {
                    VStack(alignment: .leading, spacing: Layout.gap) {
                        DetailRow(
                            label: "Deuda total",
                            value: dependencies.money.string(model.draft.totalDebt, currency: model.draft.currency),
                            tint: Palette.debt
                        )
                        DetailRow(
                            label: "Pagos mínimos al mes",
                            value: dependencies.money.string(
                                model.draft.debts.reduce(Money.zero) { $0 + $1.minimumPayment },
                                currency: model.draft.currency
                            )
                        )
                    }
                }
            } else {
                Text("Si no tienes deudas, puedes omitir este paso. La app te va a servir igual para presupuestar y ahorrar.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(item: $editing) { draft in
            DebtEditorSheet(draft: draft, currencies: CurrencyCode.allCases) { saved in
                model.upsertDebt(saved)
            }
        }
    }
}

/// A debt in a list: balance, rate and minimum, which is everything needed to
/// know where it sits in the plan.
struct DebtDraftRow: View {
    let debt: DebtDraft
    let money: MoneyFormatting
    let currency: CurrencyCode
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        CardContainer(padding: Layout.gap) {
            HStack(spacing: Layout.gap) {
                Image(systemName: debt.kind.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.debt)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(debt.name)
                        .font(Typography.label)
                        .foregroundStyle(Palette.primaryText)
                    Text(detailLine)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }

                Spacer(minLength: Layout.tightGap)

                Text(money.string(debt.balance, currency: debt.currency))
                    .font(Typography.amount)
                    .foregroundStyle(Palette.primaryText)

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 17))
                            .foregroundStyle(Palette.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Eliminar \(debt.name)")
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    private var detailLine: String {
        var parts: [String] = []
        if debt.annualRatePercent > 0 {
            parts.append("\(Int(debt.annualRatePercent.rounded()))% anual")
        }
        if debt.minimumPayment > 0 {
            parts.append("mínimo \(money.string(debt.minimumPayment, currency: debt.currency))")
        }
        return parts.isEmpty ? debt.kind.label : parts.joined(separator: " · ")
    }
}
