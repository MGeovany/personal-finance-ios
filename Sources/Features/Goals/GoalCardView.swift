import SwiftUI

/// A goal with its progress, its pace, and the days it costs.
struct GoalCardView: View {
    let goal: GoalEntity
    let impact: GoalImpact?
    let funding: Money
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let currency: CurrencyCode
    let onEdit: () -> Void
    let onChangeMode: (GoalMode) -> Void
    let onContribute: () -> Void

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                header

                ProgressBarView(fraction: goal.progress, tint: goal.isComplete ? Palette.positive : Palette.accent)

                HStack(spacing: DesignSystem.Space.s) {
                    Text("\(money.string(goal.savedAmount, currency: goal.currency)) de \(money.string(goal.targetAmount, currency: goal.currency))")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: DesignSystem.Space.s)
                    Text("\(Int((goal.progress * 100).rounded()))%")
                        .font(Typography.captionStrong)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                }

                RowDivider()

                DetailRow(
                    label: "Aporte este mes",
                    value: funding > 0 ? money.string(funding, currency: goal.currency) : "En pausa",
                    tint: funding > 0 ? Palette.accent : Palette.secondaryText
                )

                if let impact, let completion = impact.projectedCompletion {
                    DetailRow(label: "La alcanzarías", value: dates.dayAndMonth(completion, relativeTo: Date()))
                }

                if let impact, impact.delaysPlan {
                    Text("Aportar a esta meta retrasa tu fecha libre de deuda \(dates.days(impact.daysDelayed)).")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.caution)
                        .fixedSize(horizontal: false, vertical: true)
                }

                modePicker

                HStack(spacing: Layout.tightGap) {
                    Button("Abonar", action: onContribute).secondaryButton()
                    Button("Editar", action: onEdit).secondaryButton()
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: DesignSystem.Space.l) {
            Image(systemName: goal.icon)
                .font(.system(size: 18))
                .foregroundStyle(Palette.accent)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name)
                    .font(Typography.label)
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let date = goal.targetDate {
                    Text("Meta para \(dates.dayAndMonth(date))")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: DesignSystem.Space.s)

            if goal.isComplete {
                Chip(text: "Completada", tint: Palette.positive, icon: "checkmark")
            }
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: Layout.tightGap) {
            Text("Ritmo")
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Layout.tightGap) {
                    ForEach(GoalMode.allCases) { mode in
                        SelectableChip(text: mode.label, isSelected: goal.mode == mode) {
                            onChangeMode(mode)
                        }
                    }
                }
            }
        }
    }
}
