import SwiftUI

/// The liquid-glass surface language: soft extruded whites, a black primary, and
/// depth made of light rather than borders.
///
/// On iOS 26 the system glass material is used so buttons and cards refract what
/// sits behind them. Below that, the same look is approximated with layered
/// shadows and a faint top highlight. The reference's "pressed out of the page"
/// reading.
enum LiquidGlass {
    /// A soft white fill with a hair of translucency, for secondary pills and
    /// icon wells when system glass is unavailable.
    static let fill = Color.white.opacity(0.94)

    /// The black primary, slightly lifted at the top so a pill reads as rounded
    /// volume rather than a flat sticker.
    static let primaryGradient = LinearGradient(
        colors: [Color(white: 0.16), Color(white: 0.04)],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension View {
    /// The extruded liquid-glass treatment: soft dark below, white rim above.
    func softShadow(_ elevation: DesignSystem.Elevation = .raised) -> some View {
        let ambient = elevation.ambient
        let contact = elevation.contact
        let highlight = elevation.highlight
        return self
            .shadow(color: ambient.color, radius: ambient.radius, x: 0, y: ambient.y)
            .shadow(color: contact.color, radius: contact.radius, x: 0, y: contact.y)
            .shadow(color: highlight.color, radius: highlight.radius, x: 0, y: highlight.y)
    }

    /// A card or panel in liquid glass: system glass on iOS 26, solid white
    /// everywhere else. Callers add `softShadow` on older iOS.
    @ViewBuilder
    func liquidCard(cornerRadius: CGFloat = Layout.cardRadius) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(Palette.surface, in: shape)
        }
    }
}
