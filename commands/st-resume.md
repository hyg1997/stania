Session resumption. Reads last session state and generates a briefing with suggested next action.

## Process

1. Read `.stania/progress.json` → `lastSession` field
2. Read `.stania/config.json` → `mode`, `stack`
3. Quick state scan:

```bash
git log --oneline -5 2>/dev/null
git status --short 2>/dev/null | head -5
```

4. Build briefing from progress.json:
   - Last session date + summary
   - Aggregates in-progress (layers incomplete)
   - Aggregates done since last session
   - Any uncommitted changes

## Output (max 8 lines)

```
=== RESUME ===
Last: [date] — [summary]
Done: [aggregates completed]
In progress: [aggregate] — missing [layers]
Uncommitted: [Y/N] [file count]

NEXT:
-> [most urgent action]: [command]
-> [secondary action]: [command]
```

## Logic for next action

Priority order:
1. Uncommitted changes → "Commit or /st-check first"
2. In-progress aggregate → "/st-build [name] to continue [layer]"
3. Tests failing → "/st-check to diagnose"
4. All aggregates done → "/st-ship or /st-e2e for end-to-end"
5. Nothing pending → "/st-retro to close or plan next feature"

## Rules

- Max 8 lines output
- If no `.stania/progress.json`: "No session state. Run /st-bootstrap or /st-build to start."
- If lastSession missing: still report aggregate status
- Never read file contents — only progress.json metadata + git state
- Must complete in <5 seconds
