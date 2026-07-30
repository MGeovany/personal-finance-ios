import SwiftUI

/// The small celebration when a debt reaches zero or a goal fills up.
///
/// Deliberately restrained and self-dismissing: a win worth acknowledging, not a
/// confetti cannon that gets in the way of the next decision.
struct CelebrationOverlay: View {
    let title: String
    let message: String
    var actions: [Action] = []
    let onDismiss: () -> Void

    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let handler: () -> Void
    }

    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            CardContainer(padding: Layout.gutter) {
                VStack(spacing: Layout.gap) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Palette.positive)
                        .scaleEffect(hasAppeared ? 1 : 0.6)
                        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: hasAppeared)

                    Text(title)
                        .font(Typography.title)
                        .foregroundStyle(Palette.primaryText)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(Typography.body)
                        .foregroundStyle(Palette.secondaryText)
                        .multilineTextAlignment(.center)

                    VStack(spacing: Layout.tightGap) {
                        ForEach(actions) { action in
                            Button(action.title, action: action.handler).secondaryButton()
                        }
                        Button("Listo", action: onDismiss).primaryButton()
                    }
                    .padding(.top, Layout.tightGap)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(Layout.gutter * 1.5)
        }
        .onAppear { hasAppeared = true }
    }
}
