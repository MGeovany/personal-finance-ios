import Foundation
import SwiftData

/// The one place that lists the stored types and builds a container.
///
/// Having it here rather than in the app entry point means tests and previews get
/// an identical schema with a single call.
enum ModelSchema {
    static let entities: [any PersistentModel.Type] = [
        ProfileEntity.self,
        IncomeEntity.self,
        FixedExpenseEntity.self,
        UtilityEntity.self,
        UtilityReadingEntity.self,
        SubscriptionEntity.self,
        DebtEntity.self,
        DebtPaymentEntity.self,
        CategoryEntity.self,
        ExpenseEntity.self,
        GoalEntity.self,
        ReviewLogEntity.self,
    ]

    static var schema: Schema { Schema(entities) }

    /// The app's on-disk store.
    static func container() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false))
    }

    /// Throwaway store for previews and tests.
    static func inMemoryContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }
}
