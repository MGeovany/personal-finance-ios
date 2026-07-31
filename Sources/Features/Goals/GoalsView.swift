import SwiftUI

/// Secondary goals, always shown next to what they cost in payoff time.
struct GoalsView: View {
    let dependencies: AppDependencies
    @State private var model: GoalsViewModel
    @State private var editing: GoalDraft?
    @State private var contributingTo: GoalEntity?
    @State private var deleting: GoalEntity?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self._model = State(
            initialValue: GoalsViewModel(goals: dependencies.goals, planStore: dependencies.planStore)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                ScreenHeader(title: "Metas") {
                    IconButton(systemImage: "plus", label: "Agregar meta", isProminent: true) {
                        editing = GoalDraft(currency: model.currency)
                    }
                }

                if model.hasDebt, model.totalMonthlyFunding > 0 {
                    InfoBanner(
                        message: "Estás aportando \(dependencies.money.string(model.totalMonthlyFunding, currency: model.currency)) al mes a tus metas mientras pagas deuda. Cada meta muestra cuántos días te cuesta.",
                        severity: .info
                    )
                }

                ForEach(model.allGoals) { goal in
                    GoalCardView(
                        goal: goal,
                        impact: model.impact(for: goal),
                        funding: model.funding(for: goal),
                        money: dependencies.money,
                        dates: dependencies.dates,
                        currency: model.currency,
                        onEdit: { editing = GoalDraft(goal) },
                        onChangeMode: { model.setMode($0, for: goal) },
                        onContribute: { contributingTo = goal }
                    )
                    .contextMenu {
                        Button("Eliminar", role: .destructive) { deleting = goal }
                    }
                }

                if model.allGoals.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "Sin metas todavía",
                        message: "Un viaje, un carro, un fondo de emergencia. Te vamos a mostrar cómo cada meta afecta tu fecha libre de deuda.",
                        actionTitle: "Crear meta",
                        action: { editing = GoalDraft(currency: model.currency) }
                    )
                }

                Button {
                    editing = GoalDraft(currency: model.currency)
                } label: {
                    Label("Agregar meta", systemImage: "plus")
                }
                .secondaryButton()
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .sheet(item: $editing) { draft in
            GoalEditorSheet(draft: draft, currencies: CurrencyCode.allCases) { saved in
                if dependencies.goals.goal(withID: saved.id) == nil {
                    model.add(saved)
                } else {
                    model.update(saved)
                }
            }
        }
        .drawer(item: $contributingTo) { goal in
            GoalContributionSheet(goal: goal, currency: model.currency) { amount in
                model.contribute(amount, to: goal)
            }
        }
        .confirmationDrawer(
            item: $deleting,
            title: { "¿Eliminar \($0.name)?" },
            message: { _ in "Se borra la meta y lo que le has abonado deja de contarse." },
            confirmTitle: "Eliminar"
        ) { goal in
            model.delete(goal)
        }
    }
}

/// Moves money into a goal. One field, so it arrives as a drawer rather than a
/// full modal.
struct GoalContributionSheet: View {
    let goal: GoalEntity
    let currency: CurrencyCode
    let onContribute: (Money) -> Void

    @State private var amount: Money = 0
    @Environment(\.moneyFormatter) private var money
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Drawer(
            title: goal.name,
            message: "Le falta \(money.string(goal.remaining, currency: goal.currency)) para completarse.",
            cancelTitle: "Cancelar"
        ) {
            CardContainer {
                MoneyField(title: "Monto a abonar", amount: $amount, currency: goal.currency)
            }

            Button("Abonar") {
                onContribute(amount)
                dismiss()
            }
            .disabled(amount <= 0)
            .primaryButton(isEnabled: amount > 0)
        }
    }
}
