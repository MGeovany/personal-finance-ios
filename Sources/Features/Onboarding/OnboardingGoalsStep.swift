import SwiftUI

/// Optional secondary goals, and an honest note that they cost time.
struct OnboardingGoalsStep: View {
    @Bindable var model: OnboardingViewModel
    let dependencies: AppDependencies

    @State private var editing: GoalDraft?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            ForEach(model.draft.goals) { goal in
                GoalDraftRow(
                    goal: goal,
                    money: dependencies.money,
                    onTap: { editing = goal },
                    onDelete: { model.removeGoal(goal) }
                )
            }

            Button {
                editing = GoalDraft(currency: model.draft.currency)
            } label: {
                Label("Agregar meta", systemImage: "plus")
            }
            .secondaryButton()

            if !model.draft.debts.isEmpty {
                InfoBanner(
                    message: "Cada meta que financies mientras tienes deuda mueve tu fecha libre de deuda. Te vamos a mostrar exactamente cuántos días.",
                    severity: .info
                )
            }
        }
        .sheet(item: $editing) { draft in
            GoalEditorSheet(draft: draft, currencies: CurrencyCode.allCases) { saved in
                model.upsertGoal(saved)
            }
        }
    }
}

/// A goal in a list, with its contribution and pace.
struct GoalDraftRow: View {
    let goal: GoalDraft
    let money: MoneyFormatting
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        CardContainer(padding: Layout.gap) {
            HStack(spacing: Layout.gap) {
                Image(systemName: goal.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(Typography.label)
                        .foregroundStyle(Palette.primaryText)
                    Text("\(money.string(goal.requestedMonthly, currency: goal.currency)) al mes · \(goal.mode.label.lowercased())")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }

                Spacer(minLength: Layout.tightGap)

                Text(money.string(goal.targetAmount, currency: goal.currency))
                    .font(Typography.amount)
                    .foregroundStyle(Palette.primaryText)

                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 17))
                            .foregroundStyle(Palette.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Eliminar \(goal.name)")
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}
