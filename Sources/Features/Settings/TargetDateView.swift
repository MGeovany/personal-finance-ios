import SwiftUI

/// The user picks a deadline; the app answers with what it would actually take.
///
/// A date is never accepted silently. If it is out of reach, the screen says so and
/// offers the three dates that are real.
struct TargetDateView: View {
    let dependencies: AppDependencies

    @State private var targetDate: Date
    @State private var assessment: TargetDateAssessment?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        let existing = dependencies.profile.targetDate
        self._targetDate = State(
            initialValue: existing ?? Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        )
    }

    private var planStore: PlanStore { dependencies.planStore }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                DetailHeader(title: "Fecha objetivo")

                datePickerCard
                threeDatesCard

                if let assessment {
                    verdictCard(assessment)
                }
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .onAppear(perform: evaluate)
        .onChange(of: targetDate) { _, _ in evaluate() }
    }

    private var datePickerCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                DateRow(
                    title: "Quiero estar libre de deudas el",
                    date: $targetDate,
                    range: Date()...
                )

                if dependencies.profile.targetDate != nil {
                    RowDivider()
                    Button("Quitar mi fecha objetivo") {
                        dependencies.preferences.setTargetDate(nil)
                    }
                    .quietButton()
                }
            }
        }
    }

    /// The three options always offered alongside a custom date.
    @ViewBuilder
    private var threeDatesCard: some View {
        if let options = planStore.planSet.dateOptions {
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    SectionHeader(title: "Nuestras fechas")

                    ForEach(options.all) { option in
                        Button {
                            dependencies.preferences.select(speed: option.speed)
                            if let date = option.date { targetDate = date }
                        } label: {
                            HStack(alignment: .top, spacing: Layout.gap) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.label)
                                        .font(Typography.label)
                                        .foregroundStyle(Palette.primaryText)
                                    Text("Pago de \(format(option.monthlyPayment)) · \(option.difficulty.label.lowercased())")
                                        .font(Typography.caption)
                                        .foregroundStyle(Palette.tertiaryText)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(option.date.map { dependencies.dates.dayAndMonth($0, relativeTo: Date()) } ?? "···")
                                        .font(Typography.amount)
                                        .foregroundStyle(planStore.request.speed == option.speed ? Palette.accent : Palette.primaryText)
                                    DifficultyBars(difficulty: option.difficulty)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func verdictCard(_ assessment: TargetDateAssessment) -> some View {
        VStack(spacing: Layout.gap) {
            InfoBanner(
                message: dependencies.narrator.assessment(
                    assessment,
                    recommended: planStore.planSet.dateOptions?.recommended
                ),
                severity: assessment.isAchievable ? .info : .caution
            )

            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    SectionHeader(title: assessment.isAchievable ? "Lo que requiere" : "Ni con el máximo esfuerzo")

                    DetailRow(label: "Pago mensual necesario", value: format(assessment.requiredMonthlyPayment), tint: Palette.accent)
                    DetailRow(label: "Gasto variable mensual", value: format(assessment.allowedMonthlyVariable))
                    DetailRow(label: "Gasto semanal", value: format(assessment.allowedWeeklyVariable))
                    DetailRow(label: "Intereses totales", value: format(assessment.totalInterest))
                    DetailRow(label: "Dificultad", value: assessment.difficulty.label)

                    if assessment.savingsNeeded > 0 {
                        DetailRow(
                            label: "Ahorros que tendrías que usar",
                            value: format(assessment.savingsNeeded),
                            tint: Palette.caution
                        )
                    }

                    if !assessment.goalsToPause.isEmpty {
                        DetailRow(
                            label: "Metas a pausar",
                            value: assessment.goalsToPause.joined(separator: ", "),
                            tint: Palette.caution
                        )
                    }

                    if let earliest = assessment.earliestAchievableDate, !assessment.isAchievable {
                        RowDivider()
                        DetailRow(
                            label: "Lo más pronto posible",
                            value: dependencies.dates.dayAndMonth(earliest, relativeTo: Date()),
                            tint: Palette.accent
                        )
                    }
                }
            }

            if !assessment.requiredCuts.isEmpty {
                cutsCard(assessment.requiredCuts)
            }

            if assessment.isAchievable {
                Button("Fijar esta fecha como mi objetivo") {
                    dependencies.preferences.setTargetDate(targetDate)
                }
                .primaryButton()
            }
        }
    }

    private func cutsCard(_ cuts: [CategoryCut]) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Recortes que implicaría")

                ForEach(cuts) { cut in
                    DetailRow(
                        label: cut.categoryName,
                        value: "\(format(cut.from)) → \(format(cut.to))",
                        tint: Palette.caution
                    )
                }
            }
        }
    }

    private func evaluate() {
        assessment = planStore.assess(targetDate: targetDate)
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: planStore.currency)
    }
}
