import Foundation

/// Turns budgets into counts.
///
/// Every number here already exists in the plan. What this adds is the unit: orders
/// instead of a delivery budget, a weekend instead of a month, one named card instead
/// of an attack order of identifiers. Doing that in one place is what lets the setup
/// summary and the dashboard say the same thing.
struct PlanBriefingBuilder: PlanBriefingBuilding {
    /// What a delivery order costs when the user has no history to go on.
    ///
    /// A guess, and the briefing says so. It only decides how the budget is *described*:
    /// the budget itself is what the plan allocated, so a wrong price shows the wrong
    /// number of orders but never the wrong amount of money.
    private let defaultOrderPrice: Money
    private let calendar: Calendar

    init(defaultOrderPrice: Money = 350, calendar: Calendar = .current) {
        self.defaultOrderPrice = defaultOrderPrice
        self.calendar = calendar
    }

    func build(
        from plan: FinancialPlan,
        snapshot: FinancialSnapshot,
        typicalDeliveryOrder: Money?
    ) -> PlanBriefing {
        PlanBriefing(
            monthlyIncome: snapshot.totalIncome,
            freedomDate: plan.freedomDate,
            monthsToFreedom: plan.monthsToFreedom,
            delivery: orders(in: plan, typicalOrder: typicalDeliveryOrder),
            outings: weekends(in: plan, from: snapshot.referenceDate),
            unexpected: plan.allocation.buffer,
            priority: payments(in: plan, snapshot: snapshot).first { $0.isPriority },
            payments: payments(in: plan, snapshot: snapshot)
        )
    }

    // MARK: - Delivery

    private func orders(in plan: FinancialPlan, typicalOrder: Money?) -> PlanBriefing.OrderAllowance {
        let budget = plan.budget(forCategoryKey: CategoryKeys.delivery)
        // A history of zero is not history: it would divide by nothing.
        let observed = typicalOrder.flatMap { $0 > 0 ? $0 : nil }
        let price = observed ?? defaultOrderPrice

        return PlanBriefing.OrderAllowance(
            monthlyBudget: budget,
            orders: price > 0 ? Int((budget / price).doubleValue.rounded(.down)) : 0,
            assumedPrice: price,
            priceFromHistory: observed != nil
        )
    }

    // MARK: - Outings

    /// Weekends are counted by their Saturdays, which is the one day every weekend has
    /// exactly one of. A five-Saturday month really does have five weekends to fund.
    private func weekends(in plan: FinancialPlan, from date: Date) -> PlanBriefing.WeekendAllowance {
        let monthly = plan.budget(forCategoryKey: CategoryKeys.outings)
        let count = max(1, saturdays(inMonthOf: date))

        return PlanBriefing.WeekendAllowance(
            monthly: monthly,
            perWeekend: (monthly / count).rounded,
            weekends: count
        )
    }

    private func saturdays(inMonthOf date: Date) -> Int {
        let start = calendar.startOfMonth(for: date)
        guard let days = calendar.range(of: .day, in: .month, for: start) else { return 4 }

        return days.reduce(0) { total, day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: start) else { return total }
            return total + (calendar.component(.weekday, from: date) == 7 ? 1 : 0)
        }
    }

    // MARK: - Debts

    /// Each debt with what it receives, in the order the plan attacks them. The extra
    /// payment goes to exactly one debt, so only the first line carries more than a
    /// minimum.
    private func payments(in plan: FinancialPlan, snapshot: FinancialSnapshot) -> [PlanBriefing.DebtPayment] {
        let ordered = plan.attackOrder.compactMap { id in
            snapshot.activeDebts.first { $0.id == id }
        }
        // Anything the strategy did not rank still has to be paid.
        let unranked = snapshot.activeDebts.filter { debt in
            !plan.attackOrder.contains(debt.id)
        }

        return (ordered + unranked).map { debt in
            let isPriority = debt.id == plan.nextTargetDebtID
            return PlanBriefing.DebtPayment(
                debtID: debt.id,
                name: debt.name,
                institution: debt.institution,
                monthly: isPriority
                    ? debt.minimumPayment + plan.allocation.extraDebtPayment
                    : debt.minimumPayment,
                minimum: debt.minimumPayment,
                annualRate: debt.annualRate,
                isPriority: isPriority,
                payoffDate: plan.projection.payoffDateByDebt[debt.id]
            )
        }
    }
}
