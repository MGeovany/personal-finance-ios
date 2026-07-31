import SwiftUI

/// What the user wants besides being out of debt.
///
/// Picked from a grid of the usual ones. Most goals are priced by tapping a size;
/// a trip asks for a typed amount, and clearing debt uses the total already given.
struct OnboardingGoalsStep: View {
    @Bindable var model: OnboardingViewModel

    @Environment(\.moneyFormatter) private var money

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            ChoiceStack {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: DesignSystem.Space.s), GridItem(.flexible())],
                    spacing: DesignSystem.Space.s
                ) {
                    ForEach(offered) { template in
                        ChoiceTile(
                            title: template.label,
                            icon: template.icon,
                            isSelected: model.hasGoal(template)
                        ) {
                            model.toggle(template)
                        }
                    }
                }

                ChoiceCard(
                    title: "Nada por ahora",
                    detail: "Puedes agregar metas cuando quieras.",
                    icon: "checkmark.circle",
                    isSelected: model.draft.hasNoGoals
                ) {
                    model.declareNoGoals()
                }
            }

            if !model.draft.goals.isEmpty {
                amounts
            }
        }
        .animation(DesignSystem.Motion.swap, value: model.draft.goals.count)
    }

    /// Everything except the catch-all. Debt freedom only appears when there is
    /// something to clear. Otherwise the tile would be a dead end.
    private var offered: [GoalTemplate] {
        GoalTemplate.allCases.filter { template in
            if template == .custom { return false }
            if template == .debtFree { return model.draft.totalDebt > 0 }
            return true
        }
    }

    private var amounts: some View {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
            Text("¿Cuánto necesitas?")
                .sectionHeaderStyle()
                .padding(.horizontal, DesignSystem.Space.xxs)

            ForEach(model.draft.goals) { goal in
                goalAmount(goal)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    @ViewBuilder
    private func goalAmount(_ goal: GoalDraft) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            HStack(spacing: Layout.gap) {
                Image(systemName: goal.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Palette.secondaryText)
                Text(goal.name)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
            }

            if template(for: goal) == .debtFree {
                debtFreeSummary(goal)
            } else if template(for: goal) == .trip {
                CardContainer {
                    MoneyField(
                        title: "Costo del viaje",
                        amount: Binding(
                            get: { goal.targetAmount },
                            set: { model.setTarget($0, for: goal) }
                        ),
                        currency: model.draft.currency,
                        caption: "Un aproximado está bien."
                    )
                }
            } else {
                AmountChoices(
                    options: targetChoices(for: goal),
                    amount: Binding(
                        get: { goal.targetAmount },
                        set: { model.setTarget($0, for: goal) }
                    ),
                    currency: model.draft.currency,
                    customTitle: "Otra cantidad",
                    customPlaceholder: "Lo que cuesta"
                )
            }
        }
    }

    private func debtFreeSummary(_ goal: GoalDraft) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                DetailRow(
                    label: "Meta",
                    value: money.string(goal.targetAmount, currency: goal.currency),
                    tint: Palette.debt
                )
                Text("Es el total de lo que debes. El plan te lleva a dejarlo en cero.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func template(for goal: GoalDraft) -> GoalTemplate? {
        GoalTemplate.allCases.first { $0.label == goal.name }
    }

    /// Sizes labelled the way people talk about goals, derived from income so a
    /// car is not the same number for every salary.
    private func targetChoices(for goal: GoalDraft) -> [AmountChoice] {
        let bands = template(for: goal)?.targetShares ?? [
            ("Pequeño", 1.0),
            ("Normal", 2.5),
            ("Grande", 5.0),
        ]
        return AmountBands.shares(bands, of: model.draft.primaryIncome, currency: model.draft.currency)
    }
}

private extension GoalTemplate {
    /// Target sizes as months of income, named for recognition.
    var targetShares: [(label: String, share: Double)] {
        switch self {
        case .debtFree, .trip:
            []
        case .car:
            [("Usado", 4.0), ("Más nuevo", 8.0), ("Nuevo", 14.0)]
        case .emergency:
            [("Un mes", 1.0), ("Tres meses", 3.0), ("Seis meses", 6.0)]
        case .computer:
            [("Básica", 0.6), ("Buena", 1.2), ("Pro", 2.0)]
        case .moving:
            [("Local", 0.5), ("Con muebles", 1.5), ("Grande", 3.0)]
        case .education:
            [("Un curso", 0.4), ("Un semestre", 1.5), ("Completo", 4.0)]
        case .event:
            [("Sencillo", 0.5), ("Bonito", 1.5), ("Grande", 3.0)]
        case .purchase, .custom:
            [("Pequeño", 0.5), ("Normal", 1.5), ("Grande", 3.0)]
        }
    }
}
