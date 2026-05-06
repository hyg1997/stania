Launch autonomous implementation of a contract or issue.

## Usage

- `/st-agent <contract-name>` — implement a specific contract
- `/st-agent #<issue>` — implement a GitHub issue
- `/st-agent <agg1> <agg2>` — (solo) spawn parallel agents
- `/st-agent --all-pending` — (solo) spawn agents for all pending aggregates

## Mode Detection

Read `.stania/config.json` → `mode`.

**Solo**: work on current branch, commit directly, no PR. Self-check (typecheck+tests).
**Team**: create branch `feat/<name>`, PR with labels, notify via push notification.

## Process

### 1. Read context
```bash
cat packages/contracts/<name>.ts 2>/dev/null
cat .stania/domain-model.json 2>/dev/null | jq '.boundedContexts[] | select(.aggregates[].name == "<name>")'
```

### 2. Branch (team only)
```bash
git checkout -b feat/<name>
```

### 3. Implement

Follow /st-build flow WITHOUT approval gates.

**Clean Architecture**: Domain → Application → Infrastructure → Wiring (4 layers sequential).
**Other**: implement + tests in one step.

Code patterns: follow existing files in the codebase. Read one example file per layer before generating.
Frontend patterns: follow existing pages. Dark theme, inline styles, `const styles = {}`.

### 4. Bounded Context Grouping (solo, multiple aggregates)

Group pending aggregates by bounded context. Spawn ONE agent per context (not per aggregate).
Each agent builds all aggregates in its context sequentially.

### 5. Validate
```bash
pnpm typecheck 2>&1 | tail -5
pnpm test --bail --reporter=dot 2>&1 | tail -10
```
Max 2 fix attempts. If stuck → draft PR with `needs-decision` label.

### 6. Commit

**Solo**: `git add <files> && git commit -m "feat(<name>): implement <desc>"`
**Team**: commit + push + `gh pr create --title "feat(<name>)" --label "agent,ready-to-review"`

### 7. Report

**Solo**: "Done. typecheck + tests pass."
**Team**: PR created with label ready-to-review.

## Rules
- Never auto-merge — only create PR (team) or commit (solo)
- If contract missing → error: "Run /st-contract <name> first"
- If ambiguity → note in PR body, don't assume
- Respect domain-model.json invariants
