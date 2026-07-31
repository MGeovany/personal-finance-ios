import SwiftUI

/// The title of a whole screen, drawn in the app's typeface with room for round
/// buttons beside it.
///
/// The system navigation bar would set this in San Francisco and, on iOS 26, cannot
/// be talked out of it, so the screens where the title carries weight draw it here
/// and hide the bar's own.
struct ScreenHeader<Accessory: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .center, spacing: Layout.gap) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.display(34, .displayBold))
                    .foregroundStyle(Palette.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundStyle(Palette.tertiaryText)
                }
            }

            Spacer(minLength: 0)

            accessory()
        }
        .padding(.top, DesignSystem.Space.s)
        .padding(.bottom, DesignSystem.Space.xxs)
    }
}

extension ScreenHeader where Accessory == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// The header of a pushed screen: the way back, then the title beneath it.
///
/// Pushed screens draw their own header for the same reason the tab screens do, and
/// so carry their own back button in place of the navigation bar's.
struct DetailHeader<Accessory: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var accessory: () -> Accessory

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.m) {
            HStack(spacing: Layout.gap) {
                IconButton(systemImage: "chevron.left", label: "Volver") { dismiss() }
                Spacer(minLength: 0)
                accessory()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.display(28, .displayBold))
                    .foregroundStyle(Palette.primaryText)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundStyle(Palette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.top, DesignSystem.Space.xs)
        .padding(.bottom, DesignSystem.Space.xxs)
    }
}

extension DetailHeader where Accessory == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

extension View {
    /// The treatment for a screen that draws its own `ScreenHeader` or
    /// `DetailHeader`: page colour behind it, and the system bar out of the way.
    func screenSurface() -> some View {
        background {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.958, blue: 0.952),
                    Palette.canvas,
                    Color(red: 0.93, green: 0.928, blue: 0.922),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// A section title, optionally with an action on the right.
struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).sectionHeaderStyle()
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Typography.captionStrong)
                    .foregroundStyle(Palette.accent)
            }
        }
    }
}

/// Shown when a list has nothing in it yet, with the action that fills it.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Layout.gap) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(Palette.tertiaryText)

            Text(title)
                .font(Typography.label)
                .foregroundStyle(Palette.primaryText)

            Text(message)
                .font(Typography.body)
                .foregroundStyle(Palette.secondaryText)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .primaryButton()
                    .padding(.top, Layout.tightGap)
            }
        }
        .padding(.vertical, Layout.sectionGap)
        .padding(.horizontal, Layout.cardPadding)
        .frame(maxWidth: .infinity)
    }
}
