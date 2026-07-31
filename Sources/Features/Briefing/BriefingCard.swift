import SwiftUI

/// One answer, alone on the screen.
///
/// The question small and the answer large, because the answer is the whole point of
/// the card and the user is reading it for the first time. Nothing else competes.
struct BriefingCard: View {
    let item: BriefingItem

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
            Image(systemName: item.icon)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Palette.secondaryText)

            Text(item.question)
                .font(Typography.bodyStrong)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.value)
                .font(Typography.display(34, .displayBold))
                .foregroundStyle(Palette.primaryText)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.detail)
                .font(Typography.body)
                .foregroundStyle(Palette.tertiaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The briefing as a compact row, for the dashboard.
///
/// Same item, same answer. On Home the question becomes a short label and the
/// explanatory sentence drops out so the section stays scannable.
struct BriefingRow: View {
    let item: BriefingItem
    var title: String?
    var showsDetail: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: Layout.gap) {
            Image(systemName: item.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.tertiaryText)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title ?? item.question)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .lineLimit(1)

                Text(item.value)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if showsDetail {
                    Text(item.detail)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
    }
}
