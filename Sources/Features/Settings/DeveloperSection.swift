import SwiftUI

/// Loading the saved sample user, and emptying the store.
///
/// Debug builds only: these two actions exist to make development and inspection
/// easy, and neither belongs in a shipped app where they could destroy real data by
/// accident.
struct DeveloperSection: View {
    let dependencies: AppDependencies

    @State private var isConfirmingReset = false

    private var isStoreEmpty: Bool {
        dependencies.debts.all().isEmpty && dependencies.profile.primaryIncome == 0
    }

    var body: some View {
        Section {
            Button {
                dependencies.loadMockUser()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cargar \(MockUser.name.lowercased())")
                    Text(MockUser.summary)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.tertiaryText)
                }
            }
            .disabled(!isStoreEmpty)

            Button("Borrar todos mis datos", role: .destructive) {
                isConfirmingReset = true
            }
        } header: {
            Text("Desarrollo")
        } footer: {
            Text(
                isStoreEmpty
                    ? "El usuario de prueba solo se carga en una app vacía."
                    : "Ya tienes datos. Bórralos primero si quieres cargar el usuario de prueba."
            )
        }
        .confirmationDialog(
            "¿Borrar todos tus datos?",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("Borrar todo", role: .destructive) {
                dependencies.storeResetting.reset()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminan tus ingresos, deudas, gastos, servicios, suscripciones y metas. Volverás a la configuración inicial. No se puede deshacer.")
        }
    }
}
