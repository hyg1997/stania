Suggest 1-3 concrete next actions. Max 5 lines output.

## Process

1. Read `.stania/config.json` → `mode`. If `solo`, skip role detection.
   If not solo: read `.stania/me.json` → `role`. If missing, ask and create it.

2. Read state (metadata only, never file contents):
```bash
cat .stania/progress.json 2>/dev/null
git status --short 2>/dev/null | head -5
```
In team mode also: `gh pr list --json number,title,reviewDecision,isDraft --limit 5`

3. Generate suggestions by mode:

**Solo**: uncommitted changes → next pending aggregate → test/mutation gaps → E2E needed
**Lead**: stubs pending → PRs for review → contracts without agent → blocked issues
**Frontend**: stubs pending → UI specs unimplemented → contracts needing UI
**PM**: progress % → blocked PRs/issues → weekly shipped count

4. Output (exact format, max 5 lines):
```
NEXT:
→ [action with context]: [exact command]
→ [action with context]: [exact command]
```

## Rules
- Max 3 actions, prioritized by urgency
- Solo mode: never suggest PR/issue actions
- If nothing pending: "Todo al día. /st-retro o planear próximo sprint."
- Must complete in <5 seconds
