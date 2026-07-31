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
        case registerPayment, registerAbonos, dailyReview, briefing
        /// The screen where a specific number can be changed. Opened from the briefing
        /// rows, so "no me alcanza" leads somewhere instead of just being read.
        case budget, strategy

        var id: Int { hashValue }
    }

    init(dependencies: AppDependencies, model: HomeViewModel) {
        self.dependencies = dependencies
        self._model = State(initialValue: model)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                greetingHeader

                // On a payday, and until an abono is registered, this is what the screen
                // is for. Everything else keeps reporting below it.
                if model.showsPaydayBanner {
                    PaydayBanner(
                        status: model.paydayStatus,
                        instructions: model.paydayInstructions,
                        money: dependencies.money,
                        dates: dependencies.dates,
                        currency: model.currency,
                        onRegister: { route = .registerAbonos }
                    )
                }

                if model.showsWeeklyStatus {
                    WeeklyStatusCard(
                        week: model.weekBudget,
                        month: model.monthBudget,
                        days: model.weekDays,
                        deliveryOrdersUsed: model.deliveryOrdersUsed,
                        deliveryOrdersAllowed: model.deliveryOrdersAllowed,
                        outingsSpent: model.outingsMonthSpent,
                        outingsBudget: model.outingsMonthBudget,
                        spentToday: model.spentToday,
                        money: dependencies.money,
                        currency: model.currency
                    )
                }

                PlanBriefingSection(
                    items: model.briefingItems,
                    paymentRows: model.briefingPaymentRows,
                    onOpenFull: { route = .briefing },
                    onEdit: { editable in
                        switch editable {
                        case .categoryBudget: route = .budget
                        case .strategy: route = .strategy
                        }
                    }
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
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .sheet(item: $route) { destination in
            sheet(for: destination)
        }
        .onChange(of: route) { previous, current in
            // Coming back from registering a payment changes whether the payday nudges
            // are still needed, and those are booked per day rather than repeating, so
            // they have to be rebuilt rather than left to expire.
            guard current == nil, previous == .registerPayment || previous == .registerAbonos else { return }
            model.refresh()
            Task { await dependencies.refreshReminders() }
        }
        .onAppear { model.refresh() }
    }

    // MARK: - Sections

    /// Greeting in thin type on its own line; the name below, larger. The name is
    /// the personal signal; the time of day is just quiet context above it.
    private var greetingHeader: some View {
        HStack(alignment: .top, spacing: Layout.gap) {
            greetingTitle
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(greetingAccessibilityLabel)

            Spacer(minLength: 0)

            HStack(spacing: DesignSystem.Space.s) {
                IconButton(systemImage: "checklist", label: "Revisión de hoy") {
                    route = .dailyReview
                }
                NavigationLink {
                    SettingsView(dependencies: dependencies)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    Image(systemName: "gearshape")
                }
                .iconButton()
                .accessibilityLabel("Ajustes")
            }
        }
        .padding(.top, DesignSystem.Space.s)
        .padding(.bottom, DesignSystem.Space.xxs)
    }

    @ViewBuilder
    private var greetingTitle: some View {
        let greeting = dayPartGreeting
        if let name = dependencies.profile.greetingName, !name.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DesignSystem.Space.s) {
                    Image(systemName: dayPartIcon)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Palette.secondaryText)
                        .symbolRenderingMode(.hierarchical)

                    Text("\(greeting),")
                        .font(Typography.display(22, .light))
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Text(name)
                    .font(Typography.display(40, .displayBold))
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        } else {
            HStack(spacing: DesignSystem.Space.s) {
                Image(systemName: dayPartIcon)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Palette.primaryText)
                    .symbolRenderingMode(.hierarchical)

                Text(greeting)
                    .font(Typography.display(34, .displayBold))
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
        }
    }

    private var greetingAccessibilityLabel: String {
        if let name = dependencies.profile.greetingName, !name.isEmpty {
            return "\(dayPartGreeting), \(name)"
        }
        return dayPartGreeting
    }

    private var dayPart: DayPart {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: .morning
        case 12..<19: .afternoon
        default: .night
        }
    }

    private var dayPartGreeting: String { dayPart.greeting }

    private var dayPartIcon: String { dayPart.icon }

    private enum DayPart {
        case morning, afternoon, night

        var greeting: String {
            switch self {
            case .morning: "Buenos días"
            case .afternoon: "Buenas tardes"
            case .night: "Buenas noches"
            }
        }

        var icon: String {
            switch self {
            case .morning: "sun.max"
            case .afternoon: "sunset"
            case .night: "moon"
            }
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        if !model.upcomingDueDebts.isEmpty || !model.upcomingSubscriptions.isEmpty || model.reservedUtilities > 0 {
            CardContainer {
                VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
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
                VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
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

    @ViewBuilder
    private func sheet(for destination: Route) -> some View {
        switch destination {
        case .registerPayment:
            RegisterPaymentSheet(dependencies: dependencies)
        case .registerAbonos:
            RegisterAbonoSheet(dependencies: dependencies, instructions: model.paydayInstructions)
        case .dailyReview:
            DailyReviewSheet(dependencies: dependencies)
        case .briefing:
            BriefingView(dependencies: dependencies) { route = nil }
        case .budget:
            NavigationStack {
                BudgetView(dependencies: dependencies)
            }
            .modalPresentation()
        case .strategy:
            NavigationStack {
                DebtsView(dependencies: dependencies)
            }
            .modalPresentation()
        }
    }
}
