Frontend dev (intern) needs an endpoint that doesn't exist. Creates stub + mock + issue.

## Flow

### 1. Gather
Ask: What UI action? What data to send? What to receive? HTTP method + path?

### 2. Create stub contract

`packages/contracts/src/{name}.stub.ts`:
```typescript
/** STUB — pending lead approval. Issue: #{number} */
import { z } from "zod";
export const [Name]Request = z.object({ /* fields */ });
export const [Name]Response = z.object({ /* fields */ });
export const [name]StubEndpoints = { [action]: { method: 'POST' as const, path: '/api/[path]' } };
```

### 3. Create MSW mock

`packages/contracts/src/generated/mocks/{name}.stub.ts` with realistic fake data.

### 4. Create GitHub issue

```bash
gh issue create --title "contract-needed: [desc]" --label "contract-needed,frontend" \
  --body "Frontend needs this endpoint. Stub: packages/contracts/src/[name].stub.ts"
```

### 5. Escalation

Check if there are stale contract requests:
```bash
gh issue list --label "contract-needed" --json number,title,createdAt --limit 10
```
If any issue is >4 hours old, append to output:
```
⚠ STALE CONTRACTS:
→ #<number> "<title>" — pending <hours>h. Lead should run /st-contract --from-stub <name>
```

### 6. Commit
```bash
git add packages/contracts/src/[name].stub.ts packages/contracts/src/generated/mocks/
git commit -m "stub([name]): frontend needs [desc] — issue #[number]"
```

## When lead approves

Lead runs `/st-contract <name>` → reads stub as starting point → replaces .stub.ts with real contract → closes issue.

## Rules
- Stubs never imported in production code — only mocks/tests
- Frontend doesn't wait — uses mock immediately
- Max 1 stub per feature
- Escalation check runs automatically on every invocation
