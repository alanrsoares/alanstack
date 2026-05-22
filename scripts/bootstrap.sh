#!/usr/bin/env bash
# One-line installer for the alanstack skill bundle.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/alanrsoares/alanstack/main/scripts/bootstrap.sh | bash
#
# Override the clone destination:
#   ALANSTACK_HOME=/custom/path curl -fsSL ... | bash
#
# Override the runtime skill dir (where install.sh symlinks into):
#   ALANSTACK_DEST=/custom/skills curl -fsSL ... | bash
#
# Idempotent: re-running pulls latest main and re-symlinks.
set -euo pipefail

REPO_URL="${ALANSTACK_REPO_URL:-https://github.com/alanrsoares/alanstack.git}"
HOME_DIR="${ALANSTACK_HOME:-${HOME}/.alanstack}"
DEST_DIR="${ALANSTACK_DEST:-${HOME}/.agents/skills}"

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "bootstrap: missing required tool '$1'" >&2; exit 1; }
}

need git
need bash

if [ -d "$HOME_DIR/.git" ]; then
  echo "bootstrap: updating $HOME_DIR"
  git -C "$HOME_DIR" fetch --quiet origin
  git -C "$HOME_DIR" reset --quiet --hard origin/main
else
  echo "bootstrap: cloning $REPO_URL into $HOME_DIR"
  mkdir -p "$(dirname "$HOME_DIR")"
  git clone --quiet "$REPO_URL" "$HOME_DIR"
fi

echo "bootstrap: installing skills into $DEST_DIR"
bash "$HOME_DIR/scripts/install.sh" "$DEST_DIR"

cat <<EOF

alanstack installed.

  repo:   $HOME_DIR
  skills: $DEST_DIR

To update later, re-run the same one-liner or:
  cd $HOME_DIR && git pull && bash scripts/install.sh

To uninstall:
  rm -rf $HOME_DIR
  for d in $DEST_DIR/alanstack $DEST_DIR/alanstack-*; do
    [ -L "\$d" ] && rm "\$d"
  done
EOF
