import SwiftUI

/// Text styles.
///
/// The scale is built around one idea: the number that answers the user's
/// question is large, and everything else steps well back from it.
enum Typography {
    /// The single most important number on a screen.
    static let hero = Font.system(size: 44, weight: .semibold, design: .rounded).monospacedDigit()
    /// A primary number inside a card.
    static let statistic = Font.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit()
    /// A secondary number, in a row or a comparison column.
    static let amount = Font.system(size: 17, weight: .medium, design: .rounded).monospacedDigit()

    static let title = Font.system(size: 22, weight: .semibold)
    static let sectionTitle = Font.system(size: 13, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let label = Font.system(size: 14, weight: .medium)
    static let caption = Font.system(size: 12, weight: .regular)
}

extension View {
    /// Section headers: small, spaced, quiet.
    func sectionHeaderStyle() -> some View {
        font(Typography.sectionTitle)
            .textCase(.uppercase)
            .kerning(0.6)
            .foregroundStyle(Palette.tertiaryText)
    }
}
