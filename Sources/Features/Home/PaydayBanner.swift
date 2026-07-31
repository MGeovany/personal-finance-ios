import SwiftUI

/// The one thing the dashboard leads with on a payday, and keeps leading with until
/// something is registered.
///
/// Every other card on Home reports. This one asks. It is filled black on the payday
/// itself because that is the single day the plan can actually be carried out, and it
/// says the amounts per card right there so the user does not have to go looking for
/// what "abonar" means today.
struct PaydayBanner: View {
    let status: PaydayStatus
    /// What to pay and where, taken from the plan so this card and the briefing agree.
    let payments: [(payment: PlanBriefing.DebtPayment, value: String, detail: String)]
    let savingsContribution: Money?
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let currency: CurrencyCode
    let onRegister: () -> Void

    var body: some View {
        CardContainer(elevation: .floating) {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                header

                if !payments.isEmpty {
                    RowDivider()
                    instructions
                }

                Button(actionTitle, action: onRegister)
                    .primaryButton()
            }
        }
        .overlay(alignment: .topTrailing) {
            if status.isInsistent {
                Chip(text: "\(status.daysWaiting) días", tint: Palette.critical)
                    .padding(DesignSystem.Space.l)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Layout.gap) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: DesignSystem.Space.xxs) {
                Text(title)
                    .font(Typography.display(22, .displaySemibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    /// How to do it: one line per card, in the order the plan attacks them, plus the
    /// savings transfer when the plan asks for one.
    private var instructions: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.m) {
            SectionHeader(title: "Cómo hacerlo")

            ForEach(payments, id: \.payment.id) { row in
                DetailRow(
                    label: row.payment.name,
                    value: row.value,
                    tint: row.payment.isPriority ? Palette.primaryText : Palette.secondaryText,
                    icon: row.payment.isPriority ? "target" : "creditcard",
                    caption: row.payment.isPriority ? "Primero esta, es la que más caro cuesta" : "Solo el mínimo"
                )
            }

            if let savingsContribution, savingsContribution > 0 {
                DetailRow(
                    label: "A tu fondo de emergencia",
                    value: money.string(savingsContribution, currency: currency),
                    icon: "shield",
                    caption: "Transfiérelo a tu cuenta de ahorro"
                )
            }
        }
    }

    // MARK: - Wording

    private var title: String {
        switch status {
        case .today: "Hoy es día de pago"
        case .pending(_, let days) where days >= PaydayStatus.insistAfterDays: "Tu plan está en pausa"
        case .pending: "Te falta registrar tus abonos"
        default: ""
        }
    }

    private var message: String {
        switch status {
        case .today:
            return "Registra tus abonos a tus tarjetas. Es el día en que el plan se cumple."
        case .pending(let since, let days):
            let when = dates.dayAndMonth(since, relativeTo: Date())
            return days >= PaydayStatus.insistAfterDays
                ? "Te pagaron el \(when) y no has registrado ningún abono. Registra uno para seguir con el plan."
                : "Te pagaron el \(when). Aún no registras ningún abono."
        default:
            return ""
        }
    }

    private var actionTitle: String {
        status.isPayday ? "Registrar mis abonos" : "Registrar un abono"
    }

    private var icon: String {
        status.isInsistent ? "exclamationmark.circle.fill" : "banknote"
    }

    private var tint: Color {
        status.isInsistent ? Palette.critical : Palette.primaryText
    }
}
