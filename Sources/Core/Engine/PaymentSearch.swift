import Foundation

/// Finds the smallest payment that reaches a goal, by bisection.
///
/// Every projection is monotonic. Paying more never delays the payoff. So
/// bisection is both valid and cheap, and it is the reason the app can answer
/// "what would I need to pay to finish in December?" instantly.
struct PaymentSearch: Sendable {
    private let iterations: Int

    init(iterations: Int = 24) {
        self.iterations = iterations
    }

    /// - Parameters:
    ///   - upperBound: the most that could possibly be paid.
    ///   - succeeds: whether a given payment reaches the goal.
    /// - Returns: the smallest amount that succeeds, or nil if even `upperBound` fails.
    func smallestAmount(upTo upperBound: Money, succeeds: (Money) -> Bool) -> Money? {
        guard upperBound > 0 else { return succeeds(0) ? 0 : nil }
        guard succeeds(upperBound) else { return nil }
        if succeeds(0) { return 0 }

        var low = Money.zero
        var high = upperBound

        for _ in 0..<iterations {
            let mid = ((low + high) / 2).rounded
            if mid <= low || mid >= high { break }
            if succeeds(mid) { high = mid } else { low = mid }
        }

        return high.rounded
    }
}
