import SwiftUI

/// The budget: the month, the weeks inside it, and every category.
struct BudgetView: View {
    let dependencies: AppDependencies
    @State private var model: BudgetViewModel
    @State private var editingCategory: BudgetConsumption?
    @State private var showsNewCategory = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: BudgetViewModel(
                categories: dependencies.categories,
                progress: BudgetProgressCalculator(expenses: dependencies.expenses),
                planStore: dependencies.planStore,
                preferences: dependencies.preferences
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                ScreenHeader(title: "Presupuesto") {
                    IconButton(systemImage: "plus", label: "Nueva categoría", isProminent: true) {
                        showsNewCategory = true
                    }
                }

                monthCard
                weeksCard

                ForEach(model.underBudgeted) { warning in
                    InfoBanner(
                        message: dependencies.warnings.message(for: warning),
                        severity: warning.severity,
                        action: suggestionAction(for: warning)
                    )
                }

                GroceryPlanCard(
                    plan: model.grocery,
                    money: dependencies.money,
                    currency: model.currency,
                    onModeChange: { mode, share in model.setGroceryMode(mode, mainShare: share) }
                )

                categoriesCard
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .sheet(item: $editingCategory) { consumption in
            CategoryBudgetSheet(consumption: consumption, model: model, dependencies: dependencies)
        }
        .sheet(isPresented: $showsNewCategory) {
            NewCategorySheet(currency: model.currency) { name, icon, flexibility, baseline in
                model.addCategory(name: name, icon: icon, flexibility: flexibility, baseline: baseline)
            }
        }
    }

    // MARK: - Cards

    private var monthCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                StatTile(
                    label: "Te queda este mes",
                    value: dependencies.money.string(model.monthTotal.remaining, currency: model.currency),
                    caption: "de \(dependencies.money.string(model.monthTotal.budget, currency: model.currency)) para gastos variables"
                )
                ProgressBarView(
                    fraction: model.monthTotal.usedFraction,
                    tint: model.monthTotal.isOverBudget ? Palette.caution : Palette.accent
                )
            }
        }
    }

    private var weeksCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                SectionHeader(title: "Por semana")

                ForEach(model.weeks) { week in
                    HStack(spacing: DesignSystem.Space.s) {
                        Text("Semana \(week.index + 1)")
                            .font(Typography.body)
                            .foregroundStyle(week.index == model.currentWeekIndex ? Palette.primaryText : Palette.secondaryText)
                            .lineLimit(1)
                        if week.index == model.currentWeekIndex {
                            Chip(text: "Actual", tint: Palette.accent)
                        }
                        Spacer(minLength: DesignSystem.Space.s)
                        Text(dependencies.money.string(week.amount, currency: model.currency))
                            .font(Typography.amount)
                            .foregroundStyle(Palette.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .layoutPriority(1)
                    }
                }

                RowDivider()

                Text("La suma de las semanas es exactamente tu presupuesto mensual. La última semana absorbe los días que sobran del mes.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var categoriesCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                SectionHeader(
                    title: "Categorías",
                    actionTitle: "Nueva",
                    action: { showsNewCategory = true }
                )

                ForEach(model.consumptions) { consumption in
                    Button {
                        editingCategory = consumption
                    } label: {
                        LabeledProgress(
                            title: consumption.categoryName,
                            leadingValue: dependencies.money.string(consumption.budget, currency: model.currency),
                            trailingValue: usedCaption(for: consumption),
                            detail: remainingCaption(for: consumption),
                            detailTint: consumption.isOverBudget ? Palette.critical : Palette.tertiaryText,
                            fraction: consumption.usedFraction,
                            tint: tint(for: consumption),
                            icon: consumption.icon,
                            // Card padding plus the screen gutter, so the red bar
                            // breaks out of the card and meets the screen edge.
                            trailingBleed: consumption.isOverBudget
                                ? Layout.cardPadding + DesignSystem.Space.xxl
                                : 0
                        )
                    }
                    .buttonStyle(.plain)
                }

                if model.consumptions.isEmpty {
                    Text("Cuando definas presupuestos o registres gastos, aparecerán aquí.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }
            }
        }
    }

    // MARK: - Helpers

    private func usedCaption(for consumption: BudgetConsumption) -> String {
        "Has usado \(dependencies.money.string(consumption.spent, currency: model.currency))."
    }

    /// Hidden when nothing was spent: remaining then equals the total above.
    private func remainingCaption(for consumption: BudgetConsumption) -> String? {
        guard consumption.spent > 0 else { return nil }
        if consumption.isOverBudget {
            let over = dependencies.money.string(consumption.overspent, currency: model.currency)
            return "Te saliste -\(over) del presupuesto"
        }
        return "Restante \(dependencies.money.string(consumption.remaining, currency: model.currency))"
    }

    private func tint(for consumption: BudgetConsumption) -> Color {
        if consumption.isOverBudget { return Palette.critical }
        if consumption.isNearLimit { return Palette.caution }
        return Palette.accent
    }

    /// The offer attached to an under-budgeted warning: accept the suggestion in
    /// one tap and see the date change.
    private func suggestionAction(for warning: PlanWarning) -> (title: String, handler: () -> Void)? {
        guard case .categoryUnderBudgeted(let name, let suggested) = warning.kind,
              let consumption = model.consumptions.first(where: { $0.categoryName == name })
        else { return nil }

        return (
            title: "Subirlo y recalcular",
            handler: { model.setBudget(suggested, forKey: consumption.categoryKey) }
        )
    }
}
