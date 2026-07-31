import SwiftUI

/// The main shell: four tabs around a center add button.
///
/// The cradle bar is drawn by the shell rather than `TabView`, so the layout can
/// stay two-and-two around the plus without fighting the system tab bar. Ajustes
/// lives behind the gear on Home so the bar stays balanced.
struct MainTabView: View {
    let dependencies: AppDependencies

    @State private var selection: MainTab = .home
    @State private var showsAddExpense = false

    var body: some View {
        tabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                MainTabBar(selection: $selection, onAdd: { showsAddExpense = true })
            }
            .ignoresSafeArea(.keyboard)
            .sheet(isPresented: $showsAddExpense) {
                AddExpenseSheet(dependencies: dependencies)
            }
            .task { await dependencies.refreshReminders() }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selection {
        case .home:
            NavigationStack {
                HomeView(dependencies: dependencies, model: makeHomeModel())
            }
        case .debts:
            NavigationStack {
                DebtsView(dependencies: dependencies)
            }
        case .budget:
            NavigationStack {
                BudgetView(dependencies: dependencies)
            }
        case .goals:
            NavigationStack {
                GoalsView(dependencies: dependencies)
            }
        }
    }

    private func makeHomeModel() -> HomeViewModel {
        HomeViewModel(
            planStore: dependencies.planStore,
            progress: BudgetProgressCalculator(expenses: dependencies.expenses),
            expenses: dependencies.expenses,
            debts: dependencies.debts,
            subscriptions: dependencies.subscriptions,
            utilities: dependencies.utilities,
            goals: dependencies.goals,
            briefingProvider: dependencies.briefingProvider,
            briefingPresenter: dependencies.briefingPresenter,
            payday: dependencies.paydayStatus
        )
    }
}
