import SwiftUI

/// When the money arrives.
///
/// The frequency is a tap. The day only appears once the frequency is chosen, because
/// "el 15 y el 30" makes no sense until the user has said they get paid twice a month.
/// Skippable: the app works without it, it just cannot be in the right place on the
/// right day.
struct OnboardingPaydayStep: View {
    @Bindable var model: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Space.xl) {
            ChoiceStack {
                ForEach(PaydayFrequency.allCases) { frequency in
                    ChoiceCard(
                        title: frequency.label,
                        detail: frequency.detail,
                        icon: icon(for: frequency),
                        isSelected: model.draft.paydaySchedule?.frequency == frequency
                    ) {
                        model.selectPaydayFrequency(frequency)
                    }
                }

                ChoiceCard(
                    title: "No tengo un día fijo",
                    detail: "Puedes definirlo después en Ajustes.",
                    icon: "calendar.badge.minus",
                    isSelected: model.draft.paydaySchedule == nil
                ) {
                    model.clearPayday()
                }
                .padding(.top, Layout.tightGap)
            }

            if let schedule = model.draft.paydaySchedule {
                days(for: schedule)
                    .id("paydayDays")
            }
        }
        .animation(DesignSystem.Motion.swap, value: model.draft.paydaySchedule?.frequency)
    }

    @ViewBuilder
    private func days(for schedule: PaydaySchedule) -> some View {
        CardSection(header: "El día", footer: footer(for: schedule)) {
            if schedule.frequency.usesDayOfMonth {
                PaydayDayRow(
                    title: schedule.frequency.needsSecondDay ? "Primer pago" : "Día de pago",
                    day: Binding(
                        get: { schedule.primaryDay },
                        set: { model.setPaydayPrimaryDay($0) }
                    )
                )

                if schedule.frequency.needsSecondDay {
                    RowDivider()
                    PaydayDayRow(
                        title: "Segundo pago",
                        day: Binding(
                            get: { schedule.secondaryDay ?? PaydaySchedule.lastDayOfMonth },
                            set: { model.setPaydaySecondaryDay($0) }
                        )
                    )
                }
            } else {
                SelectRow(
                    title: "Día de la semana",
                    selection: Binding(
                        get: { schedule.primaryDay },
                        set: { model.setPaydayPrimaryDay($0) }
                    ),
                    options: Array(1...7),
                    label: Weekday.name(for:)
                )
            }

            if schedule.frequency.needsAnchor {
                RowDivider()
                DateRow(
                    title: "Tu último día de pago",
                    date: Binding(
                        get: { schedule.anchor ?? Date() },
                        set: { model.setPaydayAnchor($0) }
                    )
                )
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func footer(for schedule: PaydaySchedule) -> String? {
        switch schedule.frequency {
        case .semimonthly, .monthly:
            "Si el mes no tiene ese día, contamos el último."
        case .biweekly:
            "Contamos catorce días desde esa fecha."
        case .weekly:
            nil
        }
    }

    private func icon(for frequency: PaydayFrequency) -> String {
        switch frequency {
        case .monthly: "calendar"
        case .semimonthly: "calendar.badge.clock"
        case .biweekly: "arrow.trianglehead.2.clockwise"
        case .weekly: "calendar.day.timeline.left"
        }
    }
}

/// A day of the month, for a schedule where 31 means "the last one".
private struct PaydayDayRow: View {
    let title: String
    @Binding var day: Int

    var body: some View {
        SelectRow(
            title: title,
            selection: $day,
            options: Array(1...PaydaySchedule.lastDayOfMonth),
            label: { $0 == PaydaySchedule.lastDayOfMonth ? "Último del mes" : "Día \($0)" }
        )
    }
}

/// Weekday names, indexed the way `Calendar` numbers them so the value stored is the
/// one the calendar will be asked about.
enum Weekday {
    static func name(for value: Int) -> String {
        switch value {
        case 1: "Domingo"
        case 2: "Lunes"
        case 3: "Martes"
        case 4: "Miércoles"
        case 5: "Jueves"
        case 6: "Viernes"
        default: "Sábado"
        }
    }
}
