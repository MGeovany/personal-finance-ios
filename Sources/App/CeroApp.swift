import SwiftUI
import SwiftData

@main
struct CeroApp: App {
    /// Built once and passed down. Nothing in the app reaches for a global.
    @State private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .modelContainer(dependencies.container)
                .environment(dependencies)
                .tint(Palette.accent)
        }
    }
}
