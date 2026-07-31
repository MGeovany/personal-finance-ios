import Foundation

/// Banks and card products people in Honduras actually carry.
///
/// Setup offers these as taps so naming a card is recognition, not a blank form.
/// BAC and Ficohsa come first. They are the ones most users will look for.
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
                "BAC Visa Clásica",
                "BAC Visa Oro",
                "BAC Visa Signature",
                "BAC Visa Infinite",
                "BAC Mastercard Black",
                "BAC Cash Back",
                "BAC Premia",
            ]
        ),
        Bank(
            name: "Ficohsa",
            cards: [
                "Ficohsa Visa Clásica",
                "Ficohsa Visa Oro",
                "Ficohsa Visa Signature",
                "Ficohsa Mastercard Gold",
                "Ficohsa Mastercard Black",
                "Ficohsa Rewards",
            ]
        ),
        Bank(
            name: "Atlántida",
            cards: [
                "Atlántida Visa Clásica",
                "Atlántida Visa Oro",
                "Atlántida Visa Infinite",
                "Atlántida Mastercard",
            ]
        ),
        Bank(
            name: "Banpaís",
            cards: [
                "Banpaís Visa",
                "Banpaís Mastercard",
                "Banpaís Oro",
            ]
        ),
        Bank(
            name: "Banrural",
            cards: [
                "Banrural Visa",
                "Banrural Mastercard",
            ]
        ),
        Bank(
            name: "Davivienda",
            cards: [
                "Davivienda Visa",
                "Davivienda Mastercard",
            ]
        ),
        Bank(
            name: "Occidente",
            cards: [
                "Occidente Visa",
                "Occidente Mastercard",
            ]
        ),
    ]

    static func cards(for bank: String) -> [String] {
        banks.first { $0.name.caseInsensitiveCompare(bank) == .orderedSame }?.cards ?? []
    }
}
