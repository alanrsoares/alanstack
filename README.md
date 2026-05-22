# alanstack

Multi-skill bundle that applies Alan's TypeScript / Bun style across writing, reviewing, refactoring, verifying, and committing code. Format follows the AGENTS skill spec (kebab-case dir + `SKILL.md` with `name` / `description` frontmatter) and works with any agent runtime that loads skills from `~/.agents/skills/`.

## Skills

| Skill | What it does |
|------|-------------|
| [`alanstack`](skills/alanstack/SKILL.md) | The parent — operating loop, quality bar, modern stack shorthand, type/error model, branching, boundaries, communication style. Read first. |
| [`alanstack-review`](skills/alanstack-review/SKILL.md) | Compressed code review against the quality bar — one line per finding. |
| [`alanstack-refactor`](skills/alanstack-refactor/SKILL.md) | Canonical refactor moves (Promise<Result> → ResultAsync, switch → ts-pattern, null → Maybe, throws → boundary Result, untyped IO → Zod). |
| [`alanstack-qa`](skills/alanstack-qa/SKILL.md) | Verify a change with the repo's own scripts — lint + typecheck + scoped tests. |
| [`alanstack-commit`](skills/alanstack-commit/SKILL.md) | Conventional Commits with required scope, ≤50 char subject, no AI attribution. |

## Install (live symlinks)

```bash
git clone https://github.com/alanrsoares/alanstack.git ~/dev/alanstack
bash ~/dev/alanstack/scripts/install.sh
```

This symlinks each `skills/<name>/` into `~/.agents/skills/<name>/`. Edits to any SKILL.md show up in your next agent session immediately — no re-install.

Override the destination with `scripts/install.sh /custom/dest` if your agent reads skills from somewhere else.

## Package (`.skill` archives)

```bash
bash scripts/package.sh
# -> dist/alanstack.skill, dist/alanstack-review.skill, dist/alanstack-refactor.skill,
#    dist/alanstack-qa.skill, dist/alanstack-commit.skill
```

Each archive is independently installable in any agent that consumes `.skill` zips.

## Repo layout

```
~/dev/alanstack/
├── README.md                                 ← this file
├── scripts/
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

The skill content reflects Alan's personal style — use freely as a starting point for your own conventions.

Inspired by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)'s multi-skill repo layout.
