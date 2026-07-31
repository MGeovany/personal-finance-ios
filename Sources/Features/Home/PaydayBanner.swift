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
    /// Every movement the plan asks for, in the order to do them, each marked done or not.
    let instructions: [PaydayInstruction]
    let money: MoneyFormatting
    let dates: PlanDateFormatting
    let currency: CurrencyCode
    let onRegister: () -> Void

    var body: some View {
        CardContainer(elevation: .floating) {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                header

                if !instructions.isEmpty {
                    RowDivider()
                    checklist
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
        // Centred against the whole text block rather than pinned to the title, so the
        // icon sits with the message it belongs to however many lines that runs to.
        HStack(alignment: .center, spacing: Layout.gap) {
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

    /// How to do it, and how much of it is done.
    ///
    /// A checklist rather than a list: registering one payment out of four used to make
    /// this whole card disappear, which is exactly how the other three got forgotten.
    private var checklist: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.m) {
            HStack {
                SectionHeader(title: "Cómo hacerlo")
                Spacer()
                if status.progress.hasStarted {
                    Text("\(status.progress.registered) de \(status.progress.expected)")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }
            }

            ForEach(instructions) { instruction in
                InstructionRow(instruction: instruction)
            }
        }
    }

    // MARK: - Wording

    private var title: String {
        switch status {
        case .today(let progress):
            progress.hasStarted ? "Te falta registrar lo demás" : "Hoy es día de pago"
        case .pending(_, let days, let progress):
            if progress.hasStarted { "Te falta registrar lo demás" }
            else if days >= PaydayStatus.insistAfterDays { "Tu plan está en pausa" }
            else { "Te falta registrar tus abonos" }
        default:
            ""
        }
    }

    private var message: String {
        switch status {
        case .today(let progress):
            return progress.hasStarted
                ? "Te quedan \(progress.remaining) movimientos por registrar."
                : "Registra tus abonos a tus tarjetas. Es el día en que el plan se cumple."

        case .pending(let since, let days, let progress):
            let when = dates.dayAndMonth(since, relativeTo: Date())
            if progress.hasStarted {
                return "Te pagaron el \(when). Te quedan \(progress.remaining) movimientos por registrar."
            }
            return days >= PaydayStatus.insistAfterDays
                ? "Te pagaron el \(when) y no has registrado ningún abono. Registra uno para seguir con el plan."
                : "Te pagaron el \(when). Aún no registras ningún abono."

        default:
            return ""
        }
    }

    private var actionTitle: String {
        status.progress.hasStarted ? "Registrar lo que falta" : "Registrar mis abonos"
    }

    private var icon: String {
        status.isInsistent ? "exclamationmark.circle.fill" : "banknote"
    }

    private var tint: Color {
        status.isInsistent ? Palette.critical : Palette.primaryText
    }
}

/// One movement in the payday checklist, ticked once it is registered.
///
/// A done row stays on screen rather than disappearing, so the card reads as a list being
/// worked through instead of one that mysteriously shrinks.
private struct InstructionRow: View {
    let instruction: PaydayInstruction

    var body: some View {
        HStack(alignment: .center, spacing: Layout.gap) {
            Image(systemName: instruction.isRegistered ? "checkmark.circle.fill" : instruction.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(instruction.isRegistered ? Palette.positive : Palette.tertiaryText)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(instruction.label)
                    .font(Typography.body)
                    .foregroundStyle(instruction.isRegistered ? Palette.tertiaryText : Palette.primaryText)
                    .strikethrough(instruction.isRegistered, color: Palette.tertiaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(instruction.isRegistered ? "Registrado" : instruction.caption)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: Layout.tightGap)

            Text(instruction.value)
                .font(Typography.amount)
                .foregroundStyle(instruction.isRegistered ? Palette.tertiaryText : Palette.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
