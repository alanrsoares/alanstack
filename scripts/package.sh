#!/usr/bin/env bash
# Package every skill in `skills/<name>/` as a separate `.skill` archive in `dist/`.
# Validates each SKILL.md frontmatter (name + description, kebab-case, name == dirname).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
OUT_DIR="${1:-$ROOT/dist}"

[ -d "$SKILLS_DIR" ] || { echo "no skills/ dir at $ROOT" >&2; exit 2; }

mkdir -p "$OUT_DIR"

fail() { echo "validation: $1" >&2; exit 1; }

validate_skill() {
  local dir="$1"
  local name="$(basename "$dir")"
  local skill_md="$dir/SKILL.md"

  [ -f "$skill_md" ] || fail "$name: SKILL.md missing"

  # Extract YAML frontmatter (between first two --- markers).
  local frontmatter
  frontmatter="$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; next} n==1{print} n>=2{exit}' "$skill_md")"
  [ -n "$frontmatter" ] || fail "$name: SKILL.md missing YAML frontmatter"

  local fm_name fm_desc
  fm_name="$(printf '%s\n' "$frontmatter" | awk -F': *' '/^name:/{print $2; exit}')"
  fm_desc="$(printf '%s\n' "$frontmatter" | awk '/^description:/{sub(/^description:[ \t]*/,""); print; exit}')"

  [ -n "$fm_name" ] || fail "$name: frontmatter missing name"
  [ -n "$fm_desc" ] || fail "$name: frontmatter missing description"
  [[ "$fm_name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "$name: name '$fm_name' not kebab-case"
  [ "$fm_name" = "$name" ] || fail "$name: frontmatter name '$fm_name' != directory '$name'"

  local desc_len=${#fm_desc}
  [ "$desc_len" -ge 40 ] || fail "$name: description too short ($desc_len chars; aim >=40)"
  [ "$desc_len" -le 1024 ] || fail "$name: description too long ($desc_len chars; max 1024)"

  for forbidden in CHANGELOG.md INSTALLATION_GUIDE.md QUICK_REFERENCE.md; do
    [ ! -f "$dir/$forbidden" ] || fail "$name: $forbidden present; remove before packaging"
  done

  echo "validate: ok ($fm_name)"
}

package_skill() {
  local dir="$1"
  local name="$(basename "$dir")"
  local zip_out="$OUT_DIR/$name.skill"

  rm -f "$zip_out"
  (
    cd "$SKILLS_DIR"
    zip -rq "$zip_out" "$name" -x "$name/.git/*" -x "$name/.DS_Store"
  )
  echo "package: $zip_out"
}

for dir in "$SKILLS_DIR"/*/; do
  validate_skill "$dir"
done

for dir in "$SKILLS_DIR"/*/; do
  package_skill "$dir"
done

echo "done: $(ls "$OUT_DIR"/*.skill 2>/dev/null | wc -l | tr -d ' ') skill(s) in $OUT_DIR"
