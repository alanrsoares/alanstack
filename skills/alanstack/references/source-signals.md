# Source Signals

This skill was inferred from Yappr, SafeURL, RecallOS, Printr MCP, and re-reduced.

## Yappr

- Bun workspace monorepo with strict TypeScript, ESLint/Prettier, per-package scripts, and root fanout for lint/typecheck/test.
- `AGENTS.md` emphasizes Bun APIs, `~/` aliases, `.js` ESM extensions for intra-package imports, workspace package imports, store + thin screen UI, semantic TUI colors, and Conventional Commits.
- `neverthrow` is used for SDK/service boundaries and persistence-facing helpers.
- `ts-pattern` is useful for chat events, UI finite states, microphone state, and health/status unions.

## SafeURL

- Strong signal for strict monorepo checks and service-boundary `ResultAsync`.
- Commit history repeatedly reinforces converting `Promise<Result<...>>` to `ResultAsync`, simplifying chains, and removing IIFE patterns.
- Core packages centralize result helpers, schemas, and shared types.
- Security posture favors explicit validation, SSRF protection, secrets discipline, and DTO boundaries.

## RecallOS

- `docs/RAILWAY_PATTERNS.md` explicitly separates `Result`/`ResultAsync`, `Maybe`, and `ts-pattern`.
- `Maybe<T>` is implemented as `Result<T, None>` and used for expected absence: optional graph extraction service, missing tool call output, optional relations, cache/search misses.
- ResultAsync chains are common across ingestion, storage, graph, and web packages.
- Biome is the formatter/linter; the broader style should adapt to that rather than force ESLint.

## Printr MCP

- Business/tool boundaries use `neverthrow`; `toToolResponseAsync()` terminates `ResultAsync` pipelines at MCP handlers.
- SDK helpers wrap OpenAPI client responses into `Result`/`ResultAsync`.
- `ts-pattern` is used for exhaustive matching on protocol/API payload discriminators.
- Tool response helpers keep handler bodies small and boundary-specific.

## re-reduced

- Older code shows the functional/reducer heritage: reducers, selectors, action creators, immutable transforms, and composition.
- Modern repos supersede its looser historical edges with stricter no-`any`, explicit boundary validation, and `ResultAsync` pipelines.

## Backend vs frontend (cross-repo)

| Layer | Common tools | Repo notes |
| ----- | ------------ | ---------- |
| Backend HTTP | `Bun.serve()`, Hono | RecallOS: no Express; Yappr/Printr MCP: Hono |
| Backend data | Drizzle, `bun:sqlite`, `Bun.sql`, `Bun.redis` | Yappr: SQLite; RecallOS: Postgres; SafeURL: Drizzle packages |
| Frontend web | React 19, Vite, TanStack Router/Query/Start | RecallOS dashboard, Yappr desktop mainview, Printr web |
| Frontend TUI | Ink + React, unstated stores | Yappr CLI |
| Frontend styling | Tailwind, shadcn | Yappr desktop, SafeURL dashboard |
| Lint | ESLint+Prettier or Biome | Yappr/SafeURL/Printr web: ESLint; RecallOS/Printr MCP: Biome |
