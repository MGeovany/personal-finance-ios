import Foundation

/// Compares the plan's budgets against what has actually been spent.
///
/// The plan says what *should* happen; this says what *is* happening. Every
/// "te quedan L750" in the app comes from here.
@MainActor
protocol BudgetProgressCalculating {
    /// Per-category budget versus spending for the month containing `date`.
    func monthlyProgress(plan: FinancialPlan, on date: Date) -> [BudgetConsumption]
    /// Total spent this month against the whole variable budget.
    func monthTotal(plan: FinancialPlan, on date: Date) -> BudgetConsumption
    /// The current week's slice, against spending inside that week.
    func weekTotal(plan: FinancialPlan, on date: Date) -> BudgetConsumption
    func spentToday(on date: Date) -> Money
}

@MainActor
struct BudgetProgressCalculator: BudgetProgressCalculating {
    private let expenses: ExpenseRepositing
    private let calendar: Calendar

    init(expenses: ExpenseRepositing, calendar: Calendar = .current) {
        self.expenses = expenses
        self.calendar = calendar
    }

    func monthlyProgress(plan: FinancialPlan, on date: Date) -> [BudgetConsumption] {
        let spentByCategory = totals(of: expenses.expenses(inMonthOf: date))

        return plan.allocation.categories.map { allocation in
            BudgetConsumption(
                categoryKey: allocation.key,
                categoryName: allocation.name,
                icon: allocation.icon,
                budget: allocation.monthly,
                spent: spentByCategory[allocation.key] ?? 0,
                historicalAverage: nil,
                expectedNext: nil
            )
        }
    }

    func monthTotal(plan: FinancialPlan, on date: Date) -> BudgetConsumption {
        BudgetConsumption(
            categoryKey: "month",
            categoryName: "Presupuesto del mes",
            icon: "calendar",
            budget: plan.monthlyVariableBudget,
            spent: total(of: expenses.expenses(inMonthOf: date)),
            historicalAverage: nil,
            expectedNext: nil
        )
    }

    func weekTotal(plan: FinancialPlan, on date: Date) -> BudgetConsumption {
        // Falling back to the average keeps the number sensible if the reference
        // date drifts outside the month the plan was built for.
        let week = plan.weekly.week(containing: date)
        let spent = week.map { total(of: expenses.expenses(from: $0.start, to: $0.end)) } ?? 0

        return BudgetConsumption(
            categoryKey: "week",
            categoryName: "Presupuesto de la semana",
            icon: "calendar.day.timeline.left",
            budget: week?.amount ?? plan.weekly.averageWeekly,
            spent: spent,
            historicalAverage: nil,
            expectedNext: nil
        )
    }

    func spentToday(on date: Date) -> Money {
        total(of: expenses.expenses(on: date))
    }

    // MARK: - Helpers

    /// Goal contributions are not everyday spending, so they never eat a budget.
    private func totals(of records: [ExpenseEntity]) -> [String: Money] {
        records
            .filter(\.consumesBudget)
            .reduce(into: [String: Money]()) { result, expense in
                result[expense.categoryKey, default: 0] += expense.amount
            }
    }

    private func total(of records: [ExpenseEntity]) -> Money {
        records.filter(\.consumesBudget).reduce(Money.zero) { $0 + $1.amount }
    }
}
