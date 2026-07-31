import SwiftUI

/// Everything that is not a daily action: the plan, the money that never changes,
/// the reminders, and the way into the simulator and the closes.
struct SettingsView: View {
    let dependencies: AppDependencies

    @State private var showsWeeklyClose = false
    @State private var showsMonthlyClose = false

    private var profile: ProfileEntity { dependencies.profile }
    private var planStore: PlanStore { dependencies.planStore }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Space.xxxl) {
                DetailHeader(title: "Ajustes")

                planSection
                toolsSection
                moneySection
                catalogSection
                remindersSection
                closesSection

                #if DEBUG
                DeveloperSection(dependencies: dependencies)
                #endif
            }
            .padding(.horizontal, DesignSystem.Space.xxl)
            .padding(.top, DesignSystem.Space.s)
            .padding(.bottom, MainTabBar.scrollBottomPadding)
        }
        .screenSurface()
        .sheet(isPresented: $showsWeeklyClose) {
            WeeklyCloseSheet(dependencies: dependencies)
        }
        .sheet(isPresented: $showsMonthlyClose) {
            MonthlyCloseSheet(dependencies: dependencies)
        }
    }

    // MARK: - Sections

    private var planSection: some View {
        CardSection(header: "Tu plan") {
            NavigationLink {
                PlanComparisonView(dependencies: dependencies)
            } label: {
                NavRow(title: "Plan activo", value: planStore.activePlan.name)
            }
            .buttonStyle(.plain)

            RowDivider()

            NavigationLink {
                TargetDateView(dependencies: dependencies)
            } label: {
                NavRow(
                    title: "Fecha objetivo",
                    value: profile.targetDate.map(dependencies.dates.monthAndYear) ?? "Sin definir"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var toolsSection: some View {
        CardSection(header: "Herramientas") {
            NavigationLink {
                PlanProgressScreen(dependencies: dependencies)
            } label: {
                NavRow(title: "Tu progreso", icon: "chart.line.uptrend.xyaxis")
            }
            .buttonStyle(.plain)

            RowDivider()

            NavigationLink {
                SimulatorView(dependencies: dependencies)
            } label: {
                NavRow(title: "¿Qué pasa si...?", icon: "wand.and.stars")
            }
            .buttonStyle(.plain)
        }
    }

    private var moneySection: some View {
        CardSection(header: "Tu dinero") {
            DetailRow(
                label: "Ingreso mensual",
                value: dependencies.money.string(profile.primaryIncome, currency: profile.currency)
            )
            DetailRow(
                label: "Fondo de emergencia",
                value: dependencies.money.string(profile.emergencyFund, currency: profile.currency)
            )
            DetailRow(
                label: "Ahorros",
                value: dependencies.money.string(profile.savings, currency: profile.currency)
            )
            DetailRow(
                label: "Moneda",
                value: profile.currency.rawValue
            )

            RowDivider()

            NavigationLink {
                MoneyEditorView(dependencies: dependencies)
            } label: {
                NavRow(title: "Editar montos")
            }
            .buttonStyle(.plain)
        }
    }

    private var catalogSection: some View {
        CardSection(header: "Compromisos") {
            NavigationLink {
                UtilitiesView(dependencies: dependencies)
            } label: {
                NavRow(title: "Servicios públicos", icon: "bolt")
            }
            .buttonStyle(.plain)

            RowDivider()

            NavigationLink {
                SubscriptionsView(dependencies: dependencies)
            } label: {
                NavRow(title: "Suscripciones", icon: "repeat")
            }
            .buttonStyle(.plain)

            RowDivider()

            NavigationLink {
                FixedExpensesView(dependencies: dependencies)
            } label: {
                NavRow(title: "Gastos fijos", icon: "house")
            }
            .buttonStyle(.plain)
        }
    }

    private var remindersSection: some View {
        CardSection(
            header: "Recordatorios",
            footer: "Cada noche te preguntamos si ya agregaste tus gastos. También te avisamos de fechas de pago, cortes y cobros próximos."
        ) {
            CeroToggle(
                title: "Recordatorios",
                isOn: Binding(
                    get: { profile.notificationsEnabled },
                    set: { enabled in
                        dependencies.preferences.setReminder(
                            hour: profile.reminderHour,
                            minute: profile.reminderMinute,
                            enabled: enabled
                        )
                    }
                )
            )

            if profile.notificationsEnabled {
                RowDivider()

                TimeRow(
                    title: "Hora",
                    time: Binding(
                        get: { reminderDate },
                        set: { date in
                            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                            dependencies.preferences.setReminder(
                                hour: parts.hour ?? 21,
                                minute: parts.minute ?? 0,
                                enabled: true
                            )
                        }
                    )
                )
            }
        }
    }

    private var closesSection: some View {
        CardSection(header: "Cierres") {
            Button("Cierre semanal") { showsWeeklyClose = true }
                .secondaryButton()
            Button("Cierre mensual") { showsMonthlyClose = true }
                .secondaryButton()
        }
    }

    private var reminderDate: Date {
        Calendar.current.date(
            bySettingHour: profile.reminderHour,
            minute: profile.reminderMinute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}
