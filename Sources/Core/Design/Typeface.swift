import Foundation

/// The typefaces the app ships, and which one it is currently set in.
///
/// Trying a different one used to mean rewriting every face name in the design
/// system. Naming them here makes it a one line change, and lets a typeface that is
/// not in use stay in the project rather than being deleted and re-downloaded the
/// next time somebody wants to compare.
enum Typeface: String, CaseIterable, Identifiable {
    case googleSansFlex
    case quicksand
    case elmsSans

    var id: String { rawValue }

    /// The typeface the app is set in. Change this line to change the whole app.
    static let active: Typeface = .googleSansFlex

    /// As the foundry writes it, for anywhere the app credits its own type.
    var displayName: String {
        switch self {
        case .googleSansFlex: "Google Sans Flex"
        case .quicksand: "Quicksand"
        case .elmsSans: "Elms Sans"
        }
    }

    /// Base names of the files in the bundle, without extensions.
    ///
    /// One file for a variable font, whose weights are named instances Core Text
    /// resolves on its own. One file per weight for a family that ships static cuts.
    /// Either way the faces below are what a view ends up asking for.
    var fileNames: [String] {
        switch self {
        case .googleSansFlex:
            faces.all
        case .quicksand:
            ["Quicksand-Variable"]
        case .elmsSans:
            ["ElmsSans-Variable"]
        }
    }

    /// PostScript names of the weights the app asks for.
    ///
    /// All three families happen to name their weights the same way. One that did not
    /// would spell its faces out here and nothing else would have to know.
    var faces: Faces {
        switch self {
        case .googleSansFlex: Faces(prefix: "GoogleSansFlex")
        case .quicksand: Faces(prefix: "Quicksand")
        case .elmsSans: Faces(prefix: "ElmsSans")
        }
    }

    struct Faces {
        let light: String
        let regular: String
        let medium: String
        let semibold: String
        let bold: String

        /// For families that follow the usual `Family-Weight` convention.
        init(prefix: String) {
            light = "\(prefix)-Light"
            regular = "\(prefix)-Regular"
            medium = "\(prefix)-Medium"
            semibold = "\(prefix)-SemiBold"
            bold = "\(prefix)-Bold"
        }

        var all: [String] { [light, regular, medium, semibold, bold] }
    }
}
