Guided refactoring: detect issues, plan changes, execute, validate nothing broke.

## Usage

- `/st-refactor` — Scan for refactoring opportunities
- `/st-refactor <target>` — Refactor specific file/module/aggregate
- `/st-refactor --smell <type>` — Fix specific code smell

## Step 1: Detect opportunities

**Run as subagent** for token isolation:

```
Scan codebase for refactoring opportunities:

1. Duplication:
   Find files with similar structure/logic (>30 lines overlap).

2. Large files:
   find apps/ -name "*.ts" -o -name "*.tsx" | xargs wc -l | sort -rn | head -10

3. Complex functions:
   grep -rn "function\|=>" --include="*.ts" apps/ | awk '{print FILENAME}' | sort | uniq -c | sort -rn | head -10

4. Dead code:
   Exports not imported elsewhere.

5. Inconsistent patterns:
   Same operation done differently across files (e.g., error handling, API calls).

6. AI Code Smells (from SKILL.md):
   Check modified files for the 8 known smells.

Report: top 5 opportunities ranked by impact. Each with: location, what, why, estimated effort (S/M/L).
Max 20 lines.
```

## Step 2: Plan refactoring

For chosen target, create plan:

```
=== REFACTOR PLAN ===
Target: apps/api/src/application/handlers/
What: Extract common validation pattern into shared middleware
Why: 6 handlers duplicate input validation (DRY violation)
Impact: S (3 files, ~50 lines)

Steps:
1. Extract validation helper → apps/api/src/application/shared/validate.ts
2. Update handlers to use shared validator
3. Update tests
4. Run /st-check

Proceed? [y/N]
```

## Step 3: Execute

After user confirms:
1. Create/modify files per plan
2. Preserve ALL existing behavior (no functional changes)
3. Run typecheck after each major change:
   ```bash
   pnpm typecheck 2>&1 | tail -5
   ```

## Step 4: Validate

Run full validation to ensure nothing broke:
```bash
pnpm typecheck 2>&1 | tail -5
pnpm test --bail 2>&1 | tail -10
```

If any test fails: revert the change that caused it, report issue.

## Step 5: Commit

```bash
git add <changed-files>
git commit -m "refactor(<scope>): <description>"
```

## Report

```
=== REFACTOR COMPLETE ===
Changed: 3 files (handlers/create.ts, handlers/update.ts, shared/validate.ts)
Added: 1 file (shared/validate.ts)
Removed: 0 lines of duplication
Tests: PASS (545/545 — no regressions)
```

## Smell types (for --smell flag)

| Smell | Detection | Fix |
|-------|-----------|-----|
| duplication | Similar code blocks | Extract shared function |
| large-file | >300 lines | Split by responsibility |
| god-function | >50 lines | Extract helpers |
| primitive-obsession | Repeated string/number params | Value Objects |
| feature-envy | Function uses another module's data heavily | Move function |
| dead-code | Unused exports | Delete |
| inconsistency | Same pattern, different implementations | Standardize |

## Rules

- NEVER change behavior during refactoring
- Always validate with tests before and after
- Ask confirmation before executing
- If tests fail after refactor: revert + report
- Small steps: one refactoring at a time, commit after each
- Delegate scanning to subagent
- Truncate all output
