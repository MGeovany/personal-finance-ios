# Cero

An iOS personal finance app built around a single goal: **getting out of debt**.

Cero is not a spreadsheet. Opening it answers five questions:

1. How much do I owe?
2. How much can I spend this week?
3. What should I pay now?
4. When could I be debt free?
5. What is slowing me down?

> The repository name is provisional and will be changed later.

## Language convention

All documentation, code, comments and commit messages are in **English**. Only the
text the user actually sees on screen is in **Spanish**. and that copy lives in the
presentation layer (`Core/Format` and the feature views), never in the engine.

## Stack

- SwiftUI (iOS 18+), Swift
- SwiftData for local persistence. No backend, no login
- XcodeGen: the project is generated from `project.yml`

## Running it

```bash
make open     # generates Cero.xcodeproj and opens it in Xcode
make build    # builds for the simulator
make run      # builds, installs and launches on the booted simulator
make mock     # same, loading the saved sample user
make erase    # uninstalls the app, so the next launch starts at setup
```

`Cero.xcodeproj` is not versioned: regenerate it with `xcodegen generate`.

### Starting state

The app starts **empty**. The first launch goes to setup and the data is whatever
the user enters.

A **sample user** (`MockUser`) is saved alongside it: L45,000 of income, three debts
totalling L175,500, utilities, subscriptions, a goal and a few days of spending. It
never loads on its own. It has to be asked for, either with `make mock` (which
passes `CERO_MOCK_USER=1`) or from **Ajustes › Desarrollo** in debug builds. It only
loads into an empty store, so it can never overwrite real entries.

That same section has **Borrar todos mis datos**, which empties the store and returns
to setup.

## Architecture

Four layers, dependencies always pointing downward. Each layer talks to the next
through protocols, and each file has one responsibility.

```
Sources/
  App/         Entry point, dependency composition, top-level routing
  Features/    One folder per screen: view + view model + subviews
  Core/
    Design/    Design system: palette, typography, reusable components
    Format/    Spanish wording and number/date formatting
    Store/     SwiftData: entities, repositories, snapshot assembly
    Notifications/  What is worth notifying, and how it is delivered
    Engine/    Planning engine (pure. No UI, no persistence)
    Domain/    Pure value types, no dependencies
```

### The engine

`Domain` and `Engine` import neither SwiftUI nor SwiftData: they are plain Swift and
carry no language, which is what makes them verifiable without a simulator. The
engine takes a `FinancialSnapshot` (an immutable picture of the user's finances) and
produces a `FinancialPlan`.

Each step of the calculation is a small object behind a protocol:

| Protocol | Responsibility |
|---|---|
| `CashFlowCalculating` | Income minus every unavoidable commitment: what is really left |
| `EmergencyFundAdvising` | Recommended cushion, monthly contribution, savings worth spending |
| `LifestyleBudgeting` | Per-category budgets, respecting realistic floors |
| `SurplusAllocating` | Splits the surplus between debt, buffer, goals and free margin |
| `DebtPrioritizing` | Attack order: avalanche, snowball or custom |
| `DebtProjecting` | Month-by-month simulation: freedom date and total interest |
| `PlanBuilding` | Composes the above into a complete plan |
| `PlanSetBuilding` | Builds the three comparable plans |
| `TargetDateSolving` | Is your target date possible, and at what cost? |
| `ImpactEvaluating` | How many days a concrete decision moves your date |
| `ScenarioApplying` | Applies a hypothetical decision without touching real data |
| `WeeklyBudgetSplitting` | Cuts the monthly budget into weeks that sum back exactly |
| `GroceryBudgetSplitting` | Splits groceries into a main run and weekly top-ups |

Adding a payoff strategy or a plan speed means adding a type, not editing the
existing ones.

### Two engine behaviours the app depends on

- **Rollover.** The monthly outlay stays constant. When a debt clears, its minimum
  keeps being paid. Into the next debt in line. The user never redirects anything
  by hand.
- **Day-level dates.** Money is assumed to arrive evenly through the month, so a
  payoff date lands on a day rather than a month boundary. That is what makes
  "this brings your date nine days closer" a real number instead of a jump between
  whole months.

### The three speeds

`Suelto`, `Balanceado` (recommended) and `Agresivo` are one algorithm with different
parameters (`PlanTuning`): how much lifestyle is trimmed, how much of the surplus
goes to debt, how large the buffer is, and whether secondary goals keep moving. The
names are editable.

No speed can recommend an impossible budget: every category has a floor proportional
to what the user declared, and essentials (groceries, transport) are cut far less
than discretionary spending. A category the user consistently overspends is treated
as under-budgeted rather than as a discipline problem, and the app offers to raise it.

### State and recalculation

`PlanStore` holds the single plan the whole app reads. Features mutate their own
repository and then ask for a recalculation, so no screen can display a number that
no longer follows from the data. `SnapshotAssembler` is the only seam between
storage and calculation. Every amount is converted to the user's main currency
there, before the engine sees it.
