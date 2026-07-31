import SwiftUI

/// "¿Qué pasa si...?" — try a decision, see the new numbers, keep it or discard it.
struct SimulatorView: View {
    let dependencies: AppDependencies
    @State private var model: SimulatorViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: SimulatorViewModel(
                planStore: dependencies.planStore,
                subscriptions: dependencies.subscriptions,
                debts: dependencies.debts,
                categories: dependencies.categories,
                goals: dependencies.goals,
                profiles: dependencies.profiles
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.gap) {
                DetailHeader(title: "¿Qué pasa si...?")

                scenarioPicker
                inputs

                if let result = model.result {
                    comparison(result)

                    if model.canApply {
                        Button("Aplicar este cambio") { model.apply() }
                            .primaryButton()
                    } else {
                        Text("Esta simulación no cambia nada por sí sola. Es para que veas el efecto antes de decidir.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.tertiaryText)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(Layout.gutter)
        }
        .screenSurface()
    }

    // MARK: - Scenario

    private var scenarioPicker: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Elige una situación")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Layout.tightGap) {
                    ForEach(SimulatorViewModel.Scenario.allCases) { scenario in
                        let isSelected = model.scenario == scenario

                        Button {
                            withAnimation(DesignSystem.Motion.swap) { model.scenario = scenario }
                        } label: {
                            VStack(spacing: DesignSystem.Space.s) {
                                Image(systemName: scenario.icon)
                                    .font(.system(size: 17, weight: .medium))
                                Text(scenario.label)
                                    .font(Typography.caption)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(isSelected ? Palette.invertedText : Palette.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 84)
                            .padding(DesignSystem.Space.s)
                            .background(
                                isSelected ? Palette.accent : Palette.surfaceMuted,
                                in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
            }
        }
    }

    // MARK: - Inputs

    @ViewBuilder
    private var inputs: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                switch model.scenario {
                case .cancelSubscription:
                    picker(
                        "Suscripción",
                        options: model.availableSubscriptions.map { ($0.uuid, $0.name) },
                        selection: $model.selectedSubscriptionID
                    )

                case .changeCategoryBudget:
                    SelectRow(
                        title: "Categoría",
                        selection: $model.selectedCategoryKey,
                        options: model.availableCategories.map(\.key),
                        label: { key in model.availableCategories.first { $0.key == key }?.name ?? key }
                    )
                    MoneyField(title: "Nuevo presupuesto mensual", amount: $model.amount, currency: model.currency)

                case .useSavings:
                    MoneyField(title: "Monto de ahorros", amount: $model.amount, currency: model.currency)
                    Text("Tienes \(dependencies.money.string(model.savings, currency: model.currency)) en ahorros.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)

                case .extraIncome:
                    MoneyField(title: "Ingreso extra", amount: $model.amount, currency: model.currency)
                    CeroToggle(title: "Es todos los meses", isOn: $model.isRecurringIncome)

                case .extraPayment:
                    picker(
                        "A qué deuda",
                        options: model.availableDebts.map { ($0.uuid, $0.name) },
                        selection: $model.selectedDebtID
                    )
                    MoneyField(title: "Pago adicional", amount: $model.amount, currency: model.currency)

                case .newGoal:
                    MoneyField(title: "Aporte mensual a la meta", amount: $model.amount, currency: model.currency)

                case .changeGoalPace:
                    picker(
                        "Meta",
                        options: model.availableGoals.map { ($0.uuid, $0.name) },
                        selection: $model.selectedGoalID
                    )
                    SelectRow(
                        title: "Ritmo",
                        selection: $model.selectedMode,
                        options: GoalMode.allCases,
                        label: \.label
                    )

                case .cardPurchase:
                    picker(
                        "Tarjeta",
                        options: model.availableCards.map { ($0.uuid, $0.name) },
                        selection: $model.selectedDebtID
                    )
                    MoneyField(title: "Monto de la compra", amount: $model.amount, currency: model.currency)
                    CeroToggle(title: "Ya tengo el dinero", isOn: $model.isCardPurchaseBacked)

                case .changePlan:
                    SegmentedSelector(
                        selection: $model.selectedSpeed,
                        options: PlanSpeed.displayOrder,
                        label: { dependencies.profile.name(for: $0) }
                    )

                case .changeStrategy:
                    SegmentedSelector(
                        selection: $model.selectedStrategy,
                        options: PayoffStrategy.allCases,
                        label: \.label
                    )
                }
            }
        }
    }

    /// A choice over `(id, name)` pairs. Taking the pairs rather than the entities
    /// keeps this free of any entity type and of SwiftData identifiers.
    private func picker(_ title: String, options: [(id: UUID, name: String)], selection: Binding<UUID?>) -> some View {
        SelectRow(
            title: title,
            selection: selection,
            options: options.map { Optional($0.id) },
            label: { id in options.first { $0.id == id }?.name ?? "Elegir" }
        )
    }

    // MARK: - Result

    private func comparison(_ result: ScenarioResult) -> some View {
        VStack(spacing: Layout.gap) {
            ImpactBadge(
                impact: result.impact,
                dates: dependencies.dates,
                showsInterest: true,
                currency: model.currency,
                money: dependencies.money
            )

            CardContainer {
                VStack(spacing: Layout.gap) {
                    comparisonRow(
                        "Fecha libre de deudas",
                        before: result.current.freedomDate.map { dependencies.dates.dayAndMonth($0, relativeTo: Date()) } ?? "—",
                        after: result.simulated.freedomDate.map { dependencies.dates.dayAndMonth($0, relativeTo: Date()) } ?? "—"
                    )
                    RowDivider()
                    comparisonRow(
                        "Presupuesto semanal",
                        before: format(result.current.weekly.averageWeekly),
                        after: format(result.simulated.weekly.averageWeekly)
                    )
                    RowDivider()
                    comparisonRow(
                        "Pago mensual",
                        before: format(result.current.monthlyDebtPayment),
                        after: format(result.simulated.monthlyDebtPayment)
                    )
                    RowDivider()
                    comparisonRow(
                        "Intereses totales",
                        before: format(result.current.totalInterest),
                        after: format(result.simulated.totalInterest)
                    )
                    RowDivider()
                    comparisonRow(
                        "Gasto variable mensual",
                        before: format(result.current.monthlyVariableBudget),
                        after: format(result.simulated.monthlyVariableBudget)
                    )
                }
            }

            Text(dependencies.narrator.datedImpact(result.impact))
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func comparisonRow(_ label: String, before: String, after: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Palette.tertiaryText)
            HStack {
                Text(before)
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.tertiaryText)
                Text(after)
                    .font(Typography.amount)
                    .foregroundStyle(Palette.primaryText)
                Spacer()
            }
        }
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: model.currency)
    }
}
