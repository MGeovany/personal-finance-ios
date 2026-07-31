# Next features

Work the app needs but does not have yet, with the reasoning behind each one so the
decision does not have to be made twice.

## Keeping credit card rates current

### Where it stands

`CreditCardRates` estimates a card's annual rate from its tier. `Visa Classic` is
assumed to sit near the top of the market range, `Visa Infinite` near the bottom, and
an unrecognised card falls back to the middle of `DebtKind.creditCard.typicalRates`.
The table carries `reviewedOn`, a hardcoded date, and the setup screen shows it:

> Tasa estimada, revisada el 30 de julio. Puede ser inexacta o haber cambiado: si
> tienes tu estado de cuenta, corrígela.

This is honest and it unblocks setup, but it has two limits worth naming:

1. **The date goes stale silently.** Nothing forces the table to be reviewed. Six
   months from now the app will still say "revisada el 30 de julio" with the same
   confidence.
2. **The estimate is a tier heuristic, not a quoted rate.** It is deliberately never
   presented as one, but a wrong estimate still shifts the freedom date the plan
   promises, because the projection compounds it every month.

### What it would take

Rates are set per issuer and change without notice, so no client-side table stays
true. Refreshing them needs something outside the app:

**Option A: a small backend with a scheduled job.** A cron job (or a scheduled
function on whatever host) runs monthly, reads published rates from each bank's site
or from the regulator's disclosures, and writes a versioned JSON document. The app
fetches it, caches it, and shows the document's own `reviewedOn`. This is the only
option where the date on screen is a fact rather than a promise.

- Needs: a host, a scraper or a data source per bank, and a review step, because a
  scraper that silently breaks is worse than a stale constant.
- The app changes very little: `CreditCardRates` grows a remote source behind the
  same interface, and the estimate keeps working offline from the last cached
  document.

**Option B: crowdsourced, from the users who already correct it.** Every time a user
overwrites an estimated rate the app learns the real one for that card. Aggregating
those corrections gives a distribution per card without scraping anything. This
needs a backend too, but a much smaller one, and it needs consent: sending anything
about a user's debts off the device is a change to the app's current promise that
nothing leaves the phone.

**Option C: do nothing automatic, and make the staleness visible.** Keep the table
in the app, and when `reviewedOn` is more than a few months old, soften the wording
and put the correction prompt in front of the user instead of under the field. Costs
nothing, ships now, and is the honest version of the status quo.

### Recommendation

Start with **Option C**, because it is a copy change and it removes the worst
behaviour, which is stating a stale date with a straight face. Move to **Option A**
when the app has a backend for any other reason. Do not build a backend solely for
this: the estimate only has to be close enough for the first plan, and the user can
correct it in one tap.

### Also worth doing while in there

- Recalculate the plan when a rate is corrected after setup, and show the impact in
  days, the same way every other decision in the app is shown.
- Flag a card whose estimated rate is doing a lot of work in the projection, for
  example when it is the avalanche target and its rate was never confirmed. That is
  the one number worth asking the user to go check.
