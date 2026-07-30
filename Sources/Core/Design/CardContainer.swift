import SwiftUI

/// The app's one card shape. Everything that groups information sits in one of
/// these, which is what keeps the screens feeling like a single surface.
struct CardContainer<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = Layout.cardPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
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
        .buttonStyle(.plain)
    }
}
