import SwiftUI

/// An inline message: a warning, an explanation, a consequence.
///
/// The app explains every recommendation, and this is the shape those
/// explanations take.
struct InfoBanner: View {
    let message: String
    var severity: PlanWarning.Severity = .info
    var icon: String?
    var action: (title: String, handler: () -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Layout.gap) {
            Image(systemName: icon ?? defaultIcon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: Layout.tightGap) {
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let action {
                    Button(action.title, action: action.handler)
                        .compactButton(isProminent: severity == .critical)
                        .padding(.top, DesignSystem.Space.xxs)
                }
            }
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface(for: tint), in: RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
    }

    private var tint: Color { Palette.color(for: severity) }

    private var defaultIcon: String {
        switch severity {
        case .info: "info.circle"
        case .caution: "exclamationmark.triangle"
        case .critical: "exclamationmark.octagon"
        }
    }
}
