import SwiftUI

// MARK: - Tokens

/// The style system: every colour, typeface, measurement, shadow and duration the
/// app is allowed to use.
///
/// Liquid glass, monochrome: a warm off-white page, soft white cards and pills
/// lifted by light, and a single black primary action. The only colour that ever
/// appears carries meaning. Green when something is on track, red when something
/// is wrong.
///
/// Views do not reach in here directly. They use the semantic layers below
/// (`Palette`, `Typography`, `Layout`), which is what makes a change to a token
/// land everywhere at once.
enum DesignSystem {

    /// The monochrome ramp, from the page up to pure white and down to black.
    ///
    /// Tuned a hair warm so white glass cards can lift off it the way they do in
    /// the liquid-glass reference. A cold grey makes the same shadows look dirty.
    enum Ink {
        /// The page itself: soft warm grey, so white cards and pills can float.
        static let canvas = Color(red: 0.945, green: 0.943, blue: 0.938)
        /// Below the page, for wells and pressed states.
        static let sunken = Color(red: 0.905, green: 0.902, blue: 0.896)
        /// A card.
        static let surface = Color.white
        /// A field or a secondary control sitting on a card.
        static let muted = Color(red: 0.935, green: 0.932, blue: 0.928)

        static let ink900 = Color(white: 0.06)
        static let ink700 = Color(white: 0.32)
        static let ink500 = Color(white: 0.52)
        static let ink300 = Color(white: 0.68)
        static let ink200 = Color(white: 0.80)
        static let ink100 = Color(white: 0.90)

        static let black = Color(white: 0.06)
        static let white = Color.white
    }

    /// The only two hues in the app. Both mean something; neither is decoration.
    enum Feedback {
        /// On track, paid, saved, done.
        static let success = Color(red: 0.106, green: 0.498, blue: 0.294)
        static let successSurface = Color(red: 0.906, green: 0.957, blue: 0.925)

        /// A real problem: a month that does not close, a plan that breaks.
        static let danger = Color(red: 0.702, green: 0.149, blue: 0.118)
        static let dangerSurface = Color(red: 0.984, green: 0.918, blue: 0.910)
    }

    /// The weights the app draws with, taken from whichever typeface is active.
    ///
    /// Which family that is lives in `Typeface`, so a view never names a font and
    /// swapping the whole app's type is one line there. If a face name is wrong the
    /// system silently substitutes San Francisco, which is why registration is
    /// checked at launch.
    ///
    /// Neither family ships a separate optical cut for large sizes, so the display
    /// faces are the same drawings at a heavier weight. They stay named apart because
    /// that is what the call sites mean, and because a real display cut would slot in
    /// here without touching a single view.
    enum Face {
        static let light = Typeface.active.faces.light
        static let regular = Typeface.active.faces.regular
        static let medium = Typeface.active.faces.medium
        static let semibold = Typeface.active.faces.semibold
        static let bold = Typeface.active.faces.bold
        static let displayRegular = regular
        static let displaySemibold = semibold
        static let displayBold = bold

        /// The distinct faces the app asks for, used to verify they all loaded.
        static let all: [String] = Typeface.active.faces.all
    }

    /// Corner radii. Everything in the liquid-glass reference is soft: pills for
    /// actions, large continuous curves for cards.
    enum Radius {
        static let field: CGFloat = 18
        static let control: CGFloat = 20
        static let card: CGFloat = 32
        static let modal: CGFloat = 36
        /// Used with `Capsule()`, kept here so the intent is documented.
        static let pill: CGFloat = 999
    }

    /// The spacing scale. Nothing in the app should invent a gap between these.
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    /// Durations and curves, named after what they are for rather than their values,
    /// so motion stays consistent when one of them is tuned.
    enum Motion {
        /// A control responding to a tap.
        static let tap = Animation.spring(response: 0.28, dampingFraction: 0.78)
        /// A value or a label being replaced.
        static let swap = Animation.spring(response: 0.34, dampingFraction: 0.72)
        /// A drawer or a modal arriving.
        static let present = Animation.spring(response: 0.42, dampingFraction: 0.86)
        /// A drawer or a modal leaving, faster than it arrived.
        static let dismiss = Animation.easeOut(duration: 0.22)
    }

    /// How far a surface sits off the page.
    ///
    /// Liquid glass is three stacked lights: a wide ambient pool, a tighter
    /// contact shadow that pins the edge, and a white rim above that reads as the
    /// surface catching light. Without all three, pills look stuck on rather than
    /// poured.
    enum Elevation {
        /// Flush with the page. No shadow.
        case flush
        /// A card or a secondary pill.
        case raised
        /// A primary action, a floating bar. Anything that must lift further.
        case floating

        var ambient: (color: Color, radius: CGFloat, y: CGFloat) {
            switch self {
            case .flush: (.clear, 0, 0)
            case .raised: (Color.black.opacity(0.06), 22, 10)
            case .floating: (Color.black.opacity(0.12), 30, 14)
            }
        }

        var contact: (color: Color, radius: CGFloat, y: CGFloat) {
            switch self {
            case .flush: (.clear, 0, 0)
            case .raised: (Color.black.opacity(0.04), 6, 2)
            case .floating: (Color.black.opacity(0.08), 8, 3)
            }
        }

        var highlight: (color: Color, radius: CGFloat, y: CGFloat) {
            switch self {
            case .flush: (.clear, 0, 0)
            case .raised: (Color.white.opacity(0.95), 10, -5)
            case .floating: (Color.white.opacity(0.80), 12, -6)
            }
        }
    }
}

// MARK: - Colour, by meaning

/// The app's colours, named for what they are used for.
///
/// Deliberately quiet: debt is stressful enough without a red interface. Red
/// appears only where something has actually gone wrong, and progress is shown in
/// a calm green rather than a celebratory one.
enum Palette {
    /// Page background.
    static let canvas = DesignSystem.Ink.canvas
    /// Card background, one step off the canvas.
    static let surface = DesignSystem.Ink.surface
    /// A pressed or secondary surface.
    static let surfaceMuted = DesignSystem.Ink.muted
    /// A well: an input, a track, anything content sits inside of.
    static let surfaceSunken = DesignSystem.Ink.sunken

    static let primaryText = DesignSystem.Ink.ink900
    static let secondaryText = DesignSystem.Ink.ink700
    static let tertiaryText = DesignSystem.Ink.ink500
    /// Text on top of a filled black control.
    static let invertedText = DesignSystem.Ink.white

    /// Actions and the active plan. Black: the only emphasis the app needs.
    static let accent = DesignSystem.Ink.ink900
    /// Progress and good news.
    static let positive = DesignSystem.Feedback.success
    /// Something to look at, not an emergency. Weight rather than hue.
    static let caution = DesignSystem.Ink.ink900
    /// Reserved for real problems: a month that does not close.
    static let critical = DesignSystem.Feedback.danger
    /// Debt totals and balances.
    static let debt = DesignSystem.Ink.ink900

    static let hairline = DesignSystem.Ink.ink100

    static func color(for severity: PlanWarning.Severity) -> Color {
        switch severity {
        case .info: tertiaryText
        case .caution: caution
        case .critical: critical
        }
    }

    /// Low plans read calm (cyan), the middle reads on-track (green), aggressive
    /// plans read hot (red).
    static func color(for difficulty: PlanDifficulty) -> Color {
        switch difficulty {
        case .comfortable: cyan
        case .moderate: positive
        case .demanding, .veryDemanding: critical
        }
    }

    /// Soft cyan for the easiest plan signal.
    static let cyan = Color(red: 0.05, green: 0.72, blue: 0.82)

    /// The faint fill behind a tinted chip or banner. Feedback hues get their own
    /// tuned surface; ink is simply thinned.
    static func surface(for tint: Color) -> Color {
        if tint == positive { return DesignSystem.Feedback.successSurface }
        if tint == critical { return DesignSystem.Feedback.dangerSurface }
        return surfaceMuted
    }
}

// MARK: - Type

/// Text styles.
///
/// The scale is built around one idea: the number that answers the user's
/// question is large, and everything else steps well back from it.
enum Typography {
    /// The single most important number on a screen. The balance in the reference.
    static let hero = display(40, .displayBold).monospacedDigit()
    /// A primary number inside a card.
    static let statistic = display(28, .displayBold).monospacedDigit()
    /// A secondary number, in a row or a comparison column.
    static let amount = text(17, .semibold).monospacedDigit()

    static let title = display(22, .displaySemibold)
    static let titleSmall = text(17, .semibold)
    static let sectionTitle = text(11, .medium)
    /// Body sits on Light so the page breathes; Medium carries button labels and
    /// anything the thumb has to read at a glance.
    static let body = text(15, .light)
    static let bodyStrong = text(15, .medium)
    static let label = text(15, .medium)
    static let caption = text(12, .light)
    static let captionStrong = text(12, .medium)

    /// Weights, spelled out so call sites read as design rather than font names.
    enum Weight {
        case light, regular, medium, semibold, bold
        case displayRegular, displaySemibold, displayBold

        var faceName: String {
            switch self {
            case .light: DesignSystem.Face.light
            case .regular: DesignSystem.Face.regular
            case .medium: DesignSystem.Face.medium
            case .semibold: DesignSystem.Face.semibold
            case .bold: DesignSystem.Face.bold
            case .displayRegular: DesignSystem.Face.displayRegular
            case .displaySemibold: DesignSystem.Face.displaySemibold
            case .displayBold: DesignSystem.Face.displayBold
            }
        }
    }

    /// An arbitrary size in the app's typeface, for the few places the scale above
    /// does not cover.
    static func text(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        .custom(weight.faceName, size: size)
    }

    /// The optically corrected cut, for sizes above roughly 20pt.
    static func display(_ size: CGFloat, _ weight: Weight = .displaySemibold) -> Font {
        .custom(weight.faceName, size: size)
    }
}

extension View {
    /// Section headers: small, spaced, quiet. The "ACCOUNT BALANCE:" treatment.
    func sectionHeaderStyle() -> some View {
        font(Typography.sectionTitle)
            .textCase(.uppercase)
            .kerning(1.2)
            .foregroundStyle(Palette.tertiaryText)
    }
}

// MARK: - Measurements

/// Spacing and shape constants, so cards and gaps match everywhere.
enum Layout {
    static let gutter = DesignSystem.Space.xl
    static let cardPadding = DesignSystem.Space.l
    static let tightGap = DesignSystem.Space.xs
    static let gap = DesignSystem.Space.m
    static let sectionGap = DesignSystem.Space.xxl

    static let cardRadius = DesignSystem.Radius.card
    static let chipRadius = DesignSystem.Radius.control
    static let fieldRadius = DesignSystem.Radius.field
    static let modalRadius = DesignSystem.Radius.modal

    static let controlHeight: CGFloat = 54
    /// A circular icon button, as in the header of the reference.
    static let iconButton: CGFloat = 46
    /// Minimum tap target.
    static let minimumTouch: CGFloat = 44
}
