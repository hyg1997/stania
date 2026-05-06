Capture and communicate an architecture or design decision.

## Usage

- `/st-decision <title>` — record a new decision
- `/st-decision --list` — show recent decisions

## Record decision

1. Ask (if not provided):
   - What was decided?
   - Why? (alternatives considered)
   - What's the impact?

2. Create ADR in `docs/decisions/`:
```bash
COUNT=$(ls docs/decisions/ADR-*.md 2>/dev/null | wc -l | tr -d ' ')
NEXT=$((COUNT + 1))
```

Write `docs/decisions/ADR-<NNN>-<slug>.md`:
```markdown
# ADR-<NNN>: <Title>
**Date**: <today>
**Status**: Accepted
**Decision**: <what>
**Rationale**: <why, alternatives rejected>
**Consequences**: <impact on code, team, future work>
```

3. Create GitHub issue to notify team:
```bash
gh issue create --title "decision: <title>" --label "needs-decision" --body "See docs/decisions/ADR-<NNN>.md"
```

4. Commit:
```bash
git add docs/decisions/
git commit -m "decision: <title> (ADR-<NNN>)"
```

## List decisions

```bash
ls -la docs/decisions/ADR-*.md 2>/dev/null
```
Show title + date for each.

## Rules
- Keep ADRs short (max 15 lines)
- One decision per ADR
- Create docs/decisions/ if missing
