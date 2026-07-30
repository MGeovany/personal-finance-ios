import SwiftUI

/// One step for all three lists of recurring charges.
///
/// Fixed expenses, utilities and subscriptions differ only in wording and in the
/// suggestions offered, so they share a step instead of having three that drift
/// apart over time.
struct OnboardingChargeListStep: View {
    @Bindable var model: OnboardingViewModel
    let purpose: ChargeEditorSheet.Purpose
    let dependencies: AppDependencies

    @State private var editing: ChargeDraft?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            if !suggestions.isEmpty, charges.isEmpty {
                suggestionRow
            }

            ForEach(charges) { charge in
                ChargeSummaryRow(
                    charge: charge,
                    money: dependencies.money,
                    onTap: { editing = charge },
                    onDelete: { model.removeCharge(charge, from: purpose) }
                )
            }

            Button {
                editing = ChargeDraft(currency: model.draft.currency)
            } label: {
                Label(addTitle, systemImage: "plus")
            }
            .secondaryButton()

            if total > 0 {
                DetailRow(
                    label: "Total mensual",
                    value: dependencies.money.string(total, currency: model.draft.currency),
                    tint: Palette.accent
                )
                .padding(.top, Layout.tightGap)
            }

            if purpose == .utility {
                Text("Cada servicio tiene su propia reserva. Si un mes pagas menos de lo estimado, el sobrante lo puedes abonar a tu deuda.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .padding(.top, Layout.tightGap)
            }
        }
        .sheet(item: $editing) { draft in
            ChargeEditorSheet(purpose: purpose, draft: draft, currencies: CurrencyCode.allCases) { saved in
                if charges.contains(where: { $0.id == saved.id }) {
                    model.updateCharge(saved, in: purpose)
                } else {
                    model.addCharge(saved, to: purpose)
                }
            }
        }
    }

    // MARK: - Suggestions

    /// One-tap starting points, so the first entry is not a blank form.
    private var suggestionRow: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text("Sugerencias")
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: Layout.tightGap)], spacing: Layout.tightGap) {
                ForEach(suggestions, id: \.self) { name in
                    Button {
                        editing = ChargeDraft(name: name, currency: model.draft.currency)
                    } label: {
                        Text(name)
                            .font(Typography.caption.weight(.medium))
                            .foregroundStyle(Palette.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: Layout.chipRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var suggestions: [String] {
        switch purpose {
        case .fixedExpense: ["Alquiler", "Colegiatura", "Seguro", "Gimnasio"]
        case .utility: UtilityIcon.commonServices
        case .subscription: ["Netflix", "Spotify", "iCloud", "YouTube"]
        case .income: []
        }
    }

    private var charges: [ChargeDraft] {
        switch purpose {
        case .fixedExpense: model.draft.fixedExpenses
        case .utility: model.draft.utilities
        case .subscription: model.draft.subscriptions
        case .income: model.draft.otherIncomes
        }
    }

    private var total: Money {
        charges.reduce(Money.zero) { $0 + $1.monthlyAmount }
    }

    private var addTitle: String {
        switch purpose {
        case .income: "Agregar ingreso"
        case .fixedExpense: "Agregar gasto fijo"
        case .utility: "Agregar servicio"
        case .subscription: "Agregar suscripción"
        }
    }
}
