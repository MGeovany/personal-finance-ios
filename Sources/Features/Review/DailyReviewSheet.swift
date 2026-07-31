import SwiftUI

/// The nightly check-in the notification points at.
struct DailyReviewSheet: View {
    let dependencies: AppDependencies
    @State private var model: DailyReviewViewModel
    @State private var addingExpense = false
    @Environment(\.dismiss) private var dismiss

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: DailyReviewViewModel(
                expenses: dependencies.expenses,
                debts: dependencies.debts,
                subscriptions: dependencies.subscriptions,
                reviews: dependencies.reviews,
                progress: BudgetProgressCalculator(expenses: dependencies.expenses),
                planStore: dependencies.planStore
            )
        )
    }

    var body: some View {
        ModalScaffold(
            title: "Revisión de hoy",
            primary: ModalAction("Terminar revisión") {
                model.complete()
                dismiss()
            },
            secondary: ModalAction("Agregar gasto") { addingExpense = true },
            spacing: Layout.gap
        ) {
            summaryCard
            expensesCard

            if !model.uncategorized.isEmpty {
                uncategorizedCard
            }

            if !model.expectedCharges.isEmpty {
                expectedCard
            }

            checklistCard
        }
        .modalPresentation()
        .sheet(isPresented: $addingExpense) {
            AddExpenseSheet(dependencies: dependencies)
        }
    }

    private var summaryCard: some View {
        CardContainer {
            HStack(spacing: Layout.gap) {
                StatTile(
                    label: "Gastado hoy",
                    value: dependencies.money.string(model.spentToday, currency: model.currency)
                )
                StatTile(
                    label: "Queda esta semana",
                    value: dependencies.money.string(model.weekRemaining, currency: model.currency),
                    tint: Palette.accent
                )
            }
        }
    }

    private var expensesCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Gastos de hoy")

                if model.todaysExpenses.isEmpty {
                    Text("Todavía no registraste gastos hoy.")
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondaryText)
                } else {
                    ForEach(model.todaysExpenses) { expense in
                        DetailRow(
                            label: expense.merchant.isEmpty ? expense.categoryKey : expense.merchant,
                            value: dependencies.money.string(expense.amount, currency: expense.currency),
                            icon: expense.paymentMethod.icon,
                            caption: expense.backing == .settled ? nil : expense.backing.label
                        )
                    }
                }

                if model.unbackedToday > 0 {
                    InfoBanner(
                        message: "Hoy hiciste \(dependencies.money.string(model.unbackedToday, currency: model.currency)) en compras con tarjeta sin dinero reservado. Ya cuentan como deuda nueva.",
                        severity: .caution
                    )
                }

                if !model.cardsUsedToday.isEmpty {
                    Text("Tarjetas usadas: \(model.cardsUsedToday.map(\.name).joined(separator: ", "))")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }
            }
        }
    }

    private var uncategorizedCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Falta categorizar")

                ForEach(model.uncategorized) { expense in
                    SelectRow(
                        title: dependencies.money.string(expense.amount, currency: expense.currency),
                        selection: Binding(
                            get: { expense.categoryKey },
                            set: { model.categorize(expense, as: $0) }
                        ),
                        options: dependencies.categories.visible().map(\.key),
                        label: { key in categoryName(for: key) },
                        icon: { key in dependencies.categories.visible().first { $0.key == key }?.icon }
                    )
                }
            }
        }
    }

    /// Nudges toward transactions that probably happened but were not entered.
    private var expectedCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                SectionHeader(title: "Puede que falten")

                ForEach(model.expectedCharges) { subscription in
                    DetailRow(
                        label: subscription.name,
                        value: dependencies.money.string(subscription.amount, currency: subscription.currency),
                        icon: "repeat",
                        caption: "Se cobra por estos días"
                    )
                }
            }
        }
    }

    private var checklistCard: some View {
        CardContainer {
            CeroToggle(
                title: "Ya revisé Wallet y mis apps bancarias",
                caption: "Para que no se te escape ningún cargo automático.",
                isOn: $model.hasCheckedExternalApps
            )
        }
    }

    private func categoryName(for key: String) -> String {
        dependencies.categories.visible().first { $0.key == key }?.name ?? key
    }
}
