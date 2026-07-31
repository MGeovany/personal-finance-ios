import SwiftUI

/// The main screen.
///
/// Reads top to bottom as the five questions: how much do I owe, how much can I
/// spend, what should I pay, when does this end, and what is holding me back.
struct HomeView: View {
    let dependencies: AppDependencies
    @State private var model: HomeViewModel
    @State private var route: Route?

    private enum Route: Identifiable, Hashable {
        case addExpense, registerPayment, plans, dailyReview, monthlyClose

        var id: Int { hashValue }
    }

    init(dependencies: AppDependencies, model: HomeViewModel) {
        self.dependencies = dependencies
        self._model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.gap) {
                ScreenHeader(title: "Hoy", subtitle: greeting) {
                    IconButton(systemImage: "checklist", label: "Revisión de hoy") {
                        route = .dailyReview
                    }
                }

                HomeHeaderCard(
                    totalDebt: model.totalDebt,
                    debtChange: model.debtChangeThisMonth,
                    freedomDate: model.freedomDate,
                    monthsToFreedom: model.monthsToFreedom,
                    planName: model.plan.name,
                    money: dependencies.money,
                    dates: dependencies.dates,
                    currency: model.currency,
                    onChangePlan: { route = .plans }
                )

                if model.needsDailyReview {
                    reviewPrompt
                }

                warningsSection

                SpendingRoomCard(
                    week: model.weekBudget,
                    month: model.monthBudget,
                    spentToday: model.spentToday,
                    money: dependencies.money,
                    currency: model.currency
                )

                NextPaymentCard(
                    debt: model.targetDebt,
                    strategy: model.plan.strategy,
                    recommendedPayment: model.recommendedPayment,
                    extraPayment: model.extraPayment,
                    minimums: model.plan.cashFlow.minimumPayments,
                    payoffDate: model.targetDebt.flatMap { model.plan.projection.payoffDateByDebt[$0.uuid] },
                    money: dependencies.money,
                    dates: dependencies.dates,
                    currency: model.currency,
                    onRegisterPayment: { route = .registerPayment }
                )

                upcomingSection
                goalsSection
            }
            .padding(.horizontal, Layout.gutter)
            .padding(.bottom, Layout.sectionGap * 3)
        }
        .screenSurface()
        .safeAreaInset(edge: .bottom) { actionBar }
        .sheet(item: $route) { destination in
            sheet(for: destination)
        }
        .onAppear { model.refresh() }
    }

    // MARK: - Sections

    private var reviewPrompt: some View {
        InfoBanner(
            message: "¿Ya agregaste tus gastos de hoy? Revisa tus transacciones en Wallet y en tus aplicaciones bancarias.",
            severity: .info,
            icon: "checklist",
            action: (title: "Revisar ahora", handler: { route = .dailyReview })
        )
    }

    /// Uses the name from setup when there is one. Absent, the header simply says
    /// "Hoy", which is what it said before anybody was asked.
    private var greeting: String? {
        dependencies.profile.greetingName.map { "Hola, \($0)" }
    }

    @ViewBuilder
    private var warningsSection: some View {
        if !model.warnings.isEmpty {
            VStack(spacing: Layout.tightGap) {
                ForEach(model.warnings.prefix(3)) { warning in
                    InfoBanner(
                        message: dependencies.warnings.message(for: warning),
                        severity: warning.severity
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        if !model.upcomingDueDebts.isEmpty || !model.upcomingSubscriptions.isEmpty || model.reservedUtilities > 0 {
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    SectionHeader(title: "Lo que viene")

                    ForEach(model.upcomingDueDebts) { debt in
                        DetailRow(
                            label: debt.name,
                            value: dependencies.money.string(debt.minimumPayment, currency: model.currency),
                            icon: "calendar.badge.exclamationmark",
                            caption: debt.dueDay.map { "Fecha límite: día \($0)" }
                        )
                    }

                    ForEach(model.upcomingSubscriptions) { subscription in
                        DetailRow(
                            label: subscription.name,
                            value: dependencies.money.string(subscription.amount, currency: subscription.currency),
                            icon: "repeat",
                            caption: subscription.chargeDay.map { "Se cobra el día \($0)" }
                        )
                    }

                    if model.reservedUtilities > 0 {
                        DetailRow(
                            label: "Servicios reservados",
                            value: dependencies.money.string(model.reservedUtilities, currency: model.currency),
                            icon: "bolt"
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var goalsSection: some View {
        if !model.activeGoals.isEmpty {
            CardContainer {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    SectionHeader(title: "Tus metas")

                    ForEach(model.activeGoals) { goal in
                        LabeledProgress(
                            title: goal.name,
                            leadingValue: dependencies.money.string(goal.savedAmount, currency: goal.currency),
                            trailingValue: goalCaption(goal),
                            fraction: goal.progress,
                            tint: Palette.accent,
                            icon: goal.icon
                        )
                    }
                }
            }
        }
    }

    private func goalCaption(_ goal: GoalEntity) -> String {
        let target = dependencies.money.string(goal.targetAmount, currency: goal.currency)
        let funding = model.funding(for: goal)
        guard funding > 0 else { return "de \(target) · en pausa este mes" }
        return "de \(target) · \(dependencies.money.string(funding, currency: goal.currency)) este mes"
    }

    // MARK: - Actions

    private var actionBar: some View {
        HStack(spacing: Layout.gap) {
            Button {
                route = .addExpense
            } label: {
                Label("Agregar gasto", systemImage: "plus")
            }
            .primaryButton()

            IconButton(
                systemImage: "arrow.down",
                label: "Registrar pago",
                size: Layout.controlHeight
            ) {
                route = .registerPayment
            }
        }
        .padding(.horizontal, Layout.gutter)
        .padding(.vertical, Layout.gap)
        .background {
            // A soft fade rather than a bar, so the buttons read as floating over
            // the page the way the rest of the surfaces do.
            LinearGradient(
                colors: [Palette.canvas.opacity(0), Palette.canvas, Palette.canvas],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func sheet(for destination: Route) -> some View {
        switch destination {
        case .addExpense:
            AddExpenseSheet(dependencies: dependencies)
        case .registerPayment:
            RegisterPaymentSheet(dependencies: dependencies)
        case .plans:
            NavigationStack {
                PlanComparisonView(dependencies: dependencies)
            }
            .modalPresentation()
        case .dailyReview:
            DailyReviewSheet(dependencies: dependencies)
        case .monthlyClose:
            MonthlyCloseSheet(dependencies: dependencies)
        }
    }
}
