# GritQL Plugins And Codemods

Two different automation tools for two different jobs. Don't reach for a codemod when a plugin will do, and don't hand-edit a pattern that recurs across the repo.

- **GritQL Biome plugin** — a `.grit` rule registered in `biome.json`, runs on every lint (CI, editor, pre-commit). Use for a **quality-bar rule that should stay enforced going forward** — the pattern must never come back.
- **Codemod** — a one-off script that rewrites the repo once. Use for a **mechanical migration** (renaming an API, converting a call pattern repo-wide) that doesn't need continuous enforcement after it lands.

## GritQL plugins

Only applies to Biome repos (see [preferred-tools.md](preferred-tools.md#lint--format)). Requires Biome with plugin support.

**Config** — register the plugin's path in `biome.json`:

```json
{
  "plugins": ["./biome/plugins/no-any.grit"]
}
```

Convention: keep plugin files under `biome/plugins/<rule-name>.grit` in the target repo.

**Syntax essentials**:

- Default target language is JavaScript; add `language js(typescript);` for TS-specific constructs, or `language css;` / `language json;` for those targets.
- For CST-level node matching (not just snippet matching), add `engine biome(1.0)` above the language directive.
- `` `code snippet` `` with `$name` captures a pattern; `as $binding` names the whole match; `where { ... }` attaches conditions and actions.
- `register_diagnostic(span, message, severity, fix_kind)` reports a finding. `severity` is `hint | info | warn | error`.
- `$match => \`replacement\`` supplies a rewrite. `fix_kind = "safe"` lets `biome check --write` apply it automatically; omit or mark `"unsafe"` to require `--write --unsafe`. No `fix_kind` on a rewrite defaults to unsafe.
- Diagnostic-only plugins (no rewrite) are the common case — most of the quality bar is easier to flag than to auto-fix correctly.

**Working example** (from Biome's docs) — enforces the quality bar's "no `any`" rule:

```
engine biome(1.0)
language js(typescript)

TsAnyType() as $any where {
    register_diagnostic(
        span = $any,
        message = "Don't use `any`. Use `unknown`, a specific type, or a generic instead.",
        severity = "error"
    )
}
```

**Other quality-bar rules worth prototyping** (syntax unverified — confirm against the installed Biome version):

- `Promise<Result<...>>` return types (should be `ResultAsync<T, E>`).
- `throw` inside `*.service.ts` / `*.handler.ts`, outside a wrapper call.

Skip GritQL for rules needing real type information (e.g. "is this actually a `Result`?") — Grit matches syntax, not inferred types. Use a custom `ts-eslint` rule or code review instead.

Full syntax reference: [biomejs.dev/reference/gritql](https://biomejs.dev/reference/gritql/). Worked examples: [biomejs.dev/recipes/gritql-plugins](https://biomejs.dev/recipes/gritql-plugins/).

## Codemods

Defaults (`ts-morph`, `jscodeshift`): see [preferred-tools.md#codemods](preferred-tools.md#codemods).

For a one-time rewrite that fits Grit's pattern-match-and-replace model, run a `.grit` rule once via `biome check --write --unsafe <path>`, then delete it unless it's also worth keeping as a standing rule. Run any codemod on a branch, diff the result, and verify with [`alanstack-qa`](../../alanstack-qa/SKILL.md) before committing — repo-scale automation gets the same "prove behavior is unchanged" bar as a hand-written refactor.
