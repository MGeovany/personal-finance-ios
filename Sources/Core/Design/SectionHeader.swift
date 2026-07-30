import SwiftUI

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
                    .font(Typography.caption.weight(.semibold))
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
