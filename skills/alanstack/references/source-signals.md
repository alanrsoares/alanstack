# Source Signals

The rules in this skill were inferred from several private TypeScript / Bun repos spanning desktop, terminal, web, MCP/SDK, and inference-sidecar surfaces. The repo names are intentionally not reproduced here. Instead, each cluster of rules is attributed to the *kind* of repo it came from.

## Repo categories

### Bun-workspace monorepo with `AGENTS.md` + strict TS

- Per-package scripts (`typecheck`, `lint`, `test`) with root fanout via `bun run --filter`.
- `AGENTS.md` carries Bun-first conventions: `Bun.file` / `Bun.$` / `bun:sqlite` over `node:`; `~/` aliases for package-local imports; `.js` ESM extensions where the runtime needs them; workspace package imports across boundaries.
- Strict `tsconfig.base.json` (`noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `verbatimModuleSyntax`).
- Biome OR ESLint+Prettier — pick one per repo and never mix.
- Conventional Commits enforced via commitlint + husky.

### Service / SDK boundary repo

- `Promise<Result<…>>` is treated as a code-review blocker; the rule is "boundaries return `ResultAsync`".
- Commit history repeatedly reinforces this conversion plus chain simplification (removing IIFE patterns, collapsing nested `andThen`s, dropping intermediate `await`s).
- Core packages centralize result helpers, schemas, and shared types.
- Security posture: explicit validation at every external surface, SSRF / network egress filtering where outbound HTTP is allowed, secrets read from env / config (never source), DTO mapping between persistence and API.

### Knowledge / data-platform repo

- Co-locates `Result`/`ResultAsync`, `Maybe`, and `ts-pattern` as three distinct tools with documented separation:
  - `Result` for failable IO and parse paths.
  - `Maybe` for expected absence (cache miss, optional relation, no-match search, polling not-ready-yet) implemented as `Result<T, None>` with helpers (`fromNullable`, `match`, `compact`, `toResult`).
  - `ts-pattern` for exhaustive branches on owned tagged unions.
- `ResultAsync` chains span ingestion, storage, graph, and web layers — boundaries terminate the chain via small handler-local helpers.
- Biome is the formatter/linter — broader style adapts to Biome rather than forcing ESLint.

### MCP / tool-handler repo

- Tool boundaries use `neverthrow` (or onrails-shaped equivalent) with a repo-local `toToolResponseAsync()` (or similar) terminating `ResultAsync` pipelines at the handler.
- SDK helpers wrap OpenAPI client responses into `Result` / `ResultAsync`, never expose raw `Response`.
- `ts-pattern` exhaustively matches protocol / API payload discriminators.
- Handler bodies stay small; logic and validation live in `ResultAsync` chains.

### Older functional / reducer-heritage repo

- Looser historical edges: reducers, selectors, action creators, immutable transforms, ad-hoc composition.
- Modern repos supersede this with stricter no-`any`, explicit boundary validation, and `ResultAsync` pipelines. Treat the older patterns as informative but not prescriptive — when in doubt, mirror the newer repos' shape.

## Backend vs frontend (cross-repo)

| Layer | Common tools |
| ----- | ------------ |
| Backend HTTP | `Bun.serve()`, Hono. No Express. Elysia only when already present. |
| Backend data | `bun:sqlite`, `Bun.sql`, `Bun.redis`, Drizzle |
| Frontend web | React 19, Vite, TanStack Router/Query/Start, shadcn + Tailwind |
| Frontend TUI | Ink + React, lightweight stores |
| Frontend styling | Tailwind + shadcn first; `@styled-cva/react` for typed variants |
| Lint | Biome OR ESLint+Prettier — match the target repo, never mix |
