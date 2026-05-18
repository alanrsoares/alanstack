---
name: alanstack
description: Apply Alan's TypeScript/Bun coding style inferred from Yappr, SafeURL, RecallOS, Printr MCP, and re-reduced. Use when writing, refactoring, reviewing, or planning TypeScript code, Bun monorepos, Result/ResultAsync flows, Maybe/nullable handling, ts-pattern matching, validation boundaries, tests, lint/typecheck setup, or commits in Alan's projects.
---

# Coding Style

Use this skill to make code feel native to Alan's TypeScript projects. Repository instructions still win: read `AGENTS.md`, package scripts, and nearby code before applying these defaults.

## Operating Loop

1. Read local context first: `AGENTS.md`, `package.json`, tool configs, and neighboring files.
2. Preserve the repo's chosen tools. Do not replace ESLint with Biome, Biome with ESLint, Bun with npm, or a local helper with a new abstraction unless the task is explicitly about that migration.
3. Make the smallest coherent change that improves the code path under discussion.
4. Verify with the repo's scripts. For TypeScript changes, prefer lint, typecheck, and the narrowest relevant tests; broaden when touching shared behavior.
5. Commit with Conventional Commits only when asked. Do not add co-author or AI attribution.

## Tooling Defaults

- Bun-first in modern repos: use `bun`, `bun run`, `bun test`, and `bunx`; avoid npm/yarn/pnpm workflows unless the repo is legacy or explicitly configured that way.
- Prefer Bun APIs in Bun repos: `Bun.file`, `Bun.write`, `Bun.$`, `spawn` from `"bun"`, `bun:sqlite`, `Bun.sql`, `Bun.redis`.
- Use `node:` imports only where Bun does not provide the needed primitive or the surrounding code already uses Node APIs for a good reason.
- Keep monorepos scalable: root scripts should fan out to package/app scripts; each package/app owns its lint, typecheck, test, and build commands where practical.
- Match existing formatter/linter strictness. Strict TypeScript, no casual `any`, no unused code, no one-off disabled rules without a local reason.

## Type And Error Model

- Model recoverable failure with `neverthrow` `Result` / `ResultAsync` at service, IO, business, API, database, and tool-handler boundaries.
- Async failable functions should return `ResultAsync<T, E>`, not `Promise<Result<T, E>>`.
- Keep throws inside boundary wrappers such as `ResultAsync.fromPromise`, repo-local `tryAsync`, or an equivalent helper.
- Use domain-specific error classes or tagged error unions when callers need to branch; use `Error` when callers only need a message.
- Preserve failure causes. Do not encode an error as `null`, `undefined`, `false`, or `Maybe.none()`.
- Convert nullable data to errors only where absence is actually an error.

## Maybe, Nullable, Result

Use `Maybe<T>` for expected absence, not failure. In RecallOS it is `Result<T, None>` with helpers like `fromNullable`, `match`, `compact`, and `toResult`; copy or reuse that shape only when the repo already has or needs it.

- Good `Maybe` cases: cache miss, optional relationship, polling not-ready-yet, search with no match, optional service.
- Good `Result` cases: parse failure, invalid persisted data, IO failure, API/database failure, permission/auth failure.
- Keep nullable values at the edge if they are simple and local. Introduce `Maybe` when it clarifies a pipeline or removes repeated null checks.
- When absence becomes a failure, convert explicitly:

```ts
return Maybe.toResult(Maybe.fromNullable(row), () => new Error("Not found"));
```

## ts-pattern

Use `ts-pattern` for exhaustive branching over finite domain states and tagged unions the repo owns.

- Prefer `.exhaustive()` for owned unions: job status, provider, message role, event type, tool state, proto payload discriminator.
- Use `.otherwise()` only for external/open unions where intentional fallback behavior is required.
- Do not use `ts-pattern` for simple null checks, generic booleans, or a two-branch condition where `if` is clearer.
- Prefer matching data shape over precomputing brittle discriminator strings.

```ts
return match(event)
  .with({ type: "message" }, renderMessage)
  .with({ type: "tool-call" }, renderToolCall)
  .with({ type: "error" }, renderError)
  .exhaustive();
```

## Functional Shape

- Prefer pure helpers, immutable transformations, named predicates/selectors, and small functions.
- Use terse arrow functions for single-expression helpers.
- Use named `function` declarations for multiline bodies, locals, branching, public helpers, and recursive or hoisted code.
- Omit explicit return types when obvious; add them for public APIs, exported helpers, complex generics, Result boundaries, and callbacks where inference gets vague.
- Avoid inline object types in signatures or collections; extract named `type` or `interface` when the shape is meaningful.
- Avoid enums. Prefer string literal unions, tagged unions, `as const` objects, or schema-derived types.
- Avoid IIFEs and immediate invocation of composed/curried functions. Extract a named helper or intermediate value.

## Branching And Dispatch

- Use `Record<K, () => V>` or `Map<K, V>` for closed mode/token/action dispatch where every key is known.
- Use ordered `{ when, render }[]` plus `.find()` for prioritized UI state or first-match rendering.
- Use `ts-pattern` when the branch belongs to a domain union and exhaustiveness matters.
- Use ordinary `if` when it is the clearest expression of guard clauses or linear validation.

## Boundaries And Validation

- Use Zod or the repo's schema system for untrusted input: persisted JSON, API responses, CLI args, RPC payloads, config files, and external tool output.
- Keep DTOs/API responses separate from raw database entities when exposure matters.
- Parse at boundaries, then pass typed values inward.
- Keep secrets server-side or in user/env configuration. Never commit `.env` or real API keys.
- Prefer structured parsing over ad hoc string manipulation when a parser or schema is available.

## Imports And Packages

- Follow repo-local alias rules. In Yappr-style packages, use `~/` for package-local source and `.js` extensions for relative/intra-package ESM imports where required.
- Use workspace package imports for cross-package boundaries; do not deep-import private source unless that is already the repo convention.
- Keep exports maps and generated types authoritative. Regenerate OpenAPI/proto/generated clients through existing scripts.

## Tests And Verification

- Use the repo's test runner. In Bun repos, write tests with `bun:test`.
- Prefer focused tests for narrow refactors; add integration or regression tests when changing shared contracts, persistence, IO, or user-visible workflows.
- Naming commonly used across these repos: `*.spec.ts` for units, `*.integration.test.ts` for integrations, `*.smoke.test.ts` for smoke tests. Preserve existing conventions in the target package.
- Run typecheck and lint for TypeScript changes; run Python tests when touching Python.
- For refactors, prove behavior is unchanged with tests or a targeted before/after check.

## Review Heuristics

Look for these improvements when reviewing or refactoring:

- `Promise<Result<...>>` that should be `ResultAsync`.
- Nullable parse or persisted-data paths that should return `Result`.
- Repeated null checks that would read better as `Maybe`.
- Switch/if chains over owned unions that should be exhaustive `ts-pattern`.
- Hidden `throw`s inside business logic.
- Inline anonymous object types repeated across functions.
- Dispatch tables or ordered render rules that would remove branching noise.
- Root-only monorepo checks that should be per-package and parallelizable.

## Source Signals

Read `references/source-signals.md` only when rules conflict, when applying this skill outside the inferred source repos, or when updating the skill itself. It summarizes which source repos contributed each rule and helps resolve tradeoffs.
