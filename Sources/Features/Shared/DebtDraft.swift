import Foundation

/// A debt being entered or edited.
///
/// The interest rate is held as a percentage because that is what statements show;
/// the conversion to the fraction the engine uses happens in one place.
struct DebtDraft: Identifiable, Equatable {
    var id = UUID()
    var name: String = ""
    var institution: String = ""
    var kind: DebtKind = .creditCard
    var balance: Money = 0
    var currency: CurrencyCode = .hnl
    var creditLimit: Money = 0
    /// Annual rate as the user reads it: `48` for 48 %.
    var annualRatePercent: Double = 0
    var minimumPayment: Money = 0
    var statementDay: Int?
    var dueDay: Int?
    var status: DebtStatus = .active

    var annualRate: Double { annualRatePercent / 100 }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && balance > 0
    }

    /// Only revolving accounts have a meaningful limit.
    var effectiveCreditLimit: Money? {
        guard kind.isRevolving, creditLimit > 0 else { return nil }
        return creditLimit
    }
}

extension DebtDraft {
    init(_ entity: DebtEntity) {
        self.init(
            id: entity.uuid,
            name: entity.name,
            institution: entity.institution,
            kind: entity.kind,
            balance: entity.balance,
            currency: entity.currency,
            creditLimit: entity.creditLimit ?? 0,
            annualRatePercent: entity.annualRate * 100,
            minimumPayment: entity.minimumPayment,
            statementDay: entity.statementDay,
            dueDay: entity.dueDay,
            status: entity.status
        )
    }

    func makeEntity() -> DebtEntity {
        DebtEntity(
            uuid: id,
            name: name,
            institution: institution,
            kind: kind,
            balance: balance,
            currency: currency,
            creditLimit: effectiveCreditLimit,
            annualRate: annualRate,
            minimumPayment: minimumPayment,
            statementDay: statementDay,
            dueDay: dueDay,
            status: status
        )
    }

    /// Copies the draft onto an existing row, leaving payment history intact.
    func apply(to entity: DebtEntity) {
        entity.name = name
        entity.institution = institution
        entity.kind = kind
        entity.balance = balance
        entity.currency = currency
        entity.creditLimit = effectiveCreditLimit
        entity.annualRate = annualRate
        entity.minimumPayment = minimumPayment
        entity.statementDay = statementDay
        entity.dueDay = dueDay
        entity.status = status
    }
}
