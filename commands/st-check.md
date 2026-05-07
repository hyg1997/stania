Validation + hardening pipeline. Runs after /st-build or before commit.

## Fase 1: Validation (PARALLEL — 3 tool calls)

Read `.stania/config.json` → `stack`, `testFlags`.

```bash
pnpm typecheck 2>&1 | tail -5
pnpm lint 2>&1 | tail -5
pnpm test --bail --reporter=dot 2>&1 | tail -10
```

Report: `Typecheck: PASS | Lint: PASS | Tests: PASS (N/N)`
On failure: read ONLY failed step's full output, autofix (max 2 attempts).

## Fase 2: Hardening (only modified files)

```bash
FILES=$(git diff --name-only HEAD~1 2>/dev/null)
```

### Architecture (if `architecture: "clean"`)
```bash
grep -rn "from.*infrastructure\|from.*application" apps/api/src/domain/ 2>/dev/null
```

### Cache invalidation check (React Query)
For each mutation hook in modified files:
```bash
grep -A5 "useMutation" apps/web/src/lib/queries/*.ts 2>/dev/null | grep -B3 "mutationFn" | grep -v "invalidateQueries"
```
Flag any `useMutation` without `onSuccess` → `invalidateQueries` as WARNING.

### Security
```bash
grep -rn "sk-\|api_key\|password\s*=\s*[\"']" --include="*.ts" --include="*.env" . 2>/dev/null | grep -v node_modules | head -5
```

### AI Code Smells (modified files only)
Check: happy path bias, invisible coupling, test theater, stale patterns. Keep brief.

## Fase 3: Progress auto-sync

Scan filesystem and auto-correct `progress.json` layer flags:
```bash
for agg in $(jq -r '.aggregates | keys[]' .stania/progress.json); do
  ctx=$(echo $agg | cut -d/ -f1 | tr '[:upper:]' '[:lower:]')
  name=$(echo $agg | cut -d/ -f2 | tr '[:upper:]' '[:lower:]')
  # Check each layer exists
  domain=$(find apps/api/src/domain -iname "*${name}*" 2>/dev/null | head -1)
  tests=$(find apps/api/src/__tests__ -iname "*${name}*" 2>/dev/null | head -1)
done
```
Update any mismatched flags silently. Report only if changes were made.

## Fase 4: REVIEW.md generation

Write findings to `.stania/reviews/REVIEW-<date>.md`:

```markdown
# Code Review — <date>
## Validation
Typecheck: PASS | Lint: PASS | Tests: PASS (N/N)
## Hardening
Architecture: PASS | Cache: PASS | Security: PASS
## AI Code Smells
[list findings or "None detected"]
## Mutation Readiness
[aggregates with >80% coverage → "Ready for /st-mutate"]
[aggregates with <80% coverage → "Needs more tests"]
```

If `.stania/reviews/` doesn't exist, create it. Add to `.gitignore`.

## Fase 5: Auto-detect mutation testing readiness

Check coverage per aggregate (from last test run or coverage report).
If any aggregate has domain coverage >80% and hasn't been mutation-tested:
→ Append to report: "Mutation ready: [aggregate]. Run /st-mutate [aggregate]"

## Report

```
=== VALIDATION ===
Typecheck: PASS | Lint: PASS | Tests: PASS (545/545)
=== HARDENING ===
Architecture: PASS | Cache: PASS | Security: PASS
=== MUTATION READINESS ===
Ready: Routine, WorkoutSession | Needs tests: Pantry
=== VERDICT ===
[PASS] Ready for commit — Review saved to .stania/reviews/
```

Update `.stania/progress.json` → `lastCheck` for affected aggregates.

## Rules
- Truncate ALL command output (tail -5 / tail -10)
- Max 2 autofix attempts per failure
- PASS → "Ready for commit?" | WARN → show findings | FAIL → fix or report
- Always generate REVIEW.md (even on PASS — for audit trail)
