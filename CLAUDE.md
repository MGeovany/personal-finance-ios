# Cero agent instructions

## Copy and punctuation

- Never use em dashes (`—`) or en dashes (`–`) in user-facing copy, comments, docs, or code strings.
- Prefer commas, periods, colons, or a short rewrite. For empty UI values use words (`Sin fecha`, `N/D`) or an ellipsis (`···`), not a dash.
- ASCII hyphens inside identifiers, file names, and compound tokens (`liquid-glass`, `iOS-18`) are fine. Do not use a hyphen as a sentence dash.

## Engineering defaults

- Prefer **SOLID**: small types with one job, depend on abstractions the app already has, keep UI free of engine/storage details.
- **Componentize** by default. If the same UI or logic appears twice, extract a named view, modifier, or helper in the design system or the feature folder. Do not leave one-off duplicates.
- Follow existing project patterns and good practices: clear names, short focused functions, no drive-by refactors outside the task.

## When unsure

- If an instruction is ambiguous, incomplete, or could go two ways, **ask before implementing**. Do not guess product copy, data model, or navigation.

## When something was wrong or must be redone

- If the user says the change is wrong, or asks to do it again differently: **delete the previous attempt**, remove leftover files, unused symbols, and dead UI paths. Do not leave abandoned code next to the new solution. Clean first, then rebuild.
