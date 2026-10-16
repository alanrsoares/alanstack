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
| [`caveman-ponytail`](skills/caveman-ponytail/SKILL.md) | Terse prose (Caveman) and the smallest complete code change (Ponytail). Standalone; no `alanstack-` prefix because other tooling refers to it by this name. |

## Install

Uses the [`skills`](https://skills.sh/) CLI, which finds every `skills/<name>/` in this repo and installs it for the agents on your machine.

```bash
npx skills add alanrsoares/alanstack        # or: bunx skills add alanrsoares/alanstack
```

| Want | Flag |
|------|------|
| User-level, not just this project | `-g` |
| Only some skills | `-s alanstack -s alanstack-commit` |
| Only some agents | `-a claude-code` |
| See what is in the repo first | `-l` |
| No prompts | `-y` |

Update with `npx skills update`, remove with `npx skills remove`.

### Ask your agent (copy/paste)

```text
Install the alanstack skills with the skills CLI.

1. Run `npx skills add alanrsoares/alanstack --list` (use `bunx` if npx is missing)
   and show me the skills it finds.
2. Install all of them at user level: `npx skills add alanrsoares/alanstack -g -y`.
3. Check with `npx skills list -g` that each one is installed.
4. Report which skills were installed for which agents, and anything that failed
   or was skipped. Do not edit my CLAUDE.md, AGENTS.md or settings.
```

### Work on the skills locally

```bash
git clone https://github.com/alanrsoares/alanstack.git ~/dev/alanstack
bash ~/dev/alanstack/scripts/install.sh
```

Symlinks each skill into `~/.agents/skills/`, so edits to a `SKILL.md` show up in your next agent session with no re-install. Pass another directory as the first argument. A real directory already there is moved to a `.bak-*` copy.

## Package (`.skill` archives)

```bash
bash scripts/package.sh
# -> dist/alanstack.skill, dist/alanstack-review.skill, dist/alanstack-refactor.skill,
#    dist/alanstack-qa.skill, dist/alanstack-commit.skill, dist/caveman-ponytail.skill
```

Each archive is independently installable in any agent that consumes `.skill` zips.

## Repo layout

```text
~/dev/alanstack/
├── README.md                                 ← this file
├── scripts/
│   ├── bootstrap.sh                          ← legacy curl-pipe installer; prefer `npx skills add`
│   ├── install.sh                            ← symlink installer (idempotent)
│   ├── package.sh                            ← per-skill .skill builder
│   └── derive-signals.sh                     ← reports real repo tool usage vs. preferred-tools.md
└── skills/
    ├── alanstack/                            ← parent
    │   ├── SKILL.md
    │   ├── references/
    │   │   ├── preferred-tools.md
    │   │   ├── source-signals.md
    │   │   └── gritql-plugins.md
    │   └── agents/
    │       └── openai.yaml
    ├── alanstack-review/SKILL.md
    ├── alanstack-refactor/SKILL.md
    ├── alanstack-test/SKILL.md
    ├── alanstack-qa/SKILL.md
    ├── alanstack-commit/SKILL.md
    └── caveman-ponytail/SKILL.md
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

`caveman-ponytail` merges ideas from [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) and [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), both MIT. Keep the source credit in that skill when you copy it.
