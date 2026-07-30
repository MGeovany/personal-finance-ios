import SwiftUI

/// The grocery budget split into the main run and weekly top-ups.
struct GroceryPlanCard: View {
    let plan: GroceryPlan
    let money: MoneyFormatting
    let currency: CurrencyCode
    let onModeChange: (GroceryMode, Double) -> Void

    /// Local while dragging, so the plan is not recalculated on every pixel.
    @State private var mainShare: Double

    init(
        plan: GroceryPlan,
        money: MoneyFormatting,
        currency: CurrencyCode,
        onModeChange: @escaping (GroceryMode, Double) -> Void
    ) {
        self.plan = plan
        self.money = money
        self.currency = currency
        self.onModeChange = onModeChange
        self._mainShare = State(initialValue: plan.monthly > 0 ? (plan.mainPurchase / plan.monthly).doubleValue : plan.mode.defaultMainShare)
    }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Supermercado")

                HStack(spacing: Layout.tightGap) {
                    ForEach(GroceryMode.allCases) { mode in
                        SelectableChip(text: label(for: mode), isSelected: plan.mode == mode) {
                            onModeChange(mode, mode.defaultMainShare)
                        }
                    }
                }

                Text(plan.mode.explanation)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)

                RowDivider()

                DetailRow(
                    label: "Presupuesto mensual",
                    value: money.string(plan.monthly, currency: currency)
                )

                if plan.mainPurchase > 0 {
                    DetailRow(
                        label: "Compra principal",
                        value: money.string(plan.mainPurchase, currency: currency),
                        tint: Palette.accent
                    )
                }

                if plan.weeklyRestock > 0 {
                    DetailRow(
                        label: "Reposición semanal",
                        value: money.string(plan.weeklyRestock, currency: currency),
                        caption: "\(plan.restockWeeks) semanas"
                    )
                }

                if plan.mode == .hybrid {
                    proportionSlider
                }
            }
        }
    }

    private var proportionSlider: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text("Proporción de la compra principal: \(Int((mainShare * 100).rounded()))%")
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)

            Slider(value: $mainShare, in: 0.2...0.85, step: 0.05) { editing in
                // Commit only when the drag ends.
                if !editing { onModeChange(.hybrid, mainShare) }
            }
        }
    }

    private func label(for mode: GroceryMode) -> String {
        switch mode {
        case .weekly: "Semanal"
        case .monthly: "Mensual"
        case .hybrid: "Híbrida"
        }
    }
}
