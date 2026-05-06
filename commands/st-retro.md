Session close. Quick — only capture what changes future behavior.

## Process

1. `git log --oneline --since="6 hours ago"` (fallback: `git log --oneline -10`)
2. If architectural decision made → create ADR in docs/decisions/, update CLAUDE.md
3. If no decisions (most sessions) → only update progress.json

## Update state

```json
{ "lastSession": { "date": "<ISO8601>", "summary": "<1 sentence>" } }
```

## Report (max 5 lines)

```
Completado: [short list]
Pendiente:  [short list]
Proximo:    /st-spec → [X] | /st-build → [Y] | nada pendiente
```

## Rules
- No decisions → no ADR, no doc changes
- Never dump long session summary
- User wants to close in 10 seconds
