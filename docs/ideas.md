# Ideas

Things worth building that have not been decided on yet. One heading per idea, with
enough detail that the thinking does not have to be redone, and with the objections
written down next to the idea rather than discovered later.

For work that is already decided and only waiting on a dependency, see
[next-features.md](next-features.md).

## Block the delivery apps once the month's orders are used up

### The idea

The user agrees up front on how much delivery is in the month, either as an amount or
as a number of orders. When that is used up, Cero blocks the delivery apps on the
phone for the rest of the month. There is an emergency override, because sometimes
there really is no dinner.

Delivery is the category the app is most likely to be right about and least likely to
be listened to. It is bought in small amounts, on impulse, at the exact moment
someone is least interested in a budget. Registering the expense afterwards tells the
user something they already know. Standing between them and the order is the only
intervention that happens before the money is gone.

### How it would work on iOS

Apple provides the pieces, but not casually.

**Screen Time, through the Family Controls framework.** `ManagedSettingsStore`
shields applications, `FamilyActivityPicker` is how the user chooses which ones, and
`DeviceActivity` reports when a limit is reached. Three consequences fall out of the
design of those APIs:

1. **The app cannot name the delivery apps itself.** Tokens returned by the picker are
   opaque: Cero never learns which app is which, only that the user picked some. So
   the setup step has to be "elige tus apps de delivery" and the copy can never say
   "bloqueamos Uber Eats".
2. **The Family Controls entitlement has to be requested from Apple** and is reviewed
   individually. Not a checkbox. This is the long pole, and it decides whether the
   idea is buildable at all.
3. **The shield is drawn by an app extension**, so the screen the user hits when they
   try to order lives outside the main app and can only be handed a small amount of
   data. Whatever it says has to be short and prepared in advance.

**What triggers the block** is a budget question, not a Screen Time one. Cero already
knows the delivery category's monthly budget and what has been spent against it, so
the trigger is `BudgetConsumption.remaining <= 0` for that category. The count of
orders would be a second way to express the same limit, useful because people think
in "two deliveries a week" more readily than in lempiras.

### The emergency override

A block with no way out is a block the user will resolve by deleting Cero. The
override is what keeps the feature honest. It should be:

- **Deliberate, not one tap.** Say why, in a sentence. Not so the app can judge it,
  but so the user hears their own reason.
- **Priced, not punished.** Show what it costs in days on the freedom date, which is
  the number the whole app is built on. Then let them through.
- **Counted.** Three overrides in a month is not a discipline failure, it is a budget
  that was set too low. Cero already treats consistent overspending that way for
  categories, and the monthly close should offer to raise the delivery budget rather
  than let the user keep overriding a number that was never realistic.
- **Never silent.** The override belongs in the weekly close, next to the money.

### The objection worth taking seriously

Cero's stated tone is that it shows consequences and never judges. A hard block is the
opposite posture: it takes the decision away. That is defensible only if the user set
the trap themselves, knowingly, and can always get out of it. So:

- Blocking is off by default and has to be turned on by the user, once, in a screen
  that explains it plainly.
- The shield copy states a fact, not a verdict. "Ya usaste el delivery de este mes"
  and a way through, not "otra vez".
- Turning the whole feature off must be as easy as turning it on. A commitment device
  the user cannot leave stops being a commitment and becomes a cage.

If those cannot be held, the honest version of this feature is a notification at the
moment the budget runs out and nothing more.

### Smaller version worth shipping first

Everything above needs an Apple entitlement. Without it there is still a useful
feature: when the delivery budget is gone, send a notification saying so, and put the
override, the reason and the day cost in the app. That tests whether people want to be
stopped at all, which is the risky assumption, before spending weeks on entitlements
and app extensions.
