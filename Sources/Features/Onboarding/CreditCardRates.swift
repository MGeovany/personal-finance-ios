import Foundation

/// An estimated annual rate for a card, and when that estimate was last gone over.
///
/// The date travels with the number on purpose. A rate shown without one reads as a
/// fact the app looked up, when it is really a table somebody maintained by hand.
struct CreditCardRateEstimate: Equatable {
    let percent: Double
    let reviewedOn: Date
    /// True when the card's tier was recognised, so the estimate is narrower than the
    /// generic default for the whole category.
    let isTierSpecific: Bool
}

/// Estimates a card's rate from its tier.
///
/// Nobody knows their interest rate, and sending them to find a statement is how
/// setup gets abandoned. So the app guesses, says out loud that it guessed, and lets
/// the number be corrected in place.
///
/// The guess is a tier heuristic, not a quoted price: premium cards in Honduras
/// generally sit at the lower end of the market range and entry cards at the upper
/// end. Every value stays inside the range already documented on
/// `DebtKind.creditCard.typicalRates`, so a wrong tier still yields a plausible plan.
enum CreditCardRates {
    /// The day this table was last reviewed by hand. Shown to the user verbatim.
    ///
    /// Built from components rather than `Date()` so it means "when the table was
    /// written" and not "whenever the app happened to run".
    static let reviewedOn: Date = {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 7
        parts.day = 30
        return Calendar(identifier: .gregorian).date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }()

    /// Tier keywords, highest rate first, matched against the card's name.
    ///
    /// Both the English product name and the Spanish one people say out loud are
    /// listed, because a card typed by hand may arrive either way.
    private static let tiers: [(keywords: [String], percent: Double)] = [
        (["classic", "clasica", "standard", "estandar"], 65),
        (["gold", "oro"], 58),
        (["platinum", "platino"], 52),
        (["signature"], 48),
        (["infinite", "black", "world elite"], 45),
    ]

    static func estimate(forCardNamed name: String) -> CreditCardRateEstimate {
        let normalized = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)

        for tier in tiers where tier.keywords.contains(where: normalized.contains) {
            return CreditCardRateEstimate(percent: tier.percent, reviewedOn: reviewedOn, isTierSpecific: true)
        }

        return CreditCardRateEstimate(
            percent: DebtKind.creditCard.assumedRate,
            reviewedOn: reviewedOn,
            isTierSpecific: false
        )
    }
}
