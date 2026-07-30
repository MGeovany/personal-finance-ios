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
        .background(Palette.canvas)
        .navigationTitle("¿Qué pasa si...?")
    }

    // MARK: - Scenario

    private var scenarioPicker: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Elige una situación")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Layout.tightGap) {
                    ForEach(SimulatorViewModel.Scenario.allCases) { scenario in
                        Button {
                            model.scenario = scenario
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: scenario.icon)
                                    .font(.system(size: 16))
                                Text(scenario.label)
                                    .font(Typography.caption)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(model.scenario == scenario ? .white : Palette.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Layout.gap)
                            .background(
                                model.scenario == scenario ? Palette.accent : Palette.surfaceMuted,
                                in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
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
                    Picker("Categoría", selection: $model.selectedCategoryKey) {
                        ForEach(model.availableCategories) { category in
                            Text(category.name).tag(category.key)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    MoneyField(title: "Nuevo presupuesto mensual", amount: $model.amount, currency: model.currency)

                case .useSavings:
                    MoneyField(title: "Monto de ahorros", amount: $model.amount, currency: model.currency)
                    Text("Tienes \(dependencies.money.string(model.savings, currency: model.currency)) en ahorros.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)

                case .extraIncome:
                    MoneyField(title: "Ingreso extra", amount: $model.amount, currency: model.currency)
                    Toggle("Es todos los meses", isOn: $model.isRecurringIncome)

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
                    Picker("Ritmo", selection: $model.selectedMode) {
                        ForEach(GoalMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                case .cardPurchase:
                    picker(
                        "Tarjeta",
                        options: model.availableCards.map { ($0.uuid, $0.name) },
                        selection: $model.selectedDebtID
                    )
                    MoneyField(title: "Monto de la compra", amount: $model.amount, currency: model.currency)
                    Toggle("Ya tengo el dinero", isOn: $model.isCardPurchaseBacked)

                case .changePlan:
                    Picker("Plan", selection: $model.selectedSpeed) {
                        ForEach(PlanSpeed.displayOrder) { speed in
                            Text(dependencies.profile.name(for: speed)).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)

                case .changeStrategy:
                    Picker("Estrategia", selection: $model.selectedStrategy) {
                        ForEach(PayoffStrategy.allCases) { strategy in
                            Text(strategy.label).tag(strategy)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    /// A picker over `(id, name)` pairs. Taking the pairs rather than the entities
    /// keeps this free of any entity type and of SwiftData identifiers.
    private func picker(_ title: String, options: [(id: UUID, name: String)], selection: Binding<UUID?>) -> some View {
        Picker(title, selection: selection) {
            ForEach(options, id: \.id) { option in
                Text(option.name).tag(Optional(option.id))
            }
        }
        .pickerStyle(.navigationLink)
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
