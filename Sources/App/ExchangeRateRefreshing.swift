import SwiftUI

/// Keeps exchange rates current while the app is being used.
///
/// Rates are published once a day, so the app asks at launch and again whenever it
/// comes back to the foreground: a session left open overnight would otherwise keep
/// converting with yesterday's number. The provider decides whether the request is
/// worth making, so calling this often is free.
///
/// Nothing here reports failure. Offline is not an error the user has to handle, it
/// just means the rates already in hand stay in use.
private struct ExchangeRateRefresh: ViewModifier {
    let provider: LiveExchangeRateProvider

    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task { await provider.refresh() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await provider.refresh() }
            }
    }
}

extension View {
    func refreshingExchangeRates(with provider: LiveExchangeRateProvider) -> some View {
        modifier(ExchangeRateRefresh(provider: provider))
    }
}
