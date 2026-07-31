import SwiftUI

/// What a modal's confirming or dismissing button does.
struct ModalAction {
    let title: String
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    let handler: () -> Void

    init(_ title: String, isEnabled: Bool = true, isDestructive: Bool = false, handler: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.isDestructive = isDestructive
        self.handler = handler
    }
}

/// The chrome every modal in the app shares: a centred title, a round close
/// button, scrolling content on the page colour, and the confirming action pinned
/// to the bottom where a thumb already is.
///
/// Sheets used to be `Form`s, which meant each one inherited whatever the system
/// list style looked like. Going through one scaffold is what keeps twenty modals
/// looking like one app.
struct ModalScaffold<Content: View>: View {
    let title: String
    var subtitle: String?
    /// The confirming action. Absent for modals that only show something.
    var primary: ModalAction?
    /// An extra action under the primary one, for a second path out.
    var secondary: ModalAction?
    /// Hidden when the modal is a result the user must acknowledge.
    var showsClose: Bool = true
    /// The default suits sections with headers and footers; modals that stack plain
    /// cards want them closer together.
    var spacing: CGFloat = Layout.sectionGap
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    content()
                }
                .padding(.horizontal, DesignSystem.Space.xxl)
                .padding(.top, DesignSystem.Space.l)
                .padding(.bottom, DesignSystem.Space.xxxl)
            }
            .scrollDismissesKeyboard(.interactively)

            footer
        }
        .background(Palette.canvas)
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, DesignSystem.Space.xl)

            if showsClose {
                HStack {
                    Spacer()
                    IconButton(systemImage: "xmark", label: "Cerrar") { dismiss() }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Space.xxl)
        .padding(.top, DesignSystem.Space.xxl)
        .padding(.bottom, DesignSystem.Space.s)
    }

    @ViewBuilder
    private var footer: some View {
        if primary != nil || secondary != nil {
            VStack(spacing: DesignSystem.Space.s) {
                if let primary {
                    Button(primary.title) {
                        primary.handler()
                    }
                    .disabled(!primary.isEnabled)
                    .primaryButton(
                        tint: primary.isDestructive ? Palette.critical : Palette.accent,
                        isEnabled: primary.isEnabled
                    )
                }

                if let secondary {
                    Button(secondary.title, action: secondary.handler)
                        .disabled(!secondary.isEnabled)
                        .quietButton(tint: secondary.isDestructive ? Palette.critical : Palette.secondaryText)
                }
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.l)
            .padding(.bottom, DesignSystem.Space.s)
            .background(alignment: .top) {
                // Enough of a lift that the button never looks like it is floating
                // over nothing when content scrolls behind it.
                Rectangle()
                    .fill(Palette.canvas)
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, y: -6)
            }
        }
    }
}

extension View {
    /// The presentation treatment for every sheet: the page colour behind it, the
    /// system grabber hidden because the modal draws its own close button, and a
    /// corner radius matching the app's cards.
    func modalPresentation() -> some View {
        presentationBackground(Palette.canvas)
            .presentationCornerRadius(Layout.modalRadius)
            .presentationDragIndicator(.hidden)
    }
}
