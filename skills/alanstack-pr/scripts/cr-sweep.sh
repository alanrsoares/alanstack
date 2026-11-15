#!/usr/bin/env bash
# cr-sweep.sh [pr...]: CodeRabbit state per PR — unresolved threads, findings only in the
# review body, and a rate limit newer than the last review. Default: my open PRs.
set -euo pipefail
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
owner=${repo%/*}; name=${repo#*/}
prs=("$@")
[ ${#prs[@]} -gt 0 ] || mapfile -t prs < <(gh pr list --author @me --state open --json number -q '.[].number')
[ ${#prs[@]} -gt 0 ] || { echo "no open PRs"; exit 0; }

q='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){
  title reviewThreads(first:100){nodes{id isResolved isOutdated path line
    comments(first:1){nodes{author{login} body url}}}}}}}'

for n in "${prs[@]}"; do
  data=$(gh api graphql -f query="$q" -F o="$owner" -F r="$name" -F n="$n")
  echo "=== #$n $(jq -r '.data.repository.pullRequest.title' <<<"$data")"
  # Unresolved bot threads: id, place, and the bold title line under the severity line.
  jq -r '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved|not) | select(.comments.nodes[0].author.login|test("coderabbit"))
    | .comments.nodes[0] as $c
    | ($c.body | split("\n") | map(select(test("^\\*\\*[^<].*\\*\\*$"))) | first // "?") as $t
    | "  open \(.id) \(.path):\(.line // "outdated") \($t | gsub("\\*\\*";""))\n       \($c.url)"' <<<"$data"
  inline=$(jq '[.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved|not) | select(.comments.nodes[0].author.login|test("coderabbit"))] | length' <<<"$data")

  last=$(gh api "repos/$repo/pulls/$n/reviews" --paginate \
    -q '[.[] | select(.user.login|test("coderabbit"))] | last // empty')
  if [ -n "$last" ]; then
    at=$(jq -r .submitted_at <<<"$last")
    said=$(jq -r '.body' <<<"$last" | grep -oE 'Actionable comments posted: [0-9]+' | grep -oE '[0-9]+$' || echo 0)
    echo "  last review $at: $said actionable, $inline unresolved inline"
    # Outside-diff, duplicate and nitpick findings live only in the body's fix-all prompt;
    # #186 said 4 with 3 threads. Print it while work is open, never on a clean PR.
    if [ "$inline" -gt 0 ] || jq -r .body <<<"$last" | grep -qE 'Outside diff range|Duplicate comments|Nitpick comments'; then
      echo "  body-only findings — read the fix-all prompt:"
      jq -r .body <<<"$last" | sed -n '/Prompt to fix all issues/,/^```$/p' | sed '1,3d;$d;s/^/    /'
    fi
  else
    at="1970-01-01T00:00:00Z"; echo "  no review yet"
  fi
  gh api "repos/$repo/issues/$n/comments" --paginate \
    -q ".[] | select(.user.login|test(\"coderabbit\")) | select(.created_at > \"$at\")
      | select(.body|test(\"rate limit|limit reached|spending cap\";\"i\")) | \"  rate-limited \(.created_at)\"" | tail -1
done
