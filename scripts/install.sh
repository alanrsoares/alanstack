#!/usr/bin/env bash
# Symlink every skill in `skills/<name>/` into the agent runtime dir.
# Live-edit safe: edits to ~/dev/alanstack/skills/<name>/SKILL.md show up immediately
# without re-running this script.
#
# Default DEST: ~/.agents/skills (the AGENTS spec's shared skill dir).
# Override with: scripts/install.sh /custom/dest
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
DEST="${1:-${HOME}/.agents/skills}"

[ -d "$SKILLS_DIR" ] || { echo "no skills/ dir at $ROOT" >&2; exit 2; }
mkdir -p "$DEST"

linked=0
for dir in "$SKILLS_DIR"/*/; do
  name="$(basename "$dir")"
  target="$DEST/$name"

  # If a previous install left a directory (not a symlink), back it up.
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup="$target.bak-$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
    echo "backup: $target -> $backup (was a non-symlink directory)"
  fi

  ln -sfn "$dir" "$target"
  echo "linked: $name  ->  $dir"
  linked=$((linked + 1))
done

echo "done: $linked skill(s) symlinked into $DEST"
