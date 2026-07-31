import Foundation

/// Spanish dates, written the way a person would say them.
struct PlanDateFormatter: PlanDateFormatting {
    private let dayMonth: DateFormatter
    private let monthYear: DateFormatter
    private let fullDate: DateFormatter
    /// Abbreviated month and the year, for headline slots where the full form runs out
    /// of width and gets truncated.
    private let shortDate: DateFormatter
    private let monthOnly: DateFormatter
    private let calendar: Calendar

    init(locale: Locale = Locale(identifier: "es"), calendar: Calendar = .current) {
        dayMonth = PlanDateFormatter.formatter("d 'de' MMMM", locale)
        monthYear = PlanDateFormatter.formatter("MMMM 'de' yyyy", locale)
        fullDate = PlanDateFormatter.formatter("d 'de' MMMM 'de' yyyy", locale)
        shortDate = PlanDateFormatter.formatter("d MMM yyyy", locale)
        monthOnly = PlanDateFormatter.formatter("MMMM", locale)
        self.calendar = calendar
    }

    func dayAndMonth(_ date: Date) -> String { dayMonth.string(from: date) }

    func dayAndMonth(_ date: Date, relativeTo reference: Date) -> String {
        isSameYear(date, reference) ? dayMonth.string(from: date) : fullDate.string(from: date)
    }

    func compactDayAndMonth(_ date: Date, relativeTo reference: Date) -> String {
        isSameYear(date, reference) ? dayMonth.string(from: date) : shortDate.string(from: date)
    }

    private func isSameYear(_ date: Date, _ reference: Date) -> Bool {
        calendar.component(.year, from: date) == calendar.component(.year, from: reference)
    }
    func monthAndYear(_ date: Date) -> String { monthYear.string(from: date) }
    func full(_ date: Date) -> String { fullDate.string(from: date) }
    func month(_ date: Date) -> String { monthOnly.string(from: date) }

    func horizon(months: Int?) -> String {
        guard let months else { return "sin fecha" }
        switch months {
        case ..<1: return "este mes"
        case 1: return "en 1 mes"
        default: return "en \(months) meses"
        }
    }

    func days(_ count: Int) -> String {
        abs(count) == 1 ? "1 día" : "\(abs(count)) días"
    }

    private static func formatter(_ format: String, _ locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = format
        return formatter
    }
}
