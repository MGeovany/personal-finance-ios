import SwiftUI
import UIKit

/// Pushes the design system into the parts of the interface SwiftUI still renders
/// through UIKit.
///
/// The tab bar does not read `Typography`, so without this the app would be Inter
/// everywhere except the strip along the bottom of every screen.
///
/// Navigation bars are deliberately left alone: on iOS 26 they no longer honour the
/// appearance proxy, so the screens that need typographic control draw their own
/// `ScreenHeader` instead and hide the system title.
enum Appearance {
    static func apply() {
        applyTabBars()
    }

    private static func applyTabBars() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        // Opaque rather than blurred: content sliding under a near-white blur reads
        // as a smudge, not as depth.
        appearance.backgroundColor = UIColor(Palette.canvas)
        appearance.backgroundEffect = nil
        appearance.shadowColor = .clear

        for item in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            item.normal.titleTextAttributes = [
                .font: font(.medium, size: 10),
                .foregroundColor: UIColor(Palette.tertiaryText),
            ]
            item.selected.titleTextAttributes = [
                .font: font(.semibold, size: 10),
                .foregroundColor: UIColor(Palette.accent),
            ]
            item.normal.iconColor = UIColor(Palette.tertiaryText)
            item.selected.iconColor = UIColor(Palette.accent)
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = UIColor(Palette.accent)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Palette.tertiaryText)
    }

    /// Falls back to the system face if a font ever fails to register, so a missing
    /// resource degrades the type rather than crashing the app.
    private static func font(_ weight: Typography.Weight, size: CGFloat) -> UIFont {
        UIFont(name: weight.faceName, size: size)
            ?? .systemFont(ofSize: size, weight: systemWeight(for: weight))
    }

    private static func systemWeight(for weight: Typography.Weight) -> UIFont.Weight {
        switch weight {
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold, .displaySemibold: .semibold
        case .bold, .displayBold: .bold
        case .displayRegular: .regular
        }
    }
}
