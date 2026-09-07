#!/usr/bin/env bash
# Scan real repos' package.json manifests and report actual dependency usage
# against the categories declared in skills/alanstack/references/preferred-tools.md.
#
# This never edits preferred-tools.md — it prints an evidence report for a
# human to read and fold in by hand. Categorized packages get a repo-count
# per category; packages that aren't in the category map but show up in
# several repos are surfaced separately as candidate new signals.
#
# Usage:
#   scripts/derive-signals.sh                 # scan $ALANSTACK_SCAN_DIR (default: ~/dev)
#   scripts/derive-signals.sh ~/dev/foo ~/dev/bar   # scan explicit repo paths
#
# Requires: jq
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "derive-signals: missing required tool '$1'" >&2; exit 1; } }
need jq

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCAN_DIR="${ALANSTACK_SCAN_DIR:-${HOME}/dev}"
MIN_UNMAPPED_HITS="${ALANSTACK_MIN_HITS:-2}"

# pkg -> "Category|Label" — mirrors skills/alanstack/references/preferred-tools.md headings.
declare -A MAP=(
  [hono]="HTTP Server|Hono" [elysia]="HTTP Server|Elysia" [express]="HTTP Server|Express"
  [koa]="HTTP Server|Koa" [fastify]="HTTP Server|Fastify"

  [zod]="Validation|Zod" [valibot]="Validation|valibot" [yup]="Validation|yup"
  [ajv]="Validation|ajv" [typebox]="Validation|typebox" [drizzle-zod]="Validation|drizzle-zod"

  [neverthrow]="Error / Result Model|neverthrow" ["@onrails/result"]="Error / Result Model|@onrails/result"
  ["fp-ts"]="Error / Result Model|fp-ts" [effect]="Error / Result Model|effect"
  ["purify-ts"]="Error / Result Model|purify-ts" ["true-myth"]="Error / Result Model|true-myth"
  ["eslint-plugin-neverthrow"]="Error / Result Model|eslint-plugin-neverthrow"
  ["@onrails/eslint-plugin"]="Error / Result Model|@onrails/eslint-plugin"
  ["@onrails/maybe"]="Error / Result Model|@onrails/maybe"

  ["ts-pattern"]="Pattern Matching|ts-pattern" ["@onrails/pattern"]="Pattern Matching|@onrails/pattern"
  ["match-iz"]="Pattern Matching|match-iz"

  ["drizzle-orm"]="Database / ORM|Drizzle" ["drizzle-kit"]="Database / ORM|Drizzle"
  ["prisma"]="Database / ORM|Prisma" ["@prisma/client"]="Database / ORM|Prisma"
  [kysely]="Database / ORM|Kysely" [knex]="Database / ORM|Knex" [mongoose]="Database / ORM|Mongoose"
  [pg]="Database / ORM|pg (raw)" [mysql2]="Database / ORM|mysql2" [postgres]="Database / ORM|postgres driver"
  ["@libsql/client"]="Database / ORM|@libsql/client" ["@neondatabase/serverless"]="Database / ORM|Neon serverless"

  [ioredis]="Cache / KV|ioredis"

  [pino]="Logging|pino" ["pino-pretty"]="Logging|pino-pretty" [winston]="Logging|winston"
  [bunyan]="Logging|bunyan" [consola]="Logging|consola" [debug]="Logging|debug" [signale]="Logging|signale"

  [react]="Frontend Framework|React" [svelte]="Frontend Framework|Svelte" [lit]="Frontend Framework|Lit"
  [vue]="Frontend Framework|Vue" ["solid-js"]="Frontend Framework|Solid" [preact]="Frontend Framework|Preact"

  ["@tanstack/react-router"]="Router|TanStack Router" ["@tanstack/react-start"]="Router|TanStack Start"
  ["react-router"]="Router|React Router" ["react-router-dom"]="Router|React Router" [next]="Router|Next.js"

  ["@tanstack/react-query"]="Server State|TanStack Query" [swr]="Server State|SWR"
  ["@apollo/client"]="Server State|Apollo" [urql]="Server State|urql" ["@reduxjs/toolkit"]="Server State|RTK Query"

  ["@tanstack/react-store"]="Client State|@tanstack/react-store" [zustand]="Client State|zustand"
  ["unstated-next"]="Client State|unstated-next" [redux]="Client State|Redux" [mobx]="Client State|MobX"
  [jotai]="Client State|Jotai" [valtio]="Client State|Valtio"

  [ky]="HTTP Client|ky" [axios]="HTTP Client|axios" [got]="HTTP Client|got"

  [vite]="Build Tool|Vite" [tsup]="Build Tool|tsup" [webpack]="Build Tool|Webpack"
  [rollup]="Build Tool|Rollup" [parcel]="Build Tool|Parcel"

  [tailwindcss]="Styling|Tailwind CSS" ["@styled-cva/react"]="Styling|@styled-cva/react"
  ["class-variance-authority"]="Styling|class-variance-authority" [clsx]="Styling|clsx"
  ["tailwind-merge"]="Styling|tailwind-merge" ["tw-animate-css"]="Styling|tw-animate-css"
  ["tailwindcss-animate"]="Styling|tailwindcss-animate" [daisyui]="Styling|daisyui"
  ["@pandacss/dev"]="Styling|Panda CSS" ["styled-components"]="Styling|styled-components"
  ["@emotion/react"]="Styling|Emotion" ["@vanilla-extract/css"]="Styling|vanilla-extract" [unocss]="Styling|UnoCSS"

  ["lucide-react"]="UI Component Library|lucide-react" [sonner]="UI Component Library|sonner"
  [vaul]="UI Component Library|vaul" [cmdk]="UI Component Library|cmdk" ["next-themes"]="UI Component Library|next-themes"
  ["@base-ui/react"]="UI Component Library|Base UI" ["@mui/material"]="UI Component Library|MUI"
  ["@chakra-ui/react"]="UI Component Library|Chakra" [antd]="UI Component Library|Ant Design"
  ["@mantine/core"]="UI Component Library|Mantine"

  ["@tanstack/react-form"]="Forms|@tanstack/react-form" ["react-hook-form"]="Forms|react-hook-form"
  ["@hookform/resolvers"]="Forms|@hookform/resolvers" [formik]="Forms|Formik"

  [vitest]="Testing|vitest" ["@testing-library/react"]="Testing|@testing-library/react"
  ["happy-dom"]="Testing|happy-dom" ["fast-check"]="Testing|fast-check" ["ts-expect"]="Testing|ts-expect"
  ["@playwright/test"]="Testing|Playwright" [jest]="Testing|Jest" [mocha]="Testing|Mocha" [cypress]="Testing|Cypress"

  ["@biomejs/biome"]="Lint / Format|Biome" [eslint]="Lint / Format|ESLint" [prettier]="Lint / Format|Prettier"
  ["@ianvs/prettier-plugin-sort-imports"]="Lint / Format|prettier-plugin-sort-imports"
  ["prettier-plugin-tailwindcss"]="Lint / Format|prettier-plugin-tailwindcss"
  [knip]="Lint / Format|knip" [husky]="Lint / Format|husky" ["lint-staged"]="Lint / Format|lint-staged"
  ["@commitlint/cli"]="Lint / Format|commitlint"

  ["@tsconfig/strictest"]="TypeScript Config|@tsconfig/strictest"

  ["@tauri-apps/api"]="Desktop / Mobile Shell|Tauri" [expo]="Desktop / Mobile Shell|Expo"
  ["react-native"]="Desktop / Mobile Shell|React Native" [electron]="Desktop / Mobile Shell|Electron"

  ["@mastra/core"]="AI SDKs|Mastra" [ai]="AI SDKs|Vercel AI SDK" ["@ai-sdk/react"]="AI SDKs|Vercel AI SDK"
  [ollama]="AI SDKs|ollama" ["ollama-ai-provider-v2"]="AI SDKs|ollama-ai-provider-v2"
  ["@openrouter/sdk"]="AI SDKs|@openrouter/sdk" ["workers-ai-provider"]="AI SDKs|workers-ai-provider"
  [openai]="AI SDKs|openai (direct)" ["@anthropic-ai/sdk"]="AI SDKs|@anthropic-ai/sdk (direct)"
  [langchain]="AI SDKs|langchain"

  ["@modelcontextprotocol/sdk"]="MCP|@modelcontextprotocol/sdk" ["@mastra/mcp"]="MCP|@mastra/mcp"

  ["openapi-typescript"]="Codegen And SDKs|openapi-typescript" ["@hey-api/openapi-ts"]="Codegen And SDKs|@hey-api/openapi-ts"

  ["date-fns"]="Utility Belt|date-fns" [rambda]="Utility Belt|rambda" [ramda]="Utility Belt|ramda (legacy)"
  [zx]="Utility Belt|zx" [commander]="Utility Belt|commander" [inquirer]="Utility Belt|inquirer"
  [cheerio]="Utility Belt|cheerio" ["@octokit/rest"]="Utility Belt|@octokit/rest"
  ["framer-motion"]="Utility Belt|framer-motion" [motion]="Utility Belt|motion"
)

# Packages too generic to be a "signal" — exclude from the unmapped tally.
NOISE_RE='^(typescript|tslib|@types/.*|dotenv|@renkonos/.*|workspace:.*)$'

declare -A CAT_COUNT   # "Category|Label" -> repo count
declare -A UNMAPPED    # pkg -> repo count
declare -a REPO_NAMES=()

deps_for_repo() {
  # Union of dependencies/devDependencies/peerDependencies across the repo's
  # root package.json, its workspace member package.jsons, and (Bun-style)
  # workspaces.catalog keys.
  local repo="$1" root="$repo/package.json"
  [ -f "$root" ] || return 0

  local files=("$root")
  local pattern
  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue
    for d in "$repo"/$pattern; do
      [ -f "$d/package.json" ] && files+=("$d/package.json")
    done
  done < <(jq -r '
    .workspaces //empty
    | if type == "array" then .[] elif type == "object" then (.packages // [])[] else empty end
  ' "$root" 2>/dev/null)

  jq -rs '
    map(
      (.dependencies // {} | keys[]),
      (.devDependencies // {} | keys[]),
      (.peerDependencies // {} | keys[]),
      ((.workspaces // {}) | if type == "object" then (.catalog // {}) else {} end | keys[])
    ) | unique[]
  ' "${files[@]}" 2>/dev/null || true
}

scan_repo() {
  local repo="$1"
  [ -f "$repo/package.json" ] || return 0
  local name; name="$(basename "$repo")"
  local pkgs; pkgs="$(deps_for_repo "$repo")"
  [ -n "$pkgs" ] || return 0

  REPO_NAMES+=("$name")

  local seen_cats=""
  local pkg
  while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    local entry="${MAP[$pkg]:-}"
    if [ -z "$entry" ] && [[ "$pkg" == @radix-ui/* ]]; then
      entry="UI Component Library|@radix-ui/*"
    fi
    if [ -n "$entry" ]; then
      if [[ ",$seen_cats," != *",$entry,"* ]]; then
        CAT_COUNT["$entry"]=$(( ${CAT_COUNT["$entry"]:-0} + 1 ))
        seen_cats="$seen_cats,$entry"
      fi
    elif [[ ! "$pkg" =~ $NOISE_RE ]]; then
      UNMAPPED["$pkg"]=$(( ${UNMAPPED["$pkg"]:-0} + 1 ))
    fi
  done <<<"$pkgs"
}

if [ "$#" -gt 0 ]; then
  scanned_where="$# explicit path(s)"
  for r in "$@"; do
    real="$(cd "$r" 2>/dev/null && pwd)" || { echo "derive-signals: skipping unreadable path $r" >&2; continue; }
    scan_repo "$real"
  done
else
  scanned_where="$SCAN_DIR"
  for r in "$SCAN_DIR"/*/; do
    r="${r%/}"
    real="$(cd "$r" 2>/dev/null && pwd)" || continue   # unreadable/permission-denied dir
    [ "$real" = "$ROOT" ] && continue                  # skip alanstack itself
    scan_repo "$real"
  done
fi

total="${#REPO_NAMES[@]}"
echo "# Signal Report"
echo
echo "Scanned $total repo(s) with a package.json under $scanned_where."
echo "Compare against \`skills/alanstack/references/preferred-tools.md\`. This report is evidence, not an edit — fold it in by hand."
echo

echo "## Category usage"
echo
# Group CAT_COUNT keys by category (part before '|'), print label -> count sorted desc.
for key in "${!CAT_COUNT[@]}"; do
  printf '%s\t%s\n' "$key" "${CAT_COUNT[$key]}"
done | awk -F'\t' '{split($1,a,"|"); print a[1]"\t"a[2]"\t"$2}' | sort -t $'\t' -k1,1 -k3,3nr | \
awk -F'\t' '
  $1 != prev { if (prev != "") print ""; print "### " $1; prev = $1 }
  { printf "- %s: %s/%d repos\n", $2, $3, '"$total"' }
'

echo
echo "## Unmapped packages seen in >= $MIN_UNMAPPED_HITS repos (candidate new signals)"
echo
unmapped_lines="$(
  for pkg in "${!UNMAPPED[@]}"; do
    count="${UNMAPPED[$pkg]}"
    if [ "$count" -ge "$MIN_UNMAPPED_HITS" ]; then printf '%s\t%s\n' "$count" "$pkg"; fi
  done | sort -t $'\t' -k1,1nr
)"
if [ -n "$unmapped_lines" ]; then
  while IFS=$'\t' read -r count pkg; do
    echo "- $pkg: $count/$total repos"
  done <<<"$unmapped_lines"
else
  echo "(none)"
fi
