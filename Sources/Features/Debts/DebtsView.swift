import SwiftUI

/// The debts, in the order the plan will kill them.
struct DebtsView: View {
    let dependencies: AppDependencies
    @State private var model: DebtsViewModel
    @State private var editing: DebtDraft?
    @State private var deleting: DebtEntity?
    @State private var showsStrategy = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: DebtsViewModel(
                debts: dependencies.debts,
                planStore: dependencies.planStore,
                preferences: dependencies.preferences
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                ScreenHeader(title: "Deudas") {
                    IconButton(systemImage: "plus", label: "Agregar deuda", isProminent: true) {
                        editing = DebtDraft(currency: model.currency)
                    }
                }

                summaryCard
                strategyCard

                ForEach(Array(model.orderedDebts.enumerated()), id: \.element.uuid) { index, debt in
                    Button {
                        editing = DebtDraft(debt)
                    } label: {
                        DebtRowView(
                            debt: debt,
                            isTarget: debt.uuid == model.targetDebtID,
                            recommendedPayment: model.recommendedPayment(for: debt),
                            payoffDate: model.payoffDate(for: debt),
                            money: dependencies.money,
                            dates: dependencies.dates,
                            attackRank: model.attackRank(for: debt, at: index)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Editar") { editing = DebtDraft(debt) }
                        Button("Eliminar", role: .destructive) { deleting = debt }
                    }
                }

                if model.orderedDebts.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "Sin deudas registradas",
                        message: "Agrega tus tarjetas y préstamos para calcular tu fecha libre de deudas.",
                        actionTitle: "Agregar deuda",
                        action: { editing = DebtDraft(currency: model.currency) }
                    )
                }

                Button {
                    editing = DebtDraft(currency: model.currency)
                } label: {
                    Label("Agregar deuda", systemImage: "plus")
                }
                .secondaryButton()
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .sheet(item: $editing) { draft in
            DebtEditorSheet(
                draft: draft,
                currencies: CurrencyCode.allCases,
                showsStatus: true
            ) { saved in
                if dependencies.debts.debt(withID: saved.id) == nil {
                    model.add(saved)
                } else {
                    model.update(saved)
                }
            }
        }
        .confirmationDrawer(
            item: $deleting,
            title: { "¿Eliminar \($0.name)?" },
            message: { _ in "La deuda sale del plan y se recalculan tus fechas." },
            confirmTitle: "Eliminar"
        ) { debt in
            model.delete(debt)
        }
    }

    private var summaryCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                StatTile(
                    label: "Deuda total",
                    value: dependencies.money.string(model.totalDebt, currency: model.currency),
                    tint: Palette.debt
                )
                RowDivider()
                DetailRow(
                    label: "Pagos mínimos",
                    value: dependencies.money.string(model.totalMinimums, currency: model.currency)
                )
                DetailRow(
                    label: "Pago adicional del plan",
                    value: dependencies.money.string(model.extraPayment, currency: model.currency),
                    tint: Palette.accent
                )
                DetailRow(
                    label: "Fecha libre de deudas",
                    value: model.plan.freedomDate.map { dependencies.dates.dayAndMonth($0, relativeTo: Date()) } ?? "Sin fecha"
                )
            }
        }
    }

    private var strategyCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                SectionHeader(
                    title: "Estrategia",
                    actionTitle: showsStrategy ? "Ocultar" : "Cambiar",
                    action: { showsStrategy.toggle() }
                )

                Text(model.strategy.explanation)
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if showsStrategy {
                    VStack(spacing: DesignSystem.Space.s) {
                        ForEach(PayoffStrategy.allCases) { strategy in
                            StrategyOptionRow(
                                strategy: strategy,
                                isSelected: strategy == model.strategy,
                                interestDifference: strategy == model.strategy ? 0 : model.interestDifference(switchingTo: strategy),
                                money: dependencies.money,
                                currency: model.currency
                            ) {
                                model.select(strategy: strategy)
                            }
                        }
                    }
                }
            }
        }
    }
}
