import SwiftUI

/// The fixed expenses list.
struct FixedExpensesView: View {
    let dependencies: AppDependencies
    @State private var editing: ChargeDraft?

    private var items: [FixedExpenseEntity] { dependencies.fixedExpenses.all() }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                DetailHeader(title: "Gastos fijos")

                if !items.isEmpty {
                    CardContainer {
                        DetailRow(
                            label: "Total mensual",
                            value: dependencies.money.string(total, currency: dependencies.currency),
                            tint: Palette.accent
                        )
                    }
                }

                ForEach(items) { item in
                    ChargeSummaryRow(
                        charge: ChargeDraft(item),
                        money: dependencies.money,
                        onTap: { editing = ChargeDraft(item) },
                        onDelete: { delete(item) }
                    )
                }

                if items.isEmpty {
                    EmptyStateView(
                        icon: "house",
                        title: "Sin gastos fijos",
                        message: "Alquiler, colegiatura, seguros: lo que pagas siempre.",
                        actionTitle: "Agregar gasto fijo",
                        action: { editing = ChargeDraft(currency: dependencies.currency) }
                    )
                }

                Button {
                    editing = ChargeDraft(currency: dependencies.currency)
                } label: {
                    Label("Agregar gasto fijo", systemImage: "plus")
                }
                .secondaryButton()
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .sheet(item: $editing) { draft in
            ChargeEditorSheet(purpose: .fixedExpense, draft: draft, currencies: CurrencyCode.allCases) { saved in
                upsert(saved)
            }
        }
    }

    private var total: Money {
        items.reduce(Money.zero) { $0 + $1.monthlyAmount }
    }

    private func upsert(_ draft: ChargeDraft) {
        if let existing = items.first(where: { $0.uuid == draft.id }) {
            existing.name = draft.name
            existing.amount = draft.amount
            existing.currency = draft.currency
            existing.frequency = draft.frequency
            existing.dueDay = draft.day
            dependencies.fixedExpenses.save()
        } else {
            dependencies.fixedExpenses.add(
                FixedExpenseEntity(
                    uuid: draft.id,
                    name: draft.name,
                    amount: draft.amount,
                    currency: draft.currency,
                    frequency: draft.frequency,
                    dueDay: draft.day
                )
            )
        }
        dependencies.planStore.refresh()
    }

    private func delete(_ item: FixedExpenseEntity) {
        dependencies.fixedExpenses.delete(item)
        dependencies.planStore.refresh()
    }
}

/// Other income streams beyond the salary.
struct IncomeListView: View {
    let dependencies: AppDependencies
    @State private var editing: ChargeDraft?

    private var items: [IncomeEntity] { dependencies.incomes.all() }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                DetailHeader(title: "Otros ingresos")

                ForEach(items) { item in
                    ChargeSummaryRow(
                        charge: draft(from: item),
                        money: dependencies.money,
                        onTap: { editing = draft(from: item) },
                        onDelete: {
                            dependencies.incomes.delete(item)
                            dependencies.planStore.refresh()
                        }
                    )
                }

                if items.isEmpty {
                    EmptyStateView(
                        icon: "arrow.up.circle",
                        title: "Sin otros ingresos",
                        message: "Trabajos por cuenta propia, alquileres, comisiones.",
                        actionTitle: "Agregar ingreso",
                        action: { editing = ChargeDraft(currency: dependencies.currency) }
                    )
                }

                Button {
                    editing = ChargeDraft(currency: dependencies.currency)
                } label: {
                    Label("Agregar ingreso", systemImage: "plus")
                }
                .secondaryButton()
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .sheet(item: $editing) { draft in
            ChargeEditorSheet(purpose: .income, draft: draft, currencies: CurrencyCode.allCases) { saved in
                upsert(saved)
            }
        }
    }

    private func draft(from item: IncomeEntity) -> ChargeDraft {
        ChargeDraft(
            id: item.uuid,
            name: item.name,
            amount: item.amount,
            currency: item.currency,
            frequency: item.frequency
        )
    }

    private func upsert(_ draft: ChargeDraft) {
        if let existing = items.first(where: { $0.uuid == draft.id }) {
            existing.name = draft.name
            existing.amount = draft.amount
            existing.currency = draft.currency
            existing.frequency = draft.frequency
            dependencies.incomes.save()
        } else {
            dependencies.incomes.add(
                IncomeEntity(
                    uuid: draft.id,
                    name: draft.name,
                    amount: draft.amount,
                    currency: draft.currency,
                    frequency: draft.frequency
                )
            )
        }
        dependencies.planStore.refresh()
    }
}
