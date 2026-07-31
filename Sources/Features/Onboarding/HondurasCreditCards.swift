import Foundation

/// Banks and card products people in Honduras actually carry.
///
/// Setup offers these as a list so naming a card is recognition, not a blank form.
/// BAC and Ficohsa come first. They are the ones most users will look for.
///
/// Tiers keep the issuer's own English names, `Visa Gold` rather than `Visa Oro`,
/// because that is what is printed on the plastic and what the banking app shows. A
/// translated tier would send the user looking for a card they do not have.
enum HondurasCreditCards {
    struct Bank: Identifiable, Hashable {
        let name: String
        let cards: [String]

        var id: String { name }
    }

    static let banks: [Bank] = [
        Bank(
            name: "BAC",
            cards: [
                "BAC Visa Classic",
                "BAC Visa Gold",
                "BAC Visa Platinum",
                "BAC Visa Signature",
                "BAC Visa Infinite",
                "BAC Mastercard Gold",
                "BAC Mastercard Black",
                "BAC Cash Back",
                "BAC Premia",
            ]
        ),
        Bank(
            name: "Ficohsa",
            cards: [
                "Ficohsa Visa Classic",
                "Ficohsa Visa Gold",
                "Ficohsa Visa Platinum",
                "Ficohsa Visa Signature",
                "Ficohsa Mastercard Gold",
                "Ficohsa Mastercard Black",
                "Ficohsa Rewards",
            ]
        ),
        Bank(
            name: "Atlántida",
            cards: [
                "Atlántida Visa Classic",
                "Atlántida Visa Gold",
                "Atlántida Visa Platinum",
                "Atlántida Visa Infinite",
                "Atlántida Mastercard Gold",
            ]
        ),
        Bank(
            name: "Banpaís",
            cards: [
                "Banpaís Visa Classic",
                "Banpaís Visa Gold",
                "Banpaís Visa Platinum",
                "Banpaís Mastercard Gold",
            ]
        ),
        Bank(
            name: "Banrural",
            cards: [
                "Banrural Visa Classic",
                "Banrural Visa Gold",
                "Banrural Mastercard Gold",
            ]
        ),
        Bank(
            name: "Davivienda",
            cards: [
                "Davivienda Visa Classic",
                "Davivienda Visa Gold",
                "Davivienda Visa Platinum",
                "Davivienda Mastercard Gold",
            ]
        ),
        Bank(
            name: "Occidente",
            cards: [
                "Occidente Visa Classic",
                "Occidente Visa Gold",
                "Occidente Mastercard Gold",
            ]
        ),
    ]

    static func cards(for bank: String) -> [String] {
        banks.first { $0.name.caseInsensitiveCompare(bank) == .orderedSame }?.cards ?? []
    }

    /// Whether a name came from one of the offered lists.
    ///
    /// What makes it safe to clear the card when the bank changes: a suggestion from
    /// the wrong bank is stale, while a name the user typed is theirs and stays.
    static func isSuggestion(_ card: String) -> Bool {
        let trimmed = card.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return banks.contains { bank in
            bank.cards.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        }
    }
}
