import SwiftUI

/// The weekly close: what the week cost, and where the leftover goes.
struct WeeklyCloseSheet: View {
    let dependencies: AppDependencies
    @State private var model: PeriodCloseViewModel
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(initialValue: PeriodCloseViewModel.make(kind: .weekly, dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.gap) {
                    numbersCard
                    breakdownCard
                    paymentsCard

                    if model.surplus > 0 {
                        SurplusDestinationPicker(
                            surplus: model.surplus,
                            selection: $model.surplusDestination,
                            money: dependencies.money,
                            currency: model.currency
                        )
                    }

                    InfoBanner(message: model.recommendation, severity: .info)

                    Button("Cerrar la semana") {
                        model.complete()
                        dismiss()
                    }
                    .primaryButton()
                }
                .padding(Layout.gutter)
            }
            .background(Palette.canvas)
            .navigationTitle("Cierre semanal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private var numbersCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                DetailRow(label: "Presupuesto inicial", value: format(model.consumption.budget))
                DetailRow(label: "Gastos totales", value: format(model.consumption.spent))
                RowDivider()
                DetailRow(
                    label: model.consumption.isOverBudget ? "Te pasaste por" : "Dinero restante",
                    value: format(model.consumption.isOverBudget ? model.consumption.overspent : model.surplus),
                    tint: model.consumption.isOverBudget ? Palette.caution : Palette.positive
                )
                DetailRow(
                    label: "Nueva fecha estimada",
                    value: model.estimatedDate.map { dependencies.dates.dayAndMonth($0, relativeTo: Date()) } ?? "—"
                )
            }
        }
    }

    private var breakdownCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Dónde se fue")

                if let biggest = model.biggestCategory {
                    DetailRow(
                        label: "Mayor gasto",
                        value: format(biggest.spent),
                        icon: biggest.icon,
                        caption: biggest.categoryName
                    )
                }

                ForEach(model.overspentCategories) { category in
                    DetailRow(
                        label: category.categoryName,
                        value: "+" + format(category.overspent),
                        tint: Palette.caution,
                        icon: category.icon,
                        caption: "Fuera del plan"
                    )
                }

                if model.overspentCategories.isEmpty {
                    Text("Ninguna categoría se pasó del plan.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }
            }
        }
    }

    private var paymentsCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Progreso de deuda")
                DetailRow(label: "Pagos realizados", value: format(model.totalPaid))
                DetailRow(
                    label: "Deuda total",
                    value: format(dependencies.planStore.snapshot.totalDebt),
                    tint: Palette.debt
                )
            }
        }
    }

    private func format(_ value: Money) -> String {
        dependencies.money.string(value, currency: model.currency)
    }
}

/// Where the period's leftover money should go.
struct SurplusDestinationPicker: View {
    let surplus: Money
    @Binding var selection: SurplusDestination
    let money: MoneyFormatting
    let currency: CurrencyCode

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Te sobraron \(money.string(surplus, currency: currency))")

                ForEach(SurplusDestination.allCases) { destination in
                    Button {
                        selection = destination
                    } label: {
                        HStack(spacing: Layout.gap) {
                            Image(systemName: selection == destination ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(selection == destination ? Palette.accent : Palette.tertiaryText)
                            Label(destination.label, systemImage: destination.icon)
                                .font(Typography.body)
                                .foregroundStyle(Palette.primaryText)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

extension PeriodCloseViewModel {
    /// Assembles the view model from the composition root. Both close sheets need
    /// the same wiring, so it lives in one place.
    @MainActor
    static func make(kind: ReviewKind, dependencies: AppDependencies) -> PeriodCloseViewModel {
        PeriodCloseViewModel(
            kind: kind,
            expenses: dependencies.expenses,
            debts: dependencies.debts,
            goals: dependencies.goals,
            profiles: dependencies.profiles,
            reviews: dependencies.reviews,
            progress: BudgetProgressCalculator(expenses: dependencies.expenses),
            planStore: dependencies.planStore
        )
    }
}
