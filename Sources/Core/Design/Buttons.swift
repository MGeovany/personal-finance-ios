import SwiftUI

/// The filled action. One per screen at most: the app should always make the next
/// step obvious rather than offer five equal options.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Palette.accent
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.label)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.controlHeight)
            .background(
                (isEnabled ? tint : Palette.surfaceMuted),
                in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

/// The quiet action next to a primary one.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.label)
            .foregroundStyle(Palette.primaryText)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.controlHeight)
            .background(Palette.surfaceMuted, in: RoundedRectangle(cornerRadius: Layout.chipRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

extension View {
    func primaryButton(tint: Color = Palette.accent, isEnabled: Bool = true) -> some View {
        buttonStyle(PrimaryButtonStyle(tint: tint, isEnabled: isEnabled))
    }

    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
}
