---
name: alanstack-test
description: "Write tests in Alan's TypeScript/Bun style: bun:test for runtime, ts-expect (TypeEqual + expectType) for compile-time types, fast-check for laws and invariants, it.each / describe.each for closed enumerable branches, plain it for one-offs and regressions. No mocks for the lib's own functions. *.spec.ts under packages/<pkg>/test/. tsconfig.json must include test files. Use when user says 'write a test', 'add a spec', 'test this', '/alanstack-test', when adding behavior that needs coverage, when fixing a bug that needs a regression test, or asks how to test a Result/Maybe/match pipeline."
---

Write tests at the right layer. Pick the right tool: types, properties, table, or plain. No mocks for first-party code.

## Layers (which tool for which job)

| Layer | Tool | When |
|------|------|------|
| Compile-time types | `ts-expect` (`TypeEqual`, `expectType`) | Public type surface — inferred Ok/Err types, type predicates, alias equality, function-signature shape |
| Runtime laws / invariants | `bun:test` + `fast-check` | Algebraic laws (functor, monad), round-trips, idempotence, commutativity — any property that holds across a space of inputs |
| Runtime closed branches | `bun:test` + `it.each` / `describe.each` | Format/serialisation rules, status mapping, primitive dispatch, falsy-value handling — finite enumerable cases |
| Runtime one-offs | `bun:test` plain `it` | Integration cases that don't generalise, regression tests for a specific bug, scenarios with bespoke setup |

When in doubt: if the test reads "for all `x : X` it holds that ..." use `fast-check`; if it reads "for each of these N cases ..." use `it.each`; otherwise plain `it`.

## File layout

- `packages/<pkg>/test/<feature>.spec.ts` — runtime specs
- `packages/<pkg>/test/types.spec.ts` — compile-time type assertions (one per package)
- `packages/<pkg>/tsconfig.json` `include` **must** list `test/**/*.ts`. `bun test` transpiles without type-checking, so excluding tests from `tsc --noEmit` silently ships broken type assertions:

```jsonc
{
  "include": ["src/**/*.ts", "test/**/*.ts"]
}
```

- Spec naming conventions used across Alan's repos:
  - `*.spec.ts` — unit
  - `*.integration.test.ts` — integration
  - `*.smoke.test.ts` — smoke

Match the target package's existing naming. Do not introduce a new convention in a package that already has one.

## bun:test basics

```ts
import { describe, expect, it } from "bun:test";
import { ok, err, mapResult } from "../src/result.js";

describe("mapResult", () => {
  it("transforms Ok value", () => {
    expect(mapResult(ok(1), (n) => n + 1)).toEqual(ok(2));
  });

  it("passes through Err unchanged", () => {
    expect(mapResult(err("boom"), (n: number) => n + 1)).toEqual(err("boom"));
  });
});
```

No setup file, no `vitest.config`. `bun test` discovers `*.spec.ts` automatically. `bun test path/to/spec.ts` runs a single file.

## Compile-time type tests with `ts-expect`

`TypeEqual<X, Y>` asserts **exact equality**; use it on public type surface where the inferred type is the contract:

```ts
import { expectType, type TypeEqual } from "ts-expect";

const success = ok(1);
expectType<TypeEqual<typeof success, Result<number, never>>>(true);

const r = ok(1) as Result<number, string>;
if (isOk(r)) {
  expectType<TypeEqual<typeof r, Ok<number, string>>>(true);
  expectType<TypeEqual<typeof r.value, number>>(true);
}
```

Plain `expectType<T>(value)` asserts **assignability**; fall back to it when contextual inference or currying makes exact equality brittle:

```ts
const curried = map((n: number) => String(n))(ok(1));
expectType<Result<string, never>>(curried);
```

Negative type assertions: use `// @ts-expect-error` with a one-line comment naming the constraint.

```ts
// @ts-expect-error — `ok(1)` is Result<number, never>; concat with string is invalid
ok(1).value + "x";
```

## Property-based tests with `fast-check`

Build a per-package arbitrary for each domain type. Reuse across files in the same package:

```ts
import * as fc from "fast-check";

const arbResult: fc.Arbitrary<Result<number, string>> = fc.oneof(
  fc.integer().map((n) => ok<number, string>(n)),
  fc.string().map((s) => err<number, string>(s)),
);

it("functor identity: map(id)(r) === r", () => {
  fc.assert(
    fc.property(arbResult, (r) => {
      expect(map((x: number) => x)(r)).toEqual(r);
    }),
  );
});

it("monad associativity", () => {
  fc.assert(
    fc.property(arbResult, arbResultFn(), arbResultFn(), (m, f, g) => {
      expect(flatMap(g)(flatMap(f)(m))).toEqual(flatMap((x: number) => flatMap(g)(f(x)))(m));
    }),
  );
});
```

Properties to reach for:

- **Algebraic laws** — functor identity/composition, monad left/right identity + associativity, applicative laws.
- **Round-trips** — `fromNullable` → `match` → reconstruct; `parse` → `serialise` → `parse`; encode/decode pairs.
- **Idempotence** — `f(f(x)) === f(x)` for normalisers, reducers, sort.
- **Commutativity** — `combine([a, b])` vs `combine([b, a])` on the `Err` side.
- **Invariants** — output length, ordering, schema validity over arbitrary inputs.

When `fast-check` shrinks a counterexample, **keep the seed** in the test (`fc.assert(..., { seed: N })` only while reproducing; remove before merging).

Arbitraries that need `as any` to bridge `fast-check`'s loose `fc.func` types are OK in `*.spec.ts` — biome's `noExplicitAny` is off there.

## Table-style tests with `it.each` / `describe.each`

For closed enumerable cases — every row gets a `label` field, the test body is a single assertion:

```ts
const cases = [
  { label: "plain string error passes through",  input: "boom", expected: "boom" },
  { label: "object error serialised as JSON",    input: { code: "x" }, expected: /"code":"x"/ },
  { label: "number error stringified",           input: 42, expected: "42" },
] as const;

it.each(cases)("$label", ({ input, expected }) => {
  const detail = serialise(input);
  if (expected instanceof RegExp) expect(detail).toMatch(expected);
  else expect(detail).toBe(expected);
});
```

Rules:

- Use `$label` (or any `$<field>`) template in the test name. Bun expands it from the row.
- Keep the body **one assertion** if possible; branch only on the `kind`/`expected` shape, not the input.
- `as const` on the rows when the shape carries literal types you assert on.
- If two rows need different setup or different assertions, they don't belong in the same table — split.

## Plain `it` blocks

Reach for plain `it` when:

- The scenario is genuinely one-off (a specific bug repro).
- The test exists to document an exact regression (`it("regression #142: ...", ...)`).
- Setup is bespoke (file fixtures, multi-step state).
- Behavior crosses package boundaries and you're testing the seam.

## No mocks for first-party code

If the function under test is in this repo, **do not mock it**. Compose the real thing. The library has no IO to stub.

When a third-party function appears in the test:

- Pure → call it for real.
- IO with a deterministic alternative (`bun:sqlite` in-memory, `tmpdir`) → use the real client against the alternative.
- IO with no deterministic alternative (network, real DB, real LLM) → push it behind a thin adapter the test can pass a fake to, OR mark the test as integration / smoke and gate it.

`bun:test` has no built-in `jest.mock`. Use dependency injection (pass the dependency as an argument) over module-level patching. If a repo already uses `mock.module()`, match the convention but minimise scope.

## Coverage discipline

- Behavior changes need a test. Compat / shim changes extend the conformance spec for that surface (e.g. `packages/result/test/neverthrow-conformance.spec.ts`).
- Pure refactors don't need new tests if the existing suite covers the path. Add one **before** the refactor if no test does.
- A regression-test commit should reference the fix in the test name or a brief comment — future readers should be able to find the bug from the test.

## What `*.spec.ts` is allowed to do that `src/` isn't

- `any` — biome's `noExplicitAny` is `off` for spec files (needed to wire `fast-check` arbitraries cleanly).
- `_unsafeUnwrap` / `_unsafeUnwrapErr` in compat layers — allowed in tests, blocked everywhere else by `@onrails/eslint-plugin`.
- Inline `// @ts-expect-error` for negative type assertions — required to have a comment naming the constraint.
- Test-only helpers (`makeRow`, `fixture()`, builder functions) live alongside the spec or in `test/helpers/`. Don't ship test helpers from `src/`.

## When verifying after writing a test

Hand off to [alanstack-qa](../alanstack-qa/SKILL.md) for the run sequence: typecheck (so `types.spec.ts` actually checks), then `bun test <path>`. Don't claim "tests pass" without showing the count and any skipped/failed lines.

## Companion skills

- [alanstack](../alanstack/SKILL.md) — full principles, including the type/error model your tests assert on
- [alanstack-review](../alanstack-review/SKILL.md) — flags missing tests for behavior changes
- [alanstack-refactor](../alanstack-refactor/SKILL.md) — refactors that need a "before" test added first
- [alanstack-qa](../alanstack-qa/SKILL.md) — running the tests, not writing them
- [alanstack-commit](../alanstack-commit/SKILL.md) — `test(<scope>): …` per Conventional Commits
