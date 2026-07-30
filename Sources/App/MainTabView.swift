import SwiftUI

/// The five places the app lives, in the order they matter: today, the debts, the
/// budget, the goals, and the settings behind them.
struct MainTabView: View {
    let dependencies: AppDependencies
    @State private var selection: Tab = .home

    private enum Tab: Hashable {
        case home, debts, budget, goals, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView(dependencies: dependencies, model: makeHomeModel())
            }
            .tabItem { Label("Hoy", systemImage: "house") }
            .tag(Tab.home)

            NavigationStack {
                DebtsView(dependencies: dependencies)
            }
            .tabItem { Label("Deudas", systemImage: "creditcard") }
            .tag(Tab.debts)

            NavigationStack {
                BudgetView(dependencies: dependencies)
            }
            .tabItem { Label("Presupuesto", systemImage: "chart.pie") }
            .tag(Tab.budget)

            NavigationStack {
                GoalsView(dependencies: dependencies)
            }
            .tabItem { Label("Metas", systemImage: "target") }
            .tag(Tab.goals)

            NavigationStack {
                SettingsView(dependencies: dependencies)
            }
            .tabItem { Label("Ajustes", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
        .task { await scheduleNotifications() }
    }

    private func makeHomeModel() -> HomeViewModel {
        HomeViewModel(
            planStore: dependencies.planStore,
            progress: BudgetProgressCalculator(expenses: dependencies.expenses),
            debts: dependencies.debts,
            subscriptions: dependencies.subscriptions,
            utilities: dependencies.utilities,
            goals: dependencies.goals,
            reviews: dependencies.reviews
        )
    }

    /// Reminders follow the plan, so they are rebuilt whenever the app starts with
    /// notifications enabled.
    private func scheduleNotifications() async {
        let profile = dependencies.profile
        guard profile.notificationsEnabled else { return }
        guard await dependencies.notifications.requestAuthorization() else { return }

        await dependencies.notifications.reschedule(
            for: dependencies.planStore.activePlan,
            snapshot: dependencies.planStore.snapshot,
            reminder: DailyReminder(
                hour: profile.reminderHour,
                minute: profile.reminderMinute,
                isEnabled: profile.notificationsEnabled
            )
        )
    }
}
