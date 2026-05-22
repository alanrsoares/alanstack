# Preferred Tools

Quick-reference for the libraries Alan reaches for by purpose. Inferred from a sample of modern TypeScript / Bun projects. Legacy / experimental repos are excluded from the synthesis.

**Always defer to the target repo's `AGENTS.md`, `package.json`, and neighboring code.** This file is for greenfield decisions and conflict resolution.

## Format

Each section lists:

- **Default** — what to use without thinking.
- **Acceptable** — used in specific repos for a reason; keep if already there.
- **Avoid** — not present in modern repos; do not add.

## Runtime And Package Manager

- **Default**: Bun (`bun`, `bun run`, `bun test`, `bunx`).
- **Acceptable**: pnpm in monorepos that already use it.
- **Avoid**: npm, yarn (except legacy lockfiles you cannot remove).

## HTTP Server

- **Default**: `Bun.serve()` for plain HTTP/services; **Hono** when routing/middleware grows.
- **Acceptable**: **Elysia** where the repo already uses it.
- **Avoid**: Express, Koa, Fastify (Fastify only appears in Svelte projects).

## Validation

- **Default**: **Zod** at every IO boundary (HTTP, RPC, config, CLI args, persisted JSON, tool output).
- **Pair with**: `drizzle-zod` when both Drizzle and Zod are in the repo.
- **Avoid**: valibot, yup, ajv, typebox.

## Error / Result Model

- **Default**: **`neverthrow`** (`Result` / `ResultAsync`) at service, IO, business, API, DB, and tool-handler boundaries. Migrating to **`@onrails/result`** (Alan's tagged-union alternative) where applicable.
- **Lint**: `eslint-plugin-neverthrow` when ESLint is in use and enforcement is wanted; `@onrails/eslint-plugin` for the onrails-shaped variant.
- **Maybe**: `Maybe<T> = Result<T, None>` for expected absence — copy that shape only when the repo already has it.
- **Avoid**: fp-ts, effect, purify-ts, true-myth. Do not introduce a second result library alongside neverthrow/onrails.

## Pattern Matching

- **Default**: **`ts-pattern`** with `.exhaustive()` for owned tagged unions (job status, event type, message role, protocol discriminator).
- **Avoid**: ad-hoc `switch` chains over owned unions; `match-iz` or other alternatives.

## Database / ORM

- **Default**: **Drizzle** (`drizzle-orm` + `drizzle-kit`, optionally `drizzle-zod`).
- **Engine**: `bun:sqlite` for local/embedded; Postgres (`postgres` driver or `@neondatabase/serverless`) for hosted; `@libsql/client` only when Mastra/Turso is involved.
- **Avoid**: Prisma, Kysely, Knex, Mongoose, raw `pg` (use `Bun.sql` or driver-of-record), `mysql2`.

## Cache / KV

- **Default**: none baked in across repos. When needed, prefer `Bun.redis` on Bun, otherwise the platform-native client (Cloudflare KV, Upstash) of the host.
- **Avoid**: `ioredis` — no modern repo uses it.

## Logging

- **Default**: **`pino` + `pino-pretty`** for service code.
- **Acceptable**: `console.*` for CLIs, scripts, and small Bun.serve handlers.
- **Avoid**: winston, bunyan, consola, debug, signale. Do not introduce a new logging library — promote `pino` if structured logging is needed.

## Frontend Framework

- **Default**: **React 19** for web and webviews; **Ink + React** for terminal UIs.
- **Acceptable**: Svelte / SvelteKit, Lit, Lynx — only as intentional experiments. Do not propose them for a new general-purpose project.
- **Avoid**: Vue, Solid, Preact in app code.

## Router

- **Default for new SPAs / Vite apps**: **TanStack Router**.
- **Default for SSR full-stack on Cloudflare**: **TanStack Start**.
- **Acceptable**: **React Router v7** when the repo already uses it; **Next.js** App Router for content-first sites.
- **Avoid**: Wouter, Reach Router, `react-router` v6 in new code.

## Server State / Data Fetching

- **Default**: **TanStack Query** (`@tanstack/react-query`).
- **Acceptable**: Vercel AI SDK (`ai` + `@ai-sdk/react`) for chat/streaming UIs.
- **Avoid**: SWR, Apollo, urql, RTK Query, raw fetch in components.

## Client State

- **Default for new web apps**: **`@tanstack/react-store`**.
- **Acceptable**: **`zustand`** in repos that already use it; **`unstated-next`** for small per-screen stores (older repos).
- **Avoid**: Redux, MobX, Jotai, Valtio.

## HTTP Client

- **Default**: native `fetch` (Bun + Workers + browser).
- **Acceptable**: **`ky`** when a thin wrapper is wanted.
- **Avoid**: `axios`, `got` in new code (`got` lingers in a few CLI repos).

## Build Tool

- **Default**: **Vite** for SPA/library frontends; **Bun** for libraries/CLIs that ship via `bun build` or `tsup`.
- **Acceptable**: **`tsup`** for publishable TS libraries.
- **Default for SSR**: **TanStack Start** / **Next.js** as listed under Router.
- **Avoid**: Webpack, Rollup (direct), Parcel.

## Styling

- **Default**: **Tailwind CSS**.
- **Component variants**: **`@styled-cva/react`** (Alan's own wrapper) for typed variant-driven components. Fall back to **`class-variance-authority` + `clsx` + `tailwind-merge`** (the `cn` pattern) when `@styled-cva/react` is not present.
- **Animations**: `tw-animate-css` in new shadcn projects; `tailwindcss-animate` in older ones (do not mix in the same repo).
- **Acceptable**: `daisyui` for quick prototypes; `@pandacss/dev` only where it already lives.
- **Avoid**: `styled-components`, `@emotion/*`, `vanilla-extract`, `unocss`.

## UI Component Library

- **Default**: **shadcn/ui** (`components.json` + `@radix-ui/*` primitives + `lucide-react` icons + `sonner` toasts + `vaul` drawer + `cmdk` command palette + `next-themes`).
- **Acceptable**: **`@base-ui/react`** primitives where the project moved to Base UI.
- **Avoid**: MUI, Chakra, Ant Design, Mantine, NextUI.

## Forms

- **Default for new code**: **`@tanstack/react-form`**.
- **Acceptable**: **`react-hook-form` + `@hookform/resolvers/zod`** in older repos — keep if already there.
- **Avoid**: Formik.

## Testing

- **Default for Bun packages**: **`bun:test`** (no dep needed; `@types/bun` provides types).
- **Default for non-Bun frontends**: **`vitest`** (+ `@testing-library/react`, `happy-dom`).
- **Property-based**: **`fast-check`** for algebraic laws, invariants, and round-trip properties.
- **Compile-time type tests**: **`ts-expect`** (`expectType` / `TypeEqual`).
- **End-to-end**: **Playwright** when the repo already has it.
- **Avoid**: Jest (except Expo's `jest-expo`), Mocha, Cypress.

## Lint / Format

- **Default for new repos (TS-only, Biome compatible)**: **Biome** (`@biomejs/biome`).
- **Default for repos with heavy plugin needs / monorepos with shared config**: **ESLint** + **Prettier** + `@ianvs/prettier-plugin-sort-imports` + `prettier-plugin-tailwindcss`.
- **Do not switch** an ESLint repo to Biome or vice versa unless the task is explicitly that migration.
- **Acceptable extras**: `knip` for dead-code detection; `husky` + `lint-staged` for pre-commit.

## TypeScript Config

- **Default base**: `@tsconfig/strictest` in libraries and shared packages.
- **Rule**: strict TypeScript, no casual `any`, no unused symbols, no one-off rule disables without a documented local reason.

## Desktop / Mobile Shell

- **Desktop default**: **Electrobun** + typed RPC to a Bun-side data/service layer.
- **Acceptable**: **Tauri** only for non-Bun host integrations.
- **Mobile**: **Expo / React Native** only when targeting mobile is the stated goal.
- **Avoid**: Electron.

## AI SDKs

- **Agent framework**: **Mastra** (`@mastra/*`) when building agentic systems.
- **Chat / streaming UIs**: **Vercel AI SDK** (`ai`, `@ai-sdk/react`).
- **Local inference**: **`ollama`** + the appropriate `ollama-ai-provider-v2` adapter.
- **Model routing**: **`@openrouter/sdk`**; **`workers-ai-provider`** on Cloudflare.
- **Avoid**: direct `openai` / `@anthropic-ai/sdk` calls in app code — route through Vercel AI SDK or Mastra. `langchain` is not in use.

## MCP

- **Default**: **`@modelcontextprotocol/sdk`** for servers and clients.
- **Acceptable**: **`@mastra/mcp`** when already inside a Mastra agent.
- **Pattern**: terminate `ResultAsync` pipelines at the MCP handler with a repo-local `toToolResponseAsync()` helper.

## Codegen And SDKs

- **OpenAPI → TS types**: **`openapi-typescript`**.
- **OpenAPI → client**: **`@hey-api/openapi-ts`**.
- **Rule**: regenerate via the repo's existing scripts; keep generated SDK packages as thin wrappers around generated types.

## Utility Belt

- **Dates**: **`date-fns`** (everywhere a date appears).
- **Functional helpers**: **`rambda`** when a tiny FP utility helps; prefer native + small named helpers first. Do not introduce `ramda` (legacy).
- **Shell scripting**: **`zx`** (Bun-compatible) for ad-hoc scripts; **`Bun.$`** for Bun-only.
- **CLI prompts/parsing**: **`commander` + `inquirer`** for CLI tools.
- **HTML scraping**: **`cheerio`** when scraping is genuinely needed.
- **GitHub API**: **`@octokit/rest`**.
- **Animation**: **`framer-motion` / `motion`** when motion is actually required; do not add for static UIs.
- **Web3**: **`@solana/web3.js` + wallet-adapter + anchor** for Solana; **`viem` + `wagmi`** for EVM.

## Hosting / Platform

- **Default for full-stack**: **Cloudflare Workers** (Wrangler) with **TanStack Start** or **Hono**.
- **Acceptable**: **Vercel** for Next.js content sites; self-hosted Bun for services and MCP servers.

## Strong Defaults (Cross-Cutting)

The recurring "modern Alan stack" fingerprint:

```
Bun + Biome + neverthrow + Zod + ts-pattern + Drizzle + TanStack (Router/Query/Form/Store) + shadcn + Tailwind + @styled-cva/react + Vite + bun:test
```

When in doubt and there is no `AGENTS.md` to defer to, this is the stack to assemble.

## Categories With No Standard Default

These have no recurring choice across the sampled repos — make a deliberate decision and document it in the target repo's `AGENTS.md`:

- Cache / KV beyond `Bun.redis`
- Background job queue
- Email transport
- Object storage SDKs
- Telemetry / tracing (OTEL)
- Feature flags
