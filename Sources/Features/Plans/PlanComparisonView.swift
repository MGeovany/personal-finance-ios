import SwiftUI

/// The three plans, side by side and in full detail.
///
/// Reached right after setup and from settings at any time. Choosing here
/// recalculates every budget, every weekly limit and the freedom date at once.
struct PlanComparisonView: View {
    let dependencies: AppDependencies
    /// Shown after onboarding, where choosing a plan closes the flow.
    var isInitialChoice: Bool = false
    var onChosen: (() -> Void)?

    @State private var expandedTable = false
    @Environment(\.dismiss) private var dismiss

    private var planStore: PlanStore { dependencies.planStore }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionGap) {
                header

                cards

                Button {
                    expandedTable.toggle()
                } label: {
                    Label(
                        expandedTable ? "Ocultar comparación detallada" : "Ver comparación detallada",
                        systemImage: expandedTable ? "chevron.up" : "chevron.down"
                    )
                }
                .secondaryButton()

                if expandedTable {
                    comparisonTable
                }

                if isInitialChoice {
                    Button("Continuar con \(planStore.activePlan.name)") {
                        onChosen?()
                    }
                    .primaryButton()
                }
            }
            .padding(Layout.gutter)
        }
        .screenSurface()
    }

    /// The initial choice has nowhere to go back to, so it drops the back button.
    @ViewBuilder
    private var header: some View {
        if isInitialChoice {
            ScreenHeader(title: "Elige tu ritmo", subtitle: "Puedes cambiarlo cuando quieras.")
        } else {
            DetailHeader(title: "Comparar planes")
        }
    }

    // MARK: - Cards

    private var cards: some View {
        VStack(spacing: Layout.gap) {
            ForEach(planStore.planSet.ordered) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: plan.speed == planStore.request.speed,
                    isRecommended: plan.speed == .recommended,
                    summary: dependencies.narrator.summary(
                        for: plan,
                        extraInterest: planStore.extraInterest(for: plan.speed)
                    ),
                    money: dependencies.money,
                    dates: dependencies.dates,
                    currency: planStore.currency
                ) {
                    dependencies.preferences.select(speed: plan.speed)
                }
            }
        }
    }

    // MARK: - Table

    private var comparisonTable: some View {
        CardContainer {
            VStack(spacing: 0) {
                tableHeader

                ForEach(rows) { row in
                    RowDivider()
                    tableRow(row)
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: Layout.tightGap) {
            Text("")
                .frame(width: 108, alignment: .leading)
            ForEach(planStore.planSet.ordered) { plan in
                Text(plan.name)
                    .font(Typography.captionStrong)
                    .foregroundStyle(plan.speed == planStore.request.speed ? Palette.accent : Palette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.bottom, Layout.tightGap)
    }

    private func tableRow(_ row: PlanComparisonRow) -> some View {
        HStack(alignment: .top, spacing: Layout.tightGap) {
            Text(row.label)
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)
                .frame(width: 108, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(planStore.planSet.ordered) { plan in
                Text(row.value(plan))
                    .font(row.isHighlighted ? Typography.captionStrong : Typography.caption)
                    .foregroundStyle(row.isHighlighted ? Palette.primaryText : Palette.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 9)
    }

    private var rows: [PlanComparisonRow] {
        PlanComparisonRow.all(
            money: dependencies.money,
            dates: dependencies.dates,
            currency: planStore.currency,
            extraInterest: { planStore.extraInterest(for: $0) }
        )
    }
}
