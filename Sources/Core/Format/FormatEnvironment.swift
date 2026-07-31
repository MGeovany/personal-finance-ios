import SwiftUI

/// Formatting and conversion, reachable from any view.
///
/// Amount fields and date rows appear too deep in too many screens for each one to
/// thread a formatter down by hand. The defaults are the real implementations, so a
/// preview works without a container behind it.
private struct MoneyFormatterKey: EnvironmentKey {
    static let defaultValue: MoneyFormatting = MoneyFormatter()
}

private struct ExchangeRatesKey: EnvironmentKey {
    static let defaultValue: ExchangeRateProviding = StaticExchangeRateProvider()
}

private struct PlanDatesKey: EnvironmentKey {
    static let defaultValue: PlanDateFormatting = PlanDateFormatter()
}

/// The currency amounts are stored in, so a field knows what its bound value means
/// without being told at every call site.
private struct PlanCurrencyKey: EnvironmentKey {
    static let defaultValue: CurrencyCode = .hnl
}

extension EnvironmentValues {
    var moneyFormatter: MoneyFormatting {
        get { self[MoneyFormatterKey.self] }
        set { self[MoneyFormatterKey.self] = newValue }
    }

    var exchangeRates: ExchangeRateProviding {
        get { self[ExchangeRatesKey.self] }
        set { self[ExchangeRatesKey.self] = newValue }
    }

    var planDates: PlanDateFormatting {
        get { self[PlanDatesKey.self] }
        set { self[PlanDatesKey.self] = newValue }
    }

    var planCurrency: CurrencyCode {
        get { self[PlanCurrencyKey.self] }
        set { self[PlanCurrencyKey.self] = newValue }
    }
}
