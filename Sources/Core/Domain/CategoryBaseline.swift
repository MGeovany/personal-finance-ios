import Foundation

/// What the user says a category costs them, plus what the app has observed.
///
/// `baseline` is the declared number; `historicalAverage` is what actually
/// happened. When the two disagree for weeks, the app offers to raise the budget
/// instead of quietly recommending something impossible.
struct CategoryBaseline: Identifiable, Equatable, Sendable {
    var id: UUID
    var key: String
    var name: String
    var icon: String
    var baseline: Money
    var flexibility: CategoryFlexibility
    var historicalAverage: Money?
    var isHidden: Bool
    var order: Int
    /// An amount the user pinned by hand. Plans must honour it exactly instead of
    /// scaling it, because the user already told the app what they want to spend.
    var override: Money?

    /// The lowest amount any plan may assign to this category.
    var floor: Money {
        override ?? realisticBaseline.scaled(by: flexibility.floorFactor)
    }

    /// A category the user consistently overspends is under-budgeted, no matter
    /// what they declared. Observed spending then becomes the real baseline.
    var realisticBaseline: Money {
        if let override { return override }
        guard let historicalAverage, historicalAverage > baseline else { return baseline }
        return historicalAverage
    }

    /// Pinned categories are not scaled by the plan's speed.
    var isPinned: Bool { override != nil }

    var isOverspentHistorically: Bool {
        guard let historicalAverage, baseline > 0, override == nil else { return false }
        return historicalAverage > baseline.scaled(by: 1.15)
    }

    init(
        id: UUID = UUID(),
        key: String,
        name: String,
        icon: String,
        baseline: Money,
        flexibility: CategoryFlexibility,
        historicalAverage: Money? = nil,
        isHidden: Bool = false,
        order: Int = 0,
        override: Money? = nil
    ) {
        self.id = id
        self.key = key
        self.name = name
        self.icon = icon
        self.baseline = baseline
        self.flexibility = flexibility
        self.historicalAverage = historicalAverage
        self.isHidden = isHidden
        self.order = order
        self.override = override
    }

    func pinning(_ amount: Money?) -> CategoryBaseline {
        var copy = self
        copy.override = amount
        return copy
    }
}
