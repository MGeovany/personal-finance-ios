import SwiftUI

/// The everyday budgets: groceries, transport, outings.
///
/// Asks for approximations on purpose. Precision here is false comfort — the app
/// corrects these numbers from real spending within a few weeks, and says so.
struct OnboardingLifestyleStep: View {
    @Bindable var model: OnboardingViewModel
    let dependencies: AppDependencies

    /// The categories worth asking about during setup. The rest start at zero and
    /// can be filled in later without blocking the first plan.
    private let asked: [(key: String, label: String, icon: String)] = [
        (CategoryKeys.groceries, "Supermercado", "cart"),
        (CategoryKeys.transport, "Transporte y Uber", "car"),
        (CategoryKeys.outings, "Salidas y restaurantes", "party.popper"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    ForEach(asked, id: \.key) { entry in
                        MoneyField(
                            title: entry.label,
                            amount: binding(for: entry.key),
                            currency: model.draft.currency
                        )
                    }
                }
            }

            groceryModePicker

            if model.draft.declaredLifestyle > 0 {
                availableSummary
            }
        }
    }

    private var groceryModePicker: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            SectionHeader(title: "¿Cómo compras el supermercado?")

            HStack(spacing: Layout.tightGap) {
                ForEach(GroceryMode.allCases) { mode in
                    SelectableChip(
                        text: mode == .hybrid ? "Híbrida" : mode.label.replacingOccurrences(of: "Compra ", with: ""),
                        isSelected: model.draft.groceryMode == mode
                    ) {
                        model.draft.groceryMode = mode
                    }
                }
            }

            Text(model.draft.groceryMode.explanation)
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Live arithmetic, so the user sees the consequence of every number they type
    /// before any plan exists.
    private var availableSummary: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                DetailRow(
                    label: "Ingresos",
                    value: dependencies.money.string(model.draft.totalMonthlyIncome, currency: model.draft.currency)
                )
                DetailRow(
                    label: "Compromisos y pagos mínimos",
                    value: "−" + dependencies.money.string(model.draft.totalCommitted, currency: model.draft.currency)
                )
                DetailRow(
                    label: "Vida diaria",
                    value: "−" + dependencies.money.string(model.draft.declaredLifestyle, currency: model.draft.currency)
                )
                RowDivider()
                DetailRow(
                    label: "Quedaría para pagar deuda",
                    value: dependencies.money.string(model.draft.estimatedAvailable, currency: model.draft.currency),
                    tint: model.draft.estimatedAvailable > 0 ? Palette.positive : Palette.critical
                )
            }
        }
    }

    private func binding(for key: String) -> Binding<Money> {
        Binding(
            get: { model.baseline(for: key) },
            set: { model.setBaseline($0, for: key) }
        )
    }
}
