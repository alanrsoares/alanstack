#!/usr/bin/env bash
# resolve.sh <pr...>: resolve every unresolved CodeRabbit thread on each PR. A person's thread
# stays open: they resolve their own. Run only once the fixes are pushed.
set -euo pipefail
[ $# -gt 0 ] || { echo "usage: resolve.sh <pr...>" >&2; exit 2; }
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
q='query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){pullRequest(number:$n){
  reviewThreads(first:100){nodes{id isResolved comments(first:1){nodes{author{login}}}}}}}}'
m='mutation($t:ID!){resolveReviewThread(input:{threadId:$t}){thread{isResolved}}}'
for n in "$@"; do
  ids=$(gh api graphql -f query="$q" -F o="${repo%/*}" -F r="${repo#*/}" -F n="$n" \
    -q '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved|not)
        | select(.comments.nodes[0].author.login|test("coderabbit")) | .id')
  count=0
  for t in $ids; do gh api graphql -f query="$m" -F t="$t" >/dev/null; count=$((count+1)); done
  echo "#$n resolved $count"
done
