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
        CardSection(
            header: "Desarrollo",
            footer: isStoreEmpty
                ? "El usuario de prueba solo se carga en una app vacía."
                : "Ya tienes datos. Bórralos primero si quieres cargar el usuario de prueba."
        ) {
            OptionRow(
                title: "Cargar \(MockUser.name.lowercased())",
                detail: MockUser.summary
            ) {
                dependencies.loadMockUser()
            }
            .disabled(!isStoreEmpty)
            .opacity(isStoreEmpty ? 1 : 0.4)

            OptionRow(
                title: "Borrar todos mis datos",
                isDestructive: true
            ) {
                isConfirmingReset = true
            }
        }
        .confirmationDrawer(
            isPresented: $isConfirmingReset,
            title: "¿Borrar todos tus datos?",
            message: "Se eliminan tus ingresos, deudas, gastos, servicios, suscripciones y metas. Volverás a la configuración inicial. No se puede deshacer.",
            confirmTitle: "Borrar todo"
        ) {
            dependencies.storeResetting.reset()
        }
    }
}
