# Google Sans Flex: where these files came from

The five `GoogleSansFlex-*.ttf` files are static weight instances fetched from the
Google Fonts API on 2026-07-30:

```
https://fonts.googleapis.com/css2?family=Google+Sans+Flex:wght@100..1000
```

Requested with a legacy user agent so the API serves TrueType rather than WOFF2,
which iOS cannot load. Weights taken: 300, 400, 500, 600, 700.

## Confirm the license before shipping

Google's own catalogue metadata marks the family `isOpenSource: true` and
`isBrandFont: true`, added 2025-11-12. Unlike Quicksand and Elms Sans, it is **not
yet mirrored in the open `google/fonts` repository**, so there was no `OFL.txt` to
bundle alongside these files the way the other two families have one.

Before this app is distributed, someone has to:

1. Find the license text Google publishes for Google Sans Flex and add it here, the
   same as `Quicksand-OFL.txt` and `ElmsSans-OFL.txt`.
2. Check the trademark terms. Google's other brand font in the open repository,
   Google Sans Code, ships a `TRADEMARKS.md` restricting use of the name for modified
   versions. The same is likely to apply here. The files are unmodified, which is the
   easy case, but the terms should be read rather than assumed.

Everything needed to swap the family out is one line in `Typeface.active`, so if the
terms turn out not to allow bundling, Quicksand and Elms Sans are still in the
project and already licensed.

## No tabular figures

Digit advances at weight 500 measure `[650, 386, 540, 547, 600, 571, 569, 505, 564,
569]`, so the figures are proportional. `.monospacedDigit()` in `Typography` has
nothing to apply. The same is true of Quicksand and Elms Sans, so this is not a
regression, but a number animating in place will shift. A family with a `tnum`
feature is the fix if that ever matters.
