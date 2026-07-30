import SwiftUI

/// The app's colours, defined once.
///
/// Deliberately quiet: debt is stressful enough without a red interface. Warning
/// colours appear only where something actually needs attention, and progress is
/// shown in a calm green rather than a celebratory one.
enum Palette {
    /// Page background.
    static let canvas = Color(light: Color(white: 0.97), dark: Color(white: 0.06))
    /// Card background, one step off the canvas.
    static let surface = Color(light: .white, dark: Color(white: 0.12))
    /// A pressed or secondary surface.
    static let surfaceMuted = Color(light: Color(white: 0.94), dark: Color(white: 0.17))

    static let primaryText = Color(light: Color(white: 0.08), dark: Color(white: 0.96))
    static let secondaryText = Color(light: Color(white: 0.42), dark: Color(white: 0.65))
    static let tertiaryText = Color(light: Color(white: 0.58), dark: Color(white: 0.48))

    /// Accent for actions and the active plan.
    static let accent = Color(light: Color(red: 0.09, green: 0.42, blue: 0.35), dark: Color(red: 0.36, green: 0.82, blue: 0.65))
    /// Progress and good news.
    static let positive = Color(light: Color(red: 0.13, green: 0.55, blue: 0.36), dark: Color(red: 0.40, green: 0.83, blue: 0.58))
    /// Something to look at, not an emergency.
    static let caution = Color(light: Color(red: 0.72, green: 0.50, blue: 0.10), dark: Color(red: 0.95, green: 0.75, blue: 0.35))
    /// Reserved for real problems: a month that does not close.
    static let critical = Color(light: Color(red: 0.70, green: 0.24, blue: 0.20), dark: Color(red: 0.94, green: 0.48, blue: 0.42))
    /// Debt totals and balances.
    static let debt = Color(light: Color(red: 0.35, green: 0.30, blue: 0.55), dark: Color(red: 0.68, green: 0.63, blue: 0.92))

    static let hairline = Color(light: Color(white: 0.90), dark: Color(white: 0.22))

    static func color(for severity: PlanWarning.Severity) -> Color {
        switch severity {
        case .info: accent
        case .caution: caution
        case .critical: critical
        }
    }

    static func color(for difficulty: PlanDifficulty) -> Color {
        switch difficulty {
        case .comfortable: positive
        case .moderate: accent
        case .demanding: caution
        case .veryDemanding: critical
        }
    }
}

private extension Color {
    /// Resolves per appearance, so every token supports light and dark without
    /// an asset catalog entry.
    init(light: Color, dark: Color) {
        self = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
