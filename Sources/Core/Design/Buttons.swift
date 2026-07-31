import SwiftUI

/// The filled action. One per screen at most: the app should always make the next
/// step obvious rather than offer five equal options.
///
/// Black liquid-glass pill. The only opaque action on a page of translucent
/// whites, which is what makes it the next step without needing colour.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Palette.accent
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.label)
            .foregroundStyle(isEnabled ? Palette.invertedText : Palette.tertiaryText)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.controlHeight)
            // Empty space around the label is not hit-testable by default.
            .contentShape(Capsule())
            .modifier(
                LiquidPrimaryModifier(
                    tint: tint,
                    isEnabled: isEnabled,
                    isPressed: configuration.isPressed
                )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignSystem.Motion.tap, value: configuration.isPressed)
    }
}

/// The quiet action next to a primary one: white liquid glass, lifted rather than
/// filled.
struct SecondaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.label)
            .foregroundStyle(isEnabled ? Palette.primaryText : Palette.tertiaryText)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.controlHeight)
            .contentShape(Capsule())
            .modifier(LiquidGlassCapsuleModifier(isPressed: configuration.isPressed || !isEnabled))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignSystem.Motion.tap, value: configuration.isPressed)
    }
}

/// No fill at all, for the third option in a stack and for anything that undoes
/// rather than does.
struct QuietButtonStyle: ButtonStyle {
    var tint: Color = Palette.secondaryText

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.label)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.minimumTouch)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
            .animation(DesignSystem.Motion.tap, value: configuration.isPressed)
    }
}

/// A compact pill that sits inline with content, rather than spanning the width.
struct CompactButtonStyle: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if isProminent {
                configuration.label
                    .font(Typography.captionStrong)
                    .foregroundStyle(Palette.invertedText)
                    .padding(.horizontal, DesignSystem.Space.l)
                    .frame(height: 38)
                    .contentShape(Capsule())
                    .modifier(
                        LiquidPrimaryModifier(
                            tint: Palette.accent,
                            isEnabled: true,
                            isPressed: configuration.isPressed
                        )
                    )
            } else {
                configuration.label
                    .font(Typography.captionStrong)
                    .foregroundStyle(Palette.primaryText)
                    .padding(.horizontal, DesignSystem.Space.l)
                    .frame(height: 38)
                    .contentShape(Capsule())
                    .modifier(LiquidGlassCapsuleModifier(isPressed: configuration.isPressed))
            }
        }
        .scaleEffect(configuration.isPressed ? 0.96 : 1)
        .animation(DesignSystem.Motion.tap, value: configuration.isPressed)
    }
}

/// A round button holding a single glyph: close, back, notifications, more.
///
/// The reference's circular wells. Extruded white glass with a soft rim.
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = Layout.iconButton
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.text(15, .medium))
            .foregroundStyle(isProminent ? Palette.invertedText : Palette.secondaryText)
            .frame(width: size, height: size)
            .contentShape(Circle())
            .modifier(
                LiquidGlassCircleModifier(
                    isProminent: isProminent,
                    isPressed: configuration.isPressed
                )
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(DesignSystem.Motion.tap, value: configuration.isPressed)
    }
}

extension View {
    func primaryButton(tint: Color = Palette.accent, isEnabled: Bool = true) -> some View {
        buttonStyle(PrimaryButtonStyle(tint: tint, isEnabled: isEnabled))
    }

    func secondaryButton(isEnabled: Bool = true) -> some View {
        buttonStyle(SecondaryButtonStyle(isEnabled: isEnabled))
    }

    func quietButton(tint: Color = Palette.secondaryText) -> some View {
        buttonStyle(QuietButtonStyle(tint: tint))
    }

    func compactButton(isProminent: Bool = false) -> some View {
        buttonStyle(CompactButtonStyle(isProminent: isProminent))
    }

    func iconButton(size: CGFloat = Layout.iconButton, isProminent: Bool = false) -> some View {
        buttonStyle(IconButtonStyle(size: size, isProminent: isProminent))
    }
}

/// A round icon button, spelled out so screens do not have to repeat the label and
/// accessibility wiring.
struct IconButton: View {
    let systemImage: String
    var label: String
    var size: CGFloat = Layout.iconButton
    var isProminent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
        }
        .iconButton(size: size, isProminent: isProminent)
        .accessibilityLabel(label)
    }
}

// MARK: - Glass modifiers

/// Applies the black (or tinted) primary pill. System glass on iOS 26; a soft
/// gradient fill everywhere else.
private struct LiquidPrimaryModifier: ViewModifier {
    let tint: Color
    let isEnabled: Bool
    let isPressed: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *), isEnabled {
            content.glassEffect(.regular.tint(tint).interactive(), in: Capsule())
        } else if isEnabled {
            content
                .background {
                    Capsule().fill(
                        tint == Palette.accent
                            ? AnyShapeStyle(LiquidGlass.primaryGradient)
                            : AnyShapeStyle(tint)
                    )
                }
                .softShadow(isPressed ? .flush : .floating)
        } else {
            content
                .background(Palette.surfaceMuted, in: Capsule())
        }
    }
}

/// White liquid-glass capsule for secondary and compact actions.
private struct LiquidGlassCapsuleModifier: ViewModifier {
    let isPressed: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *), !isPressed {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .background(LiquidGlass.fill, in: Capsule())
                .softShadow(isPressed ? .flush : .raised)
        }
    }
}

/// Circular well for icon buttons.
private struct LiquidGlassCircleModifier: ViewModifier {
    let isProminent: Bool
    let isPressed: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isProminent {
            if #available(iOS 26, *) {
                content.glassEffect(.regular.tint(Palette.accent).interactive(), in: Circle())
            } else {
                content
                    .background(Palette.accent, in: Circle())
                    .softShadow(isPressed ? .flush : .floating)
            }
        } else if #available(iOS 26, *), !isPressed {
            content.glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(LiquidGlass.fill, in: Circle())
                .softShadow(isPressed ? .flush : .raised)
        }
    }
}
