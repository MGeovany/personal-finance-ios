import Testing
@testable import Cero

/// The setup flow's navigation: which questions a given user is asked, in what
/// order, and what the progress bar tells them.
@MainActor
struct OnboardingFlowTests {
    @Test("A user with nothing to declare is never asked to price it")
    func pathSkipsUnaskedFollowUps() {
        let model = makeModel()

        #expect(!model.path.contains(.commitmentAmounts))
        #expect(!model.path.contains(.debtAmounts))
    }

    @Test("Ticking a monthly payment adds the question that prices it")
    func tickingCommitmentAddsAmountsStep() {
        let model = makeModel()

        model.toggle(CommitmentTemplate.rent)

        #expect(model.path.contains(.commitmentAmounts))
    }

    @Test("Ticking a debt adds the question that prices it")
    func tickingDebtAddsAmountsStep() {
        let model = makeModel()

        model.toggle(DebtKind.creditCard)

        #expect(model.path.contains(.debtAmounts))
    }

    @Test("Unticking the last payment removes the pricing question again")
    func untickingRemovesAmountsStep() {
        let model = makeModel()

        model.toggle(CommitmentTemplate.rent)
        model.toggle(CommitmentTemplate.rent)

        #expect(!model.path.contains(.commitmentAmounts))
        #expect(model.draft.commitmentAmounts.isEmpty)
    }

    @Test("Advancing walks only the questions this user is being asked")
    func advanceFollowsVisiblePath() {
        let model = makeModel()
        model.advance() // welcome -> name
        model.draft.name = "Ana"

        var visited: [OnboardingStep] = [model.step]
        while !model.step.isLast {
            model.advance()
            visited.append(model.step)
        }

        #expect(!visited.contains(.commitmentAmounts))
        #expect(!visited.contains(.debtAmounts))
        #expect(visited.last == .review)
    }

    @Test("Going back retraces the same questions")
    func goBackRetracesPath() {
        let model = makeModel()
        model.advance()
        model.advance()
        let currency = model.step

        model.goBack()
        model.advance()

        #expect(model.step == currency)
        #expect(model.isMovingForward)
    }

    @Test("The cover and the summary are not counted as questions")
    func progressCountsQuestionsOnly() {
        let model = makeModel()
        let questions = model.path.filter(\.countsTowardProgress).count

        model.advance() // the first real question

        #expect(model.progress == (1, questions))
        #expect(!OnboardingStep.welcome.countsTowardProgress)
        #expect(!OnboardingStep.review.countsTowardProgress)
    }

    @Test("A question with no answer yet offers to be skipped")
    func emptyOptionalStepOffersToSkip() {
        let model = makeModel()
        while model.step != .goals { model.advance() }

        #expect(model.advanceTitle == "Omitir")

        model.toggle(GoalTemplate.trip)

        #expect(model.advanceTitle == "Continuar")
    }

    @Test("Setup cannot be finished without the one number a plan needs")
    func incomeBlocksAdvance() {
        let model = makeModel()
        while model.step != .income { model.advance() }

        #expect(!model.canAdvance)
        #expect(model.blockedReason != nil)

        model.draft.primaryIncome = 25_000

        #expect(model.canAdvance)
        #expect(model.blockedReason == nil)
    }

    @Test("A ticked payment with no amount holds the flow, and says which one")
    func missingCommitmentAmountBlocksAdvance() {
        let model = makeModel()
        model.toggle(CommitmentTemplate.rent)
        while model.step != .commitmentAmounts { model.advance() }

        #expect(!model.canAdvance)
        #expect(model.blockedReason?.contains("alquiler") == true)

        model.setAmount(9_000, for: .rent)

        #expect(model.canAdvance)
    }

    @Test("Restarting clears the answers and the finished flag")
    func restartClearsEverything() {
        let model = makeModel()
        model.draft.name = "Ana"
        model.draft.primaryIncome = 25_000
        model.finish()

        model.restart()

        #expect(model.step == .welcome)
        #expect(!model.hasFinished)
        #expect(model.draft == OnboardingDraft())
    }

    private func makeModel() -> OnboardingViewModel {
        OnboardingViewModel(committer: CommitterSpy(), preferences: PreferencesSpy())
    }
}
