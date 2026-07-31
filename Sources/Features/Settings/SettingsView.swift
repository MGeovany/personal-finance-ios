import SwiftUI

/// Everything that is not a daily action: the plan, the money that never changes,
/// the reminders, and the way into the simulator and the closes.
struct SettingsView: View {
    let dependencies: AppDependencies

    @State private var showsWeeklyClose = false
    @State private var showsMonthlyClose = false
    @State private var renamingSpeed: PlanSpeed?

    private var profile: ProfileEntity { dependencies.profile }
    private var planStore: PlanStore { dependencies.planStore }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionGap) {
                ScreenHeader(title: "Ajustes")

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
            .padding(.horizontal, Layout.gutter)
            .padding(.bottom, Layout.sectionGap)
        }
        .screenSurface()
        .sheet(isPresented: $showsWeeklyClose) {
            WeeklyCloseSheet(dependencies: dependencies)
        }
        .sheet(isPresented: $showsMonthlyClose) {
            MonthlyCloseSheet(dependencies: dependencies)
        }
        .drawer(item: $renamingSpeed) { speed in
            RenamePlanSheet(
                speed: speed,
                currentName: profile.name(for: speed)
            ) { newName in
                dependencies.preferences.rename(speed: speed, to: newName)
            }
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

            RowDivider()

            ForEach(PlanSpeed.displayOrder) { speed in
                Button {
                    renamingSpeed = speed
                } label: {
                    HStack {
                        Text(profile.name(for: speed))
                            .font(Typography.bodyStrong)
                            .foregroundStyle(Palette.primaryText)
                        Spacer(minLength: DesignSystem.Space.s)
                        Text("Renombrar")
                            .font(Typography.label)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    .frame(minHeight: Layout.minimumTouch)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolsSection: some View {
        CardSection(header: "Herramientas") {
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

/// Renames a plan. The three speeds keep their behaviour; only the label changes.
///
/// One field and one sentence of context, which is exactly what a drawer is for.
struct RenamePlanSheet: View {
    let speed: PlanSpeed
    let currentName: String
    let onSave: (String) -> Void

    @State private var name: String
    @Environment(\.dismiss) private var dismiss

    init(speed: PlanSpeed, currentName: String, onSave: @escaping (String) -> Void) {
        self.speed = speed
        self.currentName = currentName
        self.onSave = onSave
        self._name = State(initialValue: currentName)
    }

    var body: some View {
        Drawer(title: "Renombrar plan", message: speed.shortDescription, cancelTitle: "Cancelar") {
            CardContainer {
                CeroTextField(title: "Nombre", text: $name, placeholder: speed.defaultName)
            }

            Button("Guardar") {
                onSave(name)
                dismiss()
            }
            .primaryButton()
        }
    }
}
