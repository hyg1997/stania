Code review with domain context. Use for PR review or pre-merge check.

## Usage

- `/st-review` — review current branch diff vs main
- `/st-review #<PR>` — review a specific GitHub PR

## Process

1. Get the diff:
```bash
# Current branch
git diff main...HEAD --stat
git diff main...HEAD

# Or specific PR
gh pr diff <number>
gh pr view <number> --json title,body,files
```

2. Read domain context:
```bash
cat .stania/domain-model.json 2>/dev/null
```

3. Review against checklist (report each as PASS/WARN/FAIL):

**Correctness**: Does the code do what the PR says? Any logic bugs?
**Architecture**: Domain imports only from domain? Use cases don't bypass ports?
**Contracts**: Do request/response types match the contract in packages/contracts/?
**Tests**: Are invariants tested? Happy + error paths? No test theater (assert real outcomes)?
**Security**: Input validated? No PII in logs? Auth checked on new endpoints?
**Cache invalidation**: New mutations have `onSuccess → invalidateQueries`?
**Naming**: Files, functions, variables follow existing patterns?

4. Report:
```
=== CODE REVIEW: [title] ===
Correctness:  PASS
Architecture: PASS
Contracts:    WARN — response type missing `updatedAt` field
Tests:        PASS (12 new tests)
Security:     PASS
Cache:        FAIL — useUpdateX missing invalidateQueries
Naming:       PASS

VERDICT: [APPROVE / REQUEST CHANGES]
Findings: [numbered list of specific issues with file:line]
```

5. If PR number provided and verdict is APPROVE:
```bash
gh pr review <number> --approve --body "Reviewed by Stania. All checks pass."
```

## Rules
- Read the FULL diff, not just file names
- Compare against contracts if API endpoints changed
- Never approve if architecture violations found
- Max 10 findings — prioritize blockers over style
