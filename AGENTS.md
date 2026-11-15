# AGENTS.md

Conventions for writing and modifying skills in this repository.

## Skill structure

- Each skill lives in `skills/<name>/`.
- Directory contains `SKILL.md` and `agents/openai.yaml`.
- Subdirectories: `scripts/` for executables, `references/` for docs read only when needed.

## Frontmatter rules

- `name`: exact directory name in kebab-case.
- `description`: 40 to 1024 characters. Clear triggers. No `/alanstack-*` slash commands in description. Collapse synonyms.
- `disable-model-invocation: true` on user-invoked skills (`alanstack-pr`, `caveman-ponytail`). Omit on model-invoked skills.

## Content rules

- No top-level `#` title in `SKILL.md`. Start directly with introductory prose or `## ` sections.
- No `../` links to other skills. Call the Skill tool with `"<name>"` instead so packaged `.skill` archives do not break.
- Each rule has one location. Do not duplicate rules across skills; reference the owning skill.
- Each operational step ends on an explicit completion criterion.

## Change bar

A change to a skill must name an observed failure:
- What ran (input / prompt / command)
- What the skill did (unwanted behaviour)
- What was expected

"It would be better if" is not sufficient rationale for modifying a skill.

## Verification

Before pushing or opening a PR:
- Run `./scripts/package.sh /tmp/dist && rm -rf /tmp/dist`.
- Verify frontmatter, no top-level `#`, no `](../` links, and `agents/openai.yaml` existence.
