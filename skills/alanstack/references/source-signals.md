# Source Signals

The rules in this skill come from several private TypeScript / Bun repos: desktop, terminal, web, MCP/SDK, and inference-sidecar surfaces. The repo names are not given here. Each cluster of rules names the *kind* of repo it came from.

## Repo categories

### Bun-workspace monorepo with `AGENTS.md` + strict TS

- Per-package scripts (`typecheck`, `lint`, `test`) with root fanout via `bun run --filter`.
- `AGENTS.md` gives Bun-first conventions. Use `Bun.file` / `Bun.$` / `bun:sqlite` over `node:`. Use `~/` aliases for package-local imports. Use `.js` ESM extensions where the runtime needs them. Use workspace package imports across boundaries.
- Strict `tsconfig.base.json` (`noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `verbatimModuleSyntax`).
- Biome OR ESLint+Prettier — pick one per repo and never mix.
- Conventional Commits enforced via commitlint + husky.

### Service / SDK boundary repo

- A code review blocks `Promise<Result<…>>`. The rule: boundaries return `ResultAsync`.
- Commit history repeatedly reinforces this conversion plus chain simplification (removing IIFE patterns, collapsing nested `andThen`s, dropping intermediate `await`s).
- Core packages centralize result helpers, schemas, and shared types.
- Security posture: validate at every external surface. Filter SSRF / network egress where the code makes outbound HTTP calls. Read secrets from env / config, never from source. Map DTOs between persistence and API.

### Knowledge / data-platform repo

- Co-locates `Result`/`ResultAsync`, `Maybe`, and `ts-pattern` as three distinct tools with documented separation:
  - `Result` for failable IO and parse paths.
  - Use `Maybe` for expected absence (cache miss, optional relation, no-match search, polling not-ready-yet). It is `Result<T, None>` with helpers (`fromNullable`, `match`, `compact`, `toResult`).
  - `ts-pattern` for exhaustive branches on owned tagged unions.
- `ResultAsync` chains span ingestion, storage, graph, and web layers — boundaries terminate the chain via small handler-local helpers.
- Biome is the formatter/linter — broader style adapts to Biome rather than forcing ESLint.

### MCP / tool-handler repo

- Tool boundaries use `neverthrow` (or onrails-shaped equivalent) with a repo-local `toToolResponseAsync()` (or similar) terminating `ResultAsync` pipelines at the handler.
- SDK helpers wrap OpenAPI client responses into `Result` / `ResultAsync`, never expose raw `Response`.
- `ts-pattern` exhaustively matches protocol / API payload discriminators.
- Handler bodies stay small; logic and validation live in `ResultAsync` chains.

### Older functional / reducer-heritage repo

- Looser historical edges: reducers, selectors, action creators, immutable transforms, ad-hoc composition, sometimes via `@re-reduced/react` (Alan's own reducer helper).
- Modern repos supersede this with stricter no-`any`, explicit boundary validation, and `ResultAsync` pipelines. Treat the older patterns as informative but not prescriptive — when in doubt, mirror the newer repos' shape.

## Refreshing signals

`scripts/derive-signals.sh` scans the `package.json` manifests of real repos (deps, devDeps, workspace members, Bun `workspaces.catalog`). It reports the actual tool use per category, and the unmapped packages that appear in several repos. It never edits this file or `preferred-tools.md`. Use its output as evidence: fold it in by hand when a documented default no longer matches what repos do. Run it with no arguments to scan `~/dev`, or give it repo paths.

## Backend vs frontend (cross-repo)

| Layer | Common tools |
| ----- | ------------ |
| Backend HTTP | `Bun.serve()`, Hono. No Express. Elysia only when already present. |
| Backend data | `bun:sqlite`, `Bun.sql`, `Bun.redis`, Drizzle |
| Frontend web | React 19, Vite, TanStack Router/Query/Start, shadcn + Tailwind |
| Frontend TUI | Ink + React, lightweight stores |
| Frontend styling | Tailwind + shadcn first; `@styled-cva/react` for typed variants |
| Lint | Biome OR ESLint+Prettier — match the target repo, never mix |
