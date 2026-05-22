# alanstack

Multi-skill bundle that applies Alan's TypeScript / Bun style across writing, reviewing, refactoring, verifying, and committing code. Format follows the AGENTS skill spec (kebab-case dir + `SKILL.md` with `name` / `description` frontmatter) and works with any agent runtime that loads skills from `~/.agents/skills/`.

> [!IMPORTANT]
> **This is opinionated.** The rules here reflect one person's stack — Bun, Biome, neverthrow / [@onrails/result](https://github.com/alanrsoares/onrails), Zod, ts-pattern, Drizzle, TanStack, shadcn, Tailwind, `@styled-cva/react`, Vite, `bun:test` — and one person's quality bar (no `any`, no throws in business logic, no `Promise<Result<…>>`, no untyped IO, no AI attribution).
>
> If your stack or taste differs, **fork and adapt**. Each subskill is a self-contained markdown file you can edit, replace, or drop.

## Skills

| Skill | What it does |
|------|-------------|
| [`alanstack`](skills/alanstack/SKILL.md) | The parent — operating loop, quality bar, modern stack shorthand, type/error model, branching, boundaries, communication style. Read first. |
| [`alanstack-review`](skills/alanstack-review/SKILL.md) | Compressed code review against the quality bar — one line per finding. |
| [`alanstack-refactor`](skills/alanstack-refactor/SKILL.md) | Canonical refactor moves (Promise<Result> → ResultAsync, switch → ts-pattern, null → Maybe, throws → boundary Result, untyped IO → Zod). |
| [`alanstack-test`](skills/alanstack-test/SKILL.md) | Test-writing style — `bun:test` runtime, `ts-expect` types, `fast-check` properties, `it.each` tables. No mocks for first-party code. |
| [`alanstack-qa`](skills/alanstack-qa/SKILL.md) | Verify a change with the repo's own scripts — lint + typecheck + scoped tests. |
| [`alanstack-commit`](skills/alanstack-commit/SKILL.md) | Conventional Commits with required scope, ≤50 char subject, no AI attribution. |

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/alanrsoares/alanstack/main/scripts/bootstrap.sh | bash
```

Clones the repo into `~/.alanstack/` and symlinks each `skills/<name>/` into `~/.agents/skills/`. Idempotent — re-running pulls latest `main` and refreshes the symlinks. Override paths with `ALANSTACK_HOME=...` and `ALANSTACK_DEST=...`.

### Manual

```bash
git clone https://github.com/alanrsoares/alanstack.git ~/dev/alanstack
bash ~/dev/alanstack/scripts/install.sh
```

> [!TIP]
> Edits to any `SKILL.md` show up in your next agent session immediately — no re-install needed. Pass a custom skill dir as the first arg: `scripts/install.sh /custom/dest`.

## Package (`.skill` archives)

```bash
bash scripts/package.sh
# -> dist/alanstack.skill, dist/alanstack-review.skill, dist/alanstack-refactor.skill,
#    dist/alanstack-qa.skill, dist/alanstack-commit.skill
```

Each archive is independently installable in any agent that consumes `.skill` zips.

## Repo layout

```text
~/dev/alanstack/
├── README.md                                 ← this file
├── scripts/
│   ├── bootstrap.sh                          ← curl-pipe one-line installer
│   ├── install.sh                            ← symlink installer (idempotent)
│   └── package.sh                            ← per-skill .skill builder
└── skills/
    ├── alanstack/                            ← parent
    │   ├── SKILL.md
    │   ├── references/
    │   │   ├── preferred-tools.md
    │   │   └── source-signals.md
    │   └── agents/
    │       └── openai.yaml
    ├── alanstack-review/SKILL.md
    ├── alanstack-refactor/SKILL.md
    ├── alanstack-test/SKILL.md
    ├── alanstack-qa/SKILL.md
    └── alanstack-commit/SKILL.md
```

Each skill is self-contained under `skills/<name>/`. The parent owns the shared `references/` (alternatives + source signals) — subskills link to those files via `../alanstack/references/…`.

## Conventions (per skill)

- Dir name (`skills/<name>/`) == frontmatter `name` field
- Frontmatter contains only `name:` and `description:`
- Description starts with one-line summary, then "Use when …" triggers
- Kebab-case; sibling skills carry the `alanstack-` prefix
- Plain markdown body, no top-level `# Title` (the frontmatter is the title)

## License

[Unlicense](./UNLICENSE) — public domain. Copy, fork, modify, redistribute without attribution.

Inspired by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)'s multi-skill repo layout.
