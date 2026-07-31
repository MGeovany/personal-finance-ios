import SwiftUI
import SwiftData

@main
struct CeroApp: App {
    /// Built once and passed down. Nothing in the app reaches for a global.
    @State private var dependencies = AppDependencies.live()

    init() {
        FontRegistration.register()
        Appearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .modelContainer(dependencies.container)
                .environment(dependencies)
                // Amount fields format and convert wherever they appear, which is
                // too deep to thread these through by hand.
                .environment(\.moneyFormatter, dependencies.money)
                .environment(\.exchangeRates, dependencies.exchangeRates)
                .environment(\.planDates, dependencies.dates)
                .environment(\.planCurrency, dependencies.currency)
                .tint(Palette.accent)
                .background(Palette.canvas)
        }
    }
}
