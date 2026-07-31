import SwiftUI

/// Is this working?
///
/// The one screen that looks backwards. Everything measured comes first, because that is
/// what the user actually did. The projection comes after and says out loud that it is a
/// projection. Then the log, which is the evidence behind both.
struct PlanProgressScreen: View {
    let dependencies: AppDependencies

    @State private var showsAllActivity = false

    private var progress: PlanProgress { dependencies.planProgress.progress }
    private var entries: [ActivityEntry] {
        dependencies.activityFeed.recentEntries(limit: showsAllActivity ? 200 : 12)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Space.xl) {
                header
                measured
                projected
                activity
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .navigationTitle("Tu progreso")
    }

    // MARK: - Since when

    private var header: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                Text(startedLine)
                    .font(Typography.display(22, .displaySemibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let fraction = progress.debtClearedFraction, let cleared = progress.debtCleared {
                    ProgressBarView(fraction: fraction, tint: Palette.positive)
                    Text("Has bajado \(money(cleared)) de tu deuda, un \(percent(fraction)) del total con el que empezaste.")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var startedLine: String {
        guard let started = progress.startedOn else {
            return "Tu plan está en marcha"
        }
        let when = dependencies.dates.dayAndMonth(started, relativeTo: Date())
        return progress.daysIn < 1
            ? "Empezaste tu plan hoy"
            : "Llevas \(progress.daysIn) días desde el \(when)"
    }

    // MARK: - What actually happened

    private var measured: some View {
        CardSection(header: "Lo que has hecho") {
            DetailRow(
                label: "Abonado a tus deudas",
                value: money(progress.paidToDebt),
                tint: Palette.primaryText,
                icon: "arrow.down.circle"
            )
            RowDivider()
            DetailRow(
                label: "Guardado en ahorro y metas",
                value: money(progress.saved),
                tint: Palette.primaryText,
                icon: "shield"
            )

            if let faithfulness = progress.faithfulness {
                RowDivider()
                DetailRow(
                    label: "Días de pago cumplidos",
                    value: "\(progress.paydaysHonoured) de \(progress.paydaysPassed)",
                    tint: faithfulness >= 0.8 ? Palette.positive : Palette.primaryText,
                    icon: "calendar",
                    caption: faithfulness >= 0.8 ? "Vas muy bien" : "Cada uno cuenta"
                )
            }

            if let debtAtStart = progress.debtAtStart {
                RowDivider()
                DetailRow(
                    label: "Debías al empezar",
                    value: money(debtAtStart),
                    tint: Palette.secondaryText
                )
                DetailRow(
                    label: "Debes hoy",
                    value: money(progress.debtNow),
                    tint: Palette.primaryText
                )
            }
        }
    }

    // MARK: - What is expected

    private var projected: some View {
        CardSection(
            header: "Lo que viene",
            // Said plainly, because interest that has not been charged is not money in
            // anybody's pocket yet.
            footer: "Estas dos cifras son proyecciones, no resultados. Cambian cada vez que registras algo."
        ) {
            DetailRow(
                label: "Fecha libre de deudas",
                value: progress.freedomDate.map { dependencies.dates.compactDayAndMonth($0, relativeTo: Date()) } ?? "Sin fecha",
                tint: Palette.primaryText,
                icon: "flag.checkered",
                caption: dependencies.dates.horizon(months: progress.monthsToFreedom)
            )

            if progress.interestAvoided > 0 {
                RowDivider()
                DetailRow(
                    label: "Intereses que te vas a ahorrar",
                    value: money(progress.interestAvoided),
                    tint: Palette.positive,
                    icon: "chart.line.downtrend.xyaxis",
                    caption: "Contra pagar solo los mínimos"
                )
            }

            if progress.interestAhead > 0 {
                RowDivider()
                DetailRow(
                    label: "Intereses que todavía pagarás",
                    value: money(progress.interestAhead),
                    tint: Palette.secondaryText
                )
            }
        }
    }

    // MARK: - The log

    @ViewBuilder
    private var activity: some View {
        let days = entries.groupedByDay()

        if days.isEmpty {
            CardSection(header: "Movimientos") {
                Text("Todavía no has registrado nada. Cada gasto, abono y ahorro va a aparecer aquí.")
                    .font(Typography.body)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(alignment: .leading, spacing: DesignSystem.Space.l) {
                SectionHeader(title: "Movimientos")

                ForEach(days, id: \.day) { group in
                    CardSection(header: dayHeader(group.day)) {
                        ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                            if index > 0 { RowDivider() }
                            ActivityRow(entry: entry, money: dependencies.money)
                        }
                    }
                }

                if !showsAllActivity {
                    Button("Ver todo") { showsAllActivity = true }
                        .compactButton()
                }
            }
        }
    }

    private func dayHeader(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Hoy" }
        if calendar.isDateInYesterday(day) { return "Ayer" }
        return dependencies.dates.dayAndMonth(day, relativeTo: Date())
    }

    // MARK: - Formatting

    private func money(_ amount: Money) -> String {
        dependencies.money.string(amount, currency: dependencies.currency)
    }

    private func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }
}

/// One line of the history.
///
/// Spending is signed, because a list where an expense and a payment look the same is a
/// list nobody can read. Money that left for good gets a minus; money that moved somewhere
/// still yours does not.
private struct ActivityRow: View {
    let entry: ActivityEntry
    let money: MoneyFormatting

    var body: some View {
        HStack(spacing: Layout.gap) {
            Image(systemName: entry.kind.icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(entry.kind.isSpending ? Palette.tertiaryText : Palette.positive)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title)
                    .font(Typography.bodyStrong)
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(1)

                Text([entry.kind.label, entry.detail].compactMap { $0 }.joined(separator: " · "))
                    .font(Typography.caption)
                    .foregroundStyle(Palette.tertiaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: Layout.tightGap)

            Text(entry.kind.isSpending ? "−\(amount)" : amount)
                .font(Typography.amount)
                .foregroundStyle(entry.kind.isSpending ? Palette.primaryText : Palette.positive)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var amount: String {
        money.string(entry.amount, currency: entry.currency)
    }
}
