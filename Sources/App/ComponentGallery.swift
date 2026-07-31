#if DEBUG
import SwiftUI

/// Every design-system control on one screen, so a change to a token can be seen
/// everywhere at once instead of hunted for across the app.
///
/// Debug builds only, reached by launching with `CERO_GALLERY=1`.
struct ComponentGallery: View {
    @State private var text = "Alquiler"
    @State private var amount: Money = 4500
    @State private var percent: Double = 24
    @State private var isOn = true
    @State private var currency: CurrencyCode = .hnl
    @State private var frequency: ChargeFrequency = .monthly
    @State private var date = Date()
    @State private var time = Date()
    @State private var day: Int? = 15
    @State private var choice = 0
    @State private var showsModal = false
    @State private var showsDrawer = false
    @State private var isConfirming = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionGap) {
                ScreenHeader(title: "Componentes", subtitle: "Todo el sistema en una pantalla.")

                CardSection(header: "Botones") {
                    Button("Acción principal") {}.primaryButton()
                    Button("Acción secundaria") {}.secondaryButton()
                    Button("Deshacer") {}.quietButton()
                    Button("Destructiva") {}.primaryButton(tint: Palette.critical)
                    Button("Deshabilitada") {}.primaryButton(isEnabled: false)

                    HStack(spacing: Layout.gap) {
                        Button("Compacta") {}.compactButton()
                        Button("Prominente") {}.compactButton(isProminent: true)
                        IconButton(systemImage: "plus", label: "Agregar", isProminent: true) {}
                        IconButton(systemImage: "xmark", label: "Cerrar") {}
                    }
                }

                CardSection(header: "Campos") {
                    CeroTextField(title: "Nombre", text: $text)
                    MoneyField(title: "Monto", amount: $amount, currency: currency)
                    PercentField(title: "Tasa anual", percent: $percent)
                    RowDivider()
                    CeroToggle(title: "Recordatorios", caption: "Cada noche a la hora que elijas.", isOn: $isOn)
                    RowDivider()
                    SelectRow(
                        title: "Moneda",
                        selection: $currency,
                        options: CurrencyCode.allCases,
                        label: { $0.rawValue },
                        detail: { $0.displayName }
                    )
                    DateRow(title: "Fecha", date: $date)
                    TimeRow(title: "Hora", time: $time)
                    DayOfMonthPicker(title: "Día de cobro", day: $day)
                    RowDivider()
                    NavRow(title: "Otros ingresos", value: "3", icon: "arrow.up.circle")
                }

                CardSection(header: "Selección") {
                    SegmentedSelector(
                        selection: $frequency,
                        options: [.weekly, .monthly, .annual],
                        label: \.label
                    )
                    OptionRow(title: "Con detalle", detail: "La opción explicada en su sitio.", isSelected: true) {}
                    OptionRow(title: "Sin detalle") {}
                    HStack(spacing: Layout.tightGap) {
                        Chip(text: "Actual")
                        Chip(text: "No la uso", tint: Palette.caution)
                        Chip(text: "Atrasado", tint: Palette.critical)
                    }
                }

                // Not inside a CardSection: these carry their own surface, because
                // they are answers to a question rather than rows in a form.
                VStack(alignment: .leading, spacing: DesignSystem.Space.s) {
                    Text("Respuestas").sectionHeaderStyle()

                    ChoiceCard(
                        title: "Con detalle y monto",
                        detail: "La opción explicada en una línea.",
                        icon: "house",
                        trailing: "L9,000",
                        isSelected: choice == 0
                    ) { choice = 0 }

                    ChoiceCard(title: "Sin nada más", isSelected: choice == 1) { choice = 1 }

                    ChoiceCard(title: "Abre otra cosa", icon: "plus", showsSelection: false) {}

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: DesignSystem.Space.s), GridItem(.flexible())],
                        spacing: DesignSystem.Space.s
                    ) {
                        ChoiceTile(title: "Alquiler", icon: "house", isSelected: choice == 2) { choice = 2 }
                        ChoiceTile(title: "Internet", icon: "wifi", isSelected: choice == 3) { choice = 3 }
                    }

                    AmountChoices(
                        options: AmountBands.shares(
                            [("Poco", 0.08), ("Lo normal", 0.14), ("Bastante", 0.25)],
                            of: 45_000,
                            currency: currency
                        ),
                        amount: $amount,
                        currency: currency
                    )
                }

                CardSection(header: "Estados") {
                    InfoBanner(message: "Todo va según el plan.", severity: .info)
                    InfoBanner(message: "Tu fondo de emergencia está bajo.", severity: .caution)
                    InfoBanner(message: "Este gasto te saca del presupuesto.", severity: .critical)
                    ProgressBarView(fraction: 0.42)
                    ProgressBarView(fraction: 0.92, tint: Palette.critical)
                }

                CardSection(header: "Capas") {
                    Button("Abrir modal") { showsModal = true }.secondaryButton()
                    Button("Abrir drawer") { showsDrawer = true }.secondaryButton()
                    Button("Confirmar algo grave") { isConfirming = true }
                        .primaryButton(tint: Palette.critical)
                }
            }
            .padding(Layout.gutter)
        }
        .screenSurface()
        .sheet(isPresented: $showsModal) {
            ModalScaffold(
                title: "Un modal",
                subtitle: "El lugar al que vas a hacer trabajo.",
                primary: ModalAction("Guardar") { showsModal = false },
                secondary: ModalAction("Eliminar", isDestructive: true) { showsModal = false }
            ) {
                CardSection(header: "Datos", footer: "El pie explica lo que no cabe en la etiqueta.") {
                    CeroTextField(title: "Nombre", text: $text)
                    MoneyField(title: "Monto", amount: $amount, currency: currency)
                }
            }
            .modalPresentation()
        }
        .drawer(isPresented: $showsDrawer) {
            Drawer(title: "Un drawer", message: "Una pregunta, una respuesta.", cancelTitle: "Cancelar") {
                CardContainer(padding: DesignSystem.Space.xs) {
                    VStack(spacing: 0) {
                        ForEach(Array(CurrencyCode.allCases.enumerated()), id: \.element) { index, option in
                            if index > 0 { RowDivider() }
                            OptionRow(
                                title: option.displayName,
                                detail: option.symbol,
                                isSelected: option == currency
                            ) {
                                currency = option
                                showsDrawer = false
                            }
                        }
                    }
                }
            }
        }
        .confirmationDrawer(
            isPresented: $isConfirming,
            title: "¿Borrar todo?",
            message: "Esto no se puede deshacer.",
            confirmTitle: "Borrar"
        ) {}
    }
}
#endif
