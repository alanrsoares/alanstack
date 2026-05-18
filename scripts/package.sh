#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$(basename "$ROOT")"
OUT="${1:-$ROOT}"
SKILL_MD="$ROOT/SKILL.md"

fail() { echo "validation: $1" >&2; exit 1; }

[ -f "$SKILL_MD" ] || fail "SKILL.md missing"

# Extract YAML frontmatter (between first two --- markers).
FRONTMATTER="$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; next} n==1{print} n>=2{exit}' "$SKILL_MD")"
[ -n "$FRONTMATTER" ] || fail "SKILL.md missing YAML frontmatter"

FM_NAME="$(printf '%s\n' "$FRONTMATTER" | awk -F': *' '/^name:/{print $2; exit}')"
FM_DESC="$(printf '%s\n' "$FRONTMATTER" | awk -F': *' '/^description:/{sub(/^description: */,""); print; exit}')"

[ -n "$FM_NAME" ] || fail "frontmatter missing name"
[ -n "$FM_DESC" ] || fail "frontmatter missing description"
[[ "$FM_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "name '$FM_NAME' not kebab-case"
[ "$FM_NAME" = "$NAME" ] || fail "name '$FM_NAME' != directory '$NAME'"

DESC_LEN=${#FM_DESC}
[ "$DESC_LEN" -ge 40 ] || fail "description too short ($DESC_LEN chars; aim >=40)"
[ "$DESC_LEN" -le 1024 ] || fail "description too long ($DESC_LEN chars; max 1024)"

# Reject extraneous top-level docs.
for forbidden in README.md CHANGELOG.md INSTALLATION_GUIDE.md QUICK_REFERENCE.md; do
  [ ! -f "$ROOT/$forbidden" ] || fail "$forbidden present; remove before packaging"
done

echo "validation: ok ($FM_NAME)"

mkdir -p "$OUT"
ZIP="$OUT/$NAME.skill"
rm -f "$ZIP"
(
  cd "$(dirname "$ROOT")"
  zip -rq "$ZIP" \
    "$NAME/SKILL.md" \
    "$NAME/references/" \
    "$NAME/agents/" \
    "$NAME/scripts/package.sh"
)

echo "Packaged: $ZIP"
