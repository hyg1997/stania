Onboard a new team member. Sets up their role, creates guide, explains workflow.

## Usage

`/st-onboard <name> <role>` — role: lead | partner | intern

## Steps

1. Create `.stania/me.json` for the new member:
```json
{ "role": "<role>", "name": "<name>" }
```

2. Update `.stania/team.json` (create if missing):
```json
{
  "members": [
    { "name": "<name>", "role": "<role>", "joinedAt": "<ISO8601>" }
  ]
}
```

3. Show role-specific guide:

### Partner guide
```
Welcome <name>! You're a partner developer.

YOUR WORKFLOW:
1. Check what's next:           /st-next
2. Pick a contract to build:    /st-agent <contract-name>
3. Validate your work:          /st-check
4. Submit for review:           /st-ship
5. End of session:              /st-retro

KEY RULES:
- Always branch from main: git checkout -b feat/<name>
- Contract-first: read packages/contracts/ before coding
- Domain logic in apps/api/src/domain/ — no framework imports
- Tests required: domain invariants + use case happy/error paths
- PRs need 1 approval from lead before merge

ARCHITECTURE:
apps/web/          → Next.js frontend (you + intern)
apps/api/          → Hono backend (you + lead)
packages/contracts → Shared types (lead defines, you consume)

ASK LEAD WHEN:
- New bounded context needed
- Contract change required
- Architecture decision unclear
```

### Intern guide
```
Welcome <name>! You're a frontend intern.

YOUR WORKFLOW:
1. Check assigned tasks:        /st-next
2. Need a backend endpoint?     /st-need-contract <name>
3. Build UI from spec:          /st-ui <spec-name>
4. Validate your work:          /st-check
5. Submit for review:           /st-ship

KEY RULES:
- Work in apps/web/src/ only
- Use contracts from packages/contracts/ for types
- Follow existing component patterns (inline styles, dark theme)
- All mutations need onSuccess → invalidateQueries
- PRs need lead approval

PATTERNS:
- Pages: apps/web/src/app/<feature>/page.tsx
- Queries: apps/web/src/lib/queries/<feature>-queries.ts
- Components: apps/web/src/components/<feature>/

DON'T:
- Modify apps/api/ (ask lead/partner)
- Change packages/contracts/ (use /st-need-contract)
- Push directly to main
```

4. Verify setup:
```bash
git status
pnpm install
pnpm typecheck 2>&1 | tail -3
```

## Rules
- Create team.json if it doesn't exist
- Don't overwrite existing me.json — warn if it exists
- Suggest `/st-next` as first action after onboarding
