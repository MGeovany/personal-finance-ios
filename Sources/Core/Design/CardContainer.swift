import SwiftUI

/// The app's one card shape. Everything that groups information sits in one of
/// these, which is what keeps the screens feeling like a single surface.
///
/// Soft white on a warm page, lifted by liquid-glass shadows rather than a border . 
/// the same treatment as the account card in the reference.
struct CardContainer<Content: View>: View {
    private let padding: CGFloat
    private let elevation: DesignSystem.Elevation
    private let content: Content

    init(
        padding: CGFloat = Layout.cardPadding,
        elevation: DesignSystem.Elevation = .raised,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.elevation = elevation
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
            .softShadow(elevation)
    }
}

/// A group of related rows in a card, with the small heading above it and the
/// explanatory caption below it that a `Section` header and footer used to provide.
struct CardSection<Content: View>: View {
    var header: String?
    var footer: String?
    var padding: CGFloat = Layout.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
            if let header {
                Text(header)
                    .sectionHeaderStyle()
                    .padding(.horizontal, DesignSystem.Space.xxs)
            }

            CardContainer(padding: padding) {
                VStack(alignment: .leading, spacing: Layout.gap) {
                    content()
                }
            }

            if let footer {
                Text(footer)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .padding(.horizontal, DesignSystem.Space.xxs)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A card that reacts to being tapped, for rows that open a detail screen.
struct TappableCard<Content: View>: View {
    private let action: () -> Void
    private let content: Content

    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            CardContainer { content }
        }
        .buttonStyle(PressableCardStyle())
    }
}

/// Presses a card slightly into the page instead of dimming it.
private struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(DesignSystem.Motion.tap, value: configuration.isPressed)
    }
}
