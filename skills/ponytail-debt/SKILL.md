---
name: ponytail-debt
description: "List every `shortcut:` comment in the repo as a debt ledger with its ceiling and upgrade trigger. Reads and reports, changes nothing. Use for ponytail debt, deferred shortcuts, or a list of known limits."
disable-model-invocation: true
---

The `caveman-ponytail` skill marks each deliberate shortcut with `shortcut: <limit>, <when to upgrade>`. This skill collects those markers so a deferral cannot become permanent without notice. Source: [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT), `ponytail-debt`.

## Scan

Run `git grep --no-index --exclude-standard -nE '(#|//|/[*]) ?shortcut:'`. Add comment prefixes if the stack uses others. If the user names another marker word, grep for that word instead.

Each hit is one ledger row. Skip a hit that is not a deferral, such as a note about a keyboard shortcut.

## Output

One row per marker, grouped by file:

`<file>:<line>, <what was simplified>. ceiling: <limit>. upgrade: <trigger>.`

Tag `no-trigger` on each marker that names no upgrade trigger. Those markers rot.

End with `<N> markers, <M> with no trigger.` If there are no hits, write `No shortcut debt.` Done when the last line is written.

Report only. Write the ledger to a file (for example `PONYTAIL-DEBT.md`) only if the user asks.
