import Foundation

/// Maps a strategy to its implementation. The only place in the app that knows
/// the full set, so callers depend on `DebtPrioritizing` and nothing else.
struct DebtPrioritizerFactory: Sendable {
    func prioritizer(for strategy: PayoffStrategy) -> DebtPrioritizing {
        switch strategy {
        case .avalanche: AvalanchePrioritizer()
        case .snowball: SnowballPrioritizer()
        case .custom: CustomPrioritizer()
        }
    }
}
