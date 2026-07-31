import Testing
@testable import Cero

/// What the answers turn into: the rows storage will hold, and the guesses the flow
/// makes on the user's behalf so they are never asked for something they would have
/// to look up.
@MainActor
struct OnboardingAnswerTests {
    // MARK: - Monthly payments

    @Test("A ticked payment lands in the bucket that decides how it is treated")
    func commitmentsSortIntoBuckets() {
        let model = makeModel()

        model.toggle(CommitmentTemplate.rent)
        model.setAmount(9_000, for: .rent)
        model.toggle(CommitmentTemplate.electricity)
        model.setAmount(1_800, for: .electricity)
        model.toggle(CommitmentTemplate.streaming)
        model.setAmount(500, for: .streaming)

        #expect(model.draft.fixedExpenses.map(\.name) == ["Alquiler"])
        #expect(model.draft.utilities.map(\.name) == ["Luz"])
        #expect(model.draft.subscriptions.map(\.name) == ["Streaming"])
        #expect(model.draft.totalCommitted == 11_300)
    }

    @Test("A payment with no amount is not written as a zero row")
    func unpricedCommitmentIsNotWritten() {
        let model = makeModel()

        model.toggle(CommitmentTemplate.rent)

        #expect(model.draft.fixedExpenses.isEmpty)
        #expect(model.draft.commitmentsMissingAmounts == [.rent])
    }

    @Test("Anything the list did not cover is still kept, as a fixed expense")
    func customCommitmentIsKept() {
        let model = makeModel()

        model.addCustomCommitment(ChargeDraft(name: "Cuota del club", amount: 750))

        #expect(model.draft.fixedExpenses.map(\.name) == ["Cuota del club"])
    }

    // MARK: - Debts

    @Test("Ticking a debt fills in the rate such debts usually carry")
    func debtArrivesWithAssumedRate() {
        let model = makeModel()

        model.toggle(DebtKind.creditCard)

        let debt = try! #require(model.draft.debts.first)
        #expect(debt.annualRatePercent == DebtKind.creditCard.assumedRate)
        #expect(debt.name == DebtKind.creditCard.suggestedName)
    }

    @Test("The suggested minimum payment follows the balance as it is typed")
    func minimumFollowsBalance() {
        let model = makeModel()
        model.toggle(DebtKind.creditCard)
        let debt = try! #require(model.draft.debts.first)

        model.setBalance(80_000, for: debt)

        #expect(model.draft.debts[0].minimumPayment == 4_000)

        model.setBalance(100_000, for: model.draft.debts[0])

        #expect(model.draft.debts[0].minimumPayment == 5_000)
    }

    @Test("A minimum the user typed is never overwritten by the suggestion")
    func typedMinimumSurvivesBalanceChange() {
        let model = makeModel()
        model.toggle(DebtKind.creditCard)
        model.setBalance(80_000, for: model.draft.debts[0])

        model.setMinimum(2_500, for: model.draft.debts[0])
        model.setBalance(90_000, for: model.draft.debts[0])

        #expect(model.draft.debts[0].minimumPayment == 2_500)
    }

    @Test("Saying there are no debts clears the ones already ticked")
    func decliningDebtsClearsThem() {
        let model = makeModel()
        model.toggle(DebtKind.creditCard)

        model.declareNoDebts()

        #expect(model.draft.debts.isEmpty)
        #expect(model.draft.hasNoDebts)

        model.toggle(DebtKind.carLoan)

        #expect(!model.draft.hasNoDebts)
    }

    // MARK: - Offered amounts

    @Test("Offered amounts are numbers a person would say out loud")
    func bandsRoundToSpeakableAmounts() {
        let options = AmountBands.shares(
            [("Poco", 0.02), ("Normal", 0.06), ("Bastante", 0.12)],
            of: 45_000,
            currency: .hnl
        )

        #expect(options.map(\.amount) == [900, 2_700, 5_400])
    }

    @Test("Dollar amounts round in tens, not in hundreds")
    func bandsRespectSmallDenominations() {
        let options = AmountBands.shares(
            [("Poco", 0.02), ("Normal", 0.14)],
            of: 1_200,
            currency: .usd
        )

        #expect(options.map(\.amount) == [25, 170])
    }

    @Test("Two bands that round to the same amount are only offered once")
    func bandsAreDistinct() {
        let options = AmountBands.shares(
            [("A", 0.10), ("B", 0.11), ("C", 0.30)],
            of: 1_000,
            currency: .hnl
        )

        #expect(options.count == 2)
    }

    // MARK: - Commit

    @Test("Everything the user was asked reaches storage")
    func commitCarriesTheAnswers() {
        let spy = CommitterSpy()
        let model = OnboardingViewModel(committer: spy, preferences: PreferencesSpy())
        model.draft.name = "  Ana  "
        model.draft.primaryIncome = 25_000
        model.draft.remindersEnabled = false
        model.draft.reminderHour = 20

        model.finish()

        let committed = try! #require(spy.committed)
        #expect(committed.name == "  Ana  ")
        #expect(!committed.remindersEnabled)
        #expect(model.hasFinished)
    }

    private func makeModel() -> OnboardingViewModel {
        OnboardingViewModel(committer: CommitterSpy(), preferences: PreferencesSpy())
    }
}
