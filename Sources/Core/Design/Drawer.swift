import SwiftUI

/// A short panel that rises from the bottom edge.
///
/// Where a modal is a place you go to do work, a drawer is a single question
/// answered in one tap: pick a currency, pick a strategy, confirm a deletion. It
/// sizes itself to whatever it holds, so it never covers more of the screen than
/// the question needs.
struct Drawer<Content: View>: View {
    let title: String
    var message: String?
    /// The way out when the drawer is a question rather than a list.
    var cancelTitle: String?
    @ViewBuilder var content: () -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.gap) {
            grabber

            VStack(alignment: .leading, spacing: DesignSystem.Space.xxs) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Palette.primaryText)

                if let message {
                    Text(message)
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: DesignSystem.Space.s) {
                content()
            }

            if let cancelTitle {
                Button(cancelTitle) { dismiss() }
                    .quietButton()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Layout.gutter)
        .padding(.bottom, DesignSystem.Space.s)
    }

    private var grabber: some View {
        Capsule()
            .fill(Palette.surfaceSunken)
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, DesignSystem.Space.m)
    }
}

// MARK: - Presentation

extension View {
    /// Presents a drawer that sizes itself to its content.
    func drawer<DrawerContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> DrawerContent
    ) -> some View {
        modifier(DrawerPresentation(isPresented: isPresented, drawerContent: content))
    }

    /// Presents a drawer driven by an optional value, for choices that need to know
    /// which row was tapped.
    func drawer<Item: Identifiable, DrawerContent: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> DrawerContent
    ) -> some View {
        modifier(DrawerItemPresentation(item: item, drawerContent: content))
    }

    /// Asks a yes-or-no question that cannot be undone.
    func confirmationDrawer(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        confirmTitle: String,
        isDestructive: Bool = true,
        onConfirm: @escaping () -> Void
    ) -> some View {
        drawer(isPresented: isPresented) {
            ConfirmationDrawerContent(
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                isDestructive: isDestructive,
                onConfirm: onConfirm
            )
        }
    }

    /// Confirms an irreversible action on a specific item, so the question can name
    /// what is about to disappear.
    func confirmationDrawer<Item: Identifiable>(
        item: Binding<Item?>,
        title: @escaping (Item) -> String,
        message: @escaping (Item) -> String? = { _ in nil },
        confirmTitle: String,
        isDestructive: Bool = true,
        onConfirm: @escaping (Item) -> Void
    ) -> some View {
        drawer(item: item) { value in
            ConfirmationDrawerContent(
                title: title(value),
                message: message(value),
                confirmTitle: confirmTitle,
                isDestructive: isDestructive
            ) {
                onConfirm(value)
            }
        }
    }
}

/// The body of a confirmation drawer, split out so it can carry its own `dismiss`.
private struct ConfirmationDrawerContent: View {
    let title: String
    let message: String?
    let confirmTitle: String
    let isDestructive: Bool
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Drawer(title: title, message: message, cancelTitle: "Cancelar") {
            Button(confirmTitle) {
                dismiss()
                onConfirm()
            }
            .primaryButton(tint: isDestructive ? Palette.critical : Palette.accent)
        }
    }
}

/// Wraps a drawer in a sheet whose single detent tracks the content's height.
///
/// A native sheet is used rather than an overlay so drag-to-dismiss, the keyboard
/// and the tab bar all behave the way the system already taught the user, while the
/// drawer keeps drawing its own surface.
private struct DrawerPresentation<DrawerContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let drawerContent: () -> DrawerContent

    @State private var height: CGFloat = 260

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            drawerContent()
                .drawerSizing($height)
        }
    }
}

private struct DrawerItemPresentation<Item: Identifiable, DrawerContent: View>: ViewModifier {
    @Binding var item: Item?
    let drawerContent: (Item) -> DrawerContent

    @State private var height: CGFloat = 260

    func body(content: Content) -> some View {
        content.sheet(item: $item) { value in
            drawerContent(value)
                .drawerSizing($height)
        }
    }
}

private extension View {
    /// Measures the drawer and feeds the result back as its detent, which is what
    /// lets a drawer with three options be shorter than one with eight.
    func drawerSizing(_ height: Binding<CGFloat>) -> some View {
        background(Palette.canvas)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { measured in
                guard measured > 0 else { return }
                height.wrappedValue = measured
            }
            .presentationDetents([.height(height.wrappedValue)])
            .presentationBackground(Palette.canvas)
            .presentationCornerRadius(Layout.modalRadius)
            .presentationDragIndicator(.hidden)
    }
}
