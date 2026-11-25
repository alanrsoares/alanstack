---
name: ponytail-review
description: "Review a change, or a whole repo, for correctness, safety, load, missing tests, speed, and code that should not exist. Reads the connected code, not only the diff. Reports findings, changes no code. Use for review this, review my PR, audit the repo, or find bloat. TypeScript style belongs to alanstack-review."
disable-model-invocation: true
---

Review like the senior developer who gets paged when it breaks. Priority order: correct, safe, holds under load, tested, fast, lean. Every extra line must be read, tested, and fixed later. The user asked for a report, so give it in full. Source: [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT), `ponytail-review` and `ponytail-audit`, merged.

## 1. Scope

- The user names the target: staged or uncommitted changes, a branch, a PR, files, a folder, or the whole repo. Default: uncommitted changes, or the last commit if there are none.
- A named folder, a whole repo, or the word "audit" is **repo mode**. Otherwise it is **change mode**.

## 2. Understand first

- Change mode: read the diff, then the code it touches. Read callers of each changed function, the functions it calls, and the tests. When a signature, return value, or behavior changes, grep every caller.
- Repo mode: read the README, build and deploy config, dependency list, entry points, and tests. Read fully the paths that handle user input, money, auth, data writes, background jobs, and shared state. In a big repo, go deep where a mistake costs most. Say which parts you did not read.
- Trace the real flow: where data comes in, what is stored, what goes out.
- Find the expected load in the repo: one person with a script, or many users and processes. Judge scale against it. Say which load you assumed.

## 3. Look for

1. **Bug**: wrong result, crash, missed edge case (empty, zero, last item, rounding, time zones), a caller broken by the change, a fix in one caller while the shared function stays broken.
2. **Risk**: injection, weak randomness, secrets in code, missing checks on user input, swallowed errors, writes in the wrong order, no transaction.
3. **Scale**: check-then-write races, repeated work in every process, lists that only grow, a query per item, O(n^2) on large input, per-process state that must be shared.
4. **Missing test**: risky new logic (branch, parser, money, security, data write, bug fix) with no test that fails when it breaks. One good test, not coverage.
5. **Speed**: a large slowdown is a problem. A small gain in a hot loop is a suggestion.
6. **Lean**: `delete` (dead code, unused options), `reuse` (name the existing helper path), `stdlib` (the platform already does it), `yagni` (abstraction with one implementation), `merge` (near-copies that change together), `split` (one function with unrelated jobs; split by job, never by line count).

## 4. Check before you report

- Each finding needs a concrete case: this input leads to this wrong result. No case, no finding.
- Re-read the lines. Confirm the caller exists, the value can be empty, the code is unused. Before you call code unused, grep the whole tree, including tests, config, and string references.
- A `shortcut:` comment that names its limit is a decision, not a finding, unless the expected load already crosses the limit.
- Propose the smallest fix. Prefer a fix that deletes code. Add no layer, framework, or config.
- No style taste, no "consider", no vague worry.

## 5. Output

Start with `What this change does:` (or `What this repo does:`) in two or three sentences. In repo mode, add the load you assumed.

Group findings, skip empty groups:
- **Must fix**: bug, security, data loss, breaks at the expected load.
- **Should fix**: risky code without a test, real slowness, duplication, mixed jobs, code that should not exist.
- **Nice to have**: small speed gains, shorter forms.

Number findings across groups so the user can say "fix 2 and 5". In repo mode, report at most 20 and say how many you left out. Each finding has four parts, each one or two short sentences:

N. **<title>** (`path:Lstart-end`)
   - **What this is**: what the code does.
   - **Problem**: the concrete case.
   - **Fix**: the smallest change.
   - **If we skip it**: the cost.

End with:
- `Verdict: Ship.` or `Verdict: fix 1 and 3 first.` (repo mode: `healthy` or what to fix first)
- `Lean: -<N> lines possible.` when lean findings exist.
- `Not checked:` one line, if something mattered and you could not check it.

Nothing found: the first line, then `Looks good. Ship.` and one line on what you checked. Done when the verdict line is written.
