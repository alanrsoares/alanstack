---
name: alanstack-refactor
description: "Apply Alan's canonical TypeScript refactors: Promise<Result> → ResultAsync, switch chains → ts-pattern, null checks → Maybe, throws → Result, untyped IO → Zod, inline object types → named types. Use for 'refactor this', 'tighten this', 'alanstack-ify', '/alanstack-refactor', or a review's recommended refactor move."
---

Apply Alan's canonical refactors. Make one move at a time. Show the diff. Run the repo's tests to verify that the behavior did not change.

## Operating loop

1. **Read first.** `AGENTS.md`, relevant `package.json` scripts, neighboring code. Repo conventions override these defaults.
2. **One refactor per change.** Don't mix a `ts-pattern` migration with a `Maybe` introduction in the same edit.
3. **Smallest coherent change.** If the move only touches one function, don't restructure the file.
4. **Verify.** Run lint + typecheck + the narrowest relevant test. Broaden when the refactor touches shared behavior.
5. **No drive-by edits.** A refactor doesn't need surrounding cleanup. Skip the formatting churn.

## Canonical moves

### Promise<Result<T, E>> → ResultAsync<T, E>

```diff
- async function fetchUser(id: string): Promise<Result<User, ApiError>> {
-   const res = await api.get(`/users/${id}`);
-   if (!res.ok) return err({ kind: "http", status: res.status });
-   return ok(await res.json());
- }
+ function fetchUser(id: string): ResultAsync<User, ApiError> {
+   return ResultAsync.fromPromise(api.get(`/users/${id}`), toApiError)
+     .andThen((res) =>
+       res.ok
+         ? ResultAsync.fromSafePromise(res.json())
+         : errAsync({ kind: "http" as const, status: res.status }),
+     );
+ }
```

Callers chain with `.andThen` / `.map` / `.mapErr`. No `await` until the boundary.

### switch / if-chain over owned union → ts-pattern .exhaustive()

```diff
- switch (event.type) {
-   case "message":   return renderMessage(event);
-   case "tool-call": return renderToolCall(event);
-   case "error":     return renderError(event);
-   default: throw new Error(`unhandled: ${event.type}`);
- }
+ return match(event)
+   .with({ type: "message" },   renderMessage)
+   .with({ type: "tool-call" }, renderToolCall)
+   .with({ type: "error" },     renderError)
+   .exhaustive();
```

Use `.otherwise()` only when the union is external/open and a fallback is intentional.

Do **not** apply this to two-branch `if` checks, simple booleans, or guard clauses.

### Repeated null checks → Maybe<T>

```diff
- const row = await db.query(...);
- if (row == null) return null;
- if (row.deleted) return null;
- return mapRow(row);
+ return Maybe.fromNullable(await db.query(...))
+   .andThen((row) => row.deleted ? Maybe.none() : Maybe.some(row))
+   .match({ some: mapRow, none: () => null });
```

Or, when absence becomes a failure at the next boundary:

```diff
- if (row == null) throw new NotFoundError(id);
+ return Maybe.toResult(Maybe.fromNullable(row), () => new NotFoundError(id));
```

### Throws in business logic → boundary-wrapped Result

Put throws **only** inside the wrapper that produces a Result. A hidden throw inside `service.ts` / `handler.ts` breaks the quality bar.

```diff
- export function parseConfig(raw: string): Config {
-   const data = JSON.parse(raw); // throws on bad input
-   if (!data.url) throw new Error("missing url");
-   return data as Config;
- }
+ export function parseConfig(raw: string): Result<Config, ConfigError> {
+   return trySync(() => JSON.parse(raw), () => ({ kind: "json" as const }))
+     .andThen((data) => {
+       const parsed = ConfigSchema.safeParse(data);
+       return parsed.success ? ok(parsed.data) : err({ kind: "schema" as const });
+     });
+ }
```

The schema types `parsed.data`. Do not cast.

### Untyped IO → Zod parse at the boundary

```diff
- app.post("/orders", async (req) => {
-   const body = await req.json();
-   return createOrder(body.userId, body.items);
- });
+ const CreateOrderBody = z.object({
+   userId: z.string().uuid(),
+   items:  z.array(z.object({ sku: z.string(), qty: z.number().int().positive() })).min(1),
+ });
+ app.post("/orders", async (req) => {
+   const parsed = CreateOrderBody.safeParse(await req.json());
+   if (!parsed.success) return badRequest(parsed.error);
+   return createOrder(parsed.data.userId, parsed.data.items);
+ });
```

Apply at every external surface: HTTP body, RPC payload, DB row → API mapping, file read, `process.env`, CLI arg.

### Inline anonymous object types → named type

```diff
- function fetch(input: { url: string; signal?: AbortSignal; retries?: number }) {
+ type FetchInput = { url: string; signal?: AbortSignal; retries?: number };
+ function fetch(input: FetchInput) {
```

Extract when the shape repeats or appears in a public signature. Inline objects in a single private call site are fine.

### IIFE / immediate curried call → named helper

```diff
- const handler = ((map) => (cmd: string) => map[cmd]?.() ?? unknown(cmd))({
-   ping: () => "pong",
-   flush: () => flushAll(),
- });
+ const commands: Record<string, () => string> = {
+   ping: () => "pong",
+   flush: () => flushAll(),
+ };
+ const handler = (cmd: string) => commands[cmd]?.() ?? unknown(cmd);
```

### Branching: switch chain → dispatch table

When every key is known and each branch is a function call:

```diff
- switch (cmd) {
-   case "ping":  return ping();
-   case "flush": return flush();
-   case "stop":  return stop();
- }
+ const handlers: Record<Command, () => ResultAsync<void, Error>> = {
+   ping, flush, stop,
+ };
+ return handlers[cmd]();
```

Use `ts-pattern` instead when matching on shape (not key) or when you want exhaustiveness over a tagged union.

## Boundaries — don't do these

- Don't convert `Maybe.none()` to throw; if absence is a failure, convert to `Result` first.
- Don't introduce `Maybe` for one isolated `??` fallback. Keep it as `??`.
- Don't introduce `ts-pattern` for `if (x == null)` or two-branch booleans.
- Keep a `class` that has methods. Do not replace it with a tagged union if the other domain classes in the repo are also classes.
- Don't `await` a `ResultAsync` only to re-wrap. Chain with `.andThen` until the outermost boundary.

## Scaling a move beyond hand-editing

If a canonical move recurs in more than a few files, do not edit each file by hand. Read [gritql-plugins.md](../alanstack/references/gritql-plugins.md). A GritQL Biome plugin keeps a rule enforced. A codemod rewrites the whole repo one time. The same verification bar applies to both.

## Verification

After each move:

```bash
bun run --filter <pkg> typecheck
bun run --filter <pkg> lint
bun test <path/to/spec>
```

If the refactor touches a shared module, broaden to `bun typecheck && bun lint && bun test` from the repo root.

For a pure refactor, prove that the behavior did not change: run the existing test suite. If no test covers the path, first add a `.spec.ts` for the before-state. Then refactor.

Principles: [alanstack](../alanstack/SKILL.md).
