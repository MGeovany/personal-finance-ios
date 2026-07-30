import Foundation

/// Renders the dates the app talks about: freedom dates, due dates, months.
protocol PlanDateFormatting: Sendable {
    /// `15 de diciembre`
    func dayAndMonth(_ date: Date) -> String
    /// `15 de diciembre`, or `15 de diciembre de 2027` when the year differs from
    /// the reference. A payoff date more than a year out is meaningless without it.
    func dayAndMonth(_ date: Date, relativeTo reference: Date) -> String
    /// `diciembre de 2026`
    func monthAndYear(_ date: Date) -> String
    /// `15 de diciembre de 2026`
    func full(_ date: Date) -> String
    /// `diciembre`
    func month(_ date: Date) -> String
    /// `en 8 meses`, `este mes`
    func horizon(months: Int?) -> String
    /// `9 días`, `1 día`
    func days(_ count: Int) -> String
}
