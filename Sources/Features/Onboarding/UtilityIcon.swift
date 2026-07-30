import Foundation

/// Picks an icon for a utility from its name, so a list of user-typed services
/// still reads at a glance without asking them to choose a symbol.
enum UtilityIcon {
    static func suggestion(for name: String) -> String {
        let normalized = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)

        for (keywords, icon) in mapping {
            if keywords.contains(where: normalized.contains) { return icon }
        }
        return "bolt"
    }

    /// The common services first; anything unrecognised falls back to a bolt.
    private static let mapping: [(keywords: [String], icon: String)] = [
        (["luz", "electric", "energia"], "bolt"),
        (["agua", "water"], "drop"),
        (["internet", "fibra", "wifi"], "wifi"),
        (["telefono", "celular", "movil", "phone"], "phone"),
        (["gas"], "flame"),
        (["cable", "tv", "television"], "tv"),
        (["basura", "aseo"], "trash"),
        (["seguridad", "vigilancia"], "lock.shield"),
    ]

    /// The services the setup step offers as one-tap suggestions.
    static let commonServices = ["Luz", "Agua", "Internet", "Teléfono", "Gas"]
}
