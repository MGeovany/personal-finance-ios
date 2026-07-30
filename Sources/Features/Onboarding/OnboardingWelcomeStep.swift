import SwiftUI

/// The opening screen: the five questions the app answers, so the user knows
/// what all the setup is for.
struct OnboardingWelcomeStep: View {
    private let promises = [
        (icon: "creditcard", text: "Cuánto debes en total"),
        (icon: "wallet.bifold", text: "Cuánto puedes gastar esta semana"),
        (icon: "arrow.down.circle", text: "Qué pago te conviene hacer ahora"),
        (icon: "calendar.badge.checkmark", text: "En qué fecha podrías quedar libre de deudas"),
        (icon: "chart.line.downtrend.xyaxis", text: "Qué está retrasando tu progreso"),
    ]

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Layout.gap) {
                ForEach(promises, id: \.text) { promise in
                    HStack(spacing: Layout.gap) {
                        Image(systemName: promise.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(Palette.accent)
                            .frame(width: 24)
                        Text(promise.text)
                            .font(Typography.body)
                            .foregroundStyle(Palette.primaryText)
                    }
                }
            }
        }
    }
}
