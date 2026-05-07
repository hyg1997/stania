Feature flag lifecycle: create, wrap code, rollout, cleanup.

## Usage

- `/st-flag create <name>` — Create new feature flag
- `/st-flag wrap <name>` — Wrap existing code with flag
- `/st-flag rollout <name> <percentage>` — Set rollout percentage
- `/st-flag cleanup <name>` — Remove flag after full rollout
- `/st-flag list` — Show all flags and their status

## Step 1: Detect flag provider

```bash
grep -l "posthog\|flagsmith\|launchdarkly\|growthbook\|unleash" package.json 2>/dev/null
grep -rn "useFeatureFlag\|useFlag\|isFeatureEnabled" apps/ 2>/dev/null | head -3
```

If no provider found: suggest setup:
```
No feature flag provider detected. Options:
1. PostHog (recommended — free 1M requests/mo, includes analytics)
2. Flagsmith (open source, self-hostable)
3. Environment variable (simplest, no external dependency)

Which one?
```

## Step 2: Create flag

### PostHog
```typescript
// apps/web/src/lib/flags.ts (or add to existing)
export const FLAGS = {
  '<flag-name>': '<flag-name>',
} as const;
```

Register in PostHog dashboard or via API:
```bash
curl -X POST https://app.posthog.com/api/projects/<id>/feature_flags/ \
  -H "Authorization: Bearer <key>" \
  -d '{"key":"<flag-name>","name":"<description>","active":true,"rollout_percentage":0}' 2>/dev/null | tail -5
```

### Environment variable (simple)
```bash
echo "FEATURE_<FLAG_NAME>=false" >> .env
echo "FEATURE_<FLAG_NAME>=false" >> .env.example
```

## Step 3: Wrap code

### Frontend (React)
```typescript
import { useFeatureFlagEnabled } from 'posthog-js/react';
// or
import { useFlag } from './lib/flags';

function Component() {
  const isEnabled = useFeatureFlagEnabled('<flag-name>');

  if (!isEnabled) return <OldComponent />;
  return <NewComponent />;
}
```

### Backend (Hono/Express)
```typescript
function handler(c: Context) {
  const flagEnabled = await isFeatureEnabled('<flag-name>', userId);

  if (!flagEnabled) {
    return oldBehavior(c);
  }
  return newBehavior(c);
}
```

### Environment variable (simple)
```typescript
const isEnabled = process.env.FEATURE_<FLAG_NAME> === 'true';
```

## Step 4: Rollout

Gradual rollout strategy:
1. 0% → Deploy code behind flag (safe)
2. 5% → Internal testing / test accounts
3. 25% → Early adopters
4. 50% → Half users, monitor errors
5. 100% → Full rollout, monitor 24-48h

Between each step: check error rates, user feedback, performance.

## Step 5: Cleanup

After 100% rollout is stable (48h+):

1. Find all flag usage:
```bash
grep -rn "<flag-name>\|FEATURE_<FLAG_NAME>" apps/ --include="*.ts" --include="*.tsx" 2>/dev/null
```

2. Remove flag checks: keep only the new code path
3. Remove flag definition from flags.ts / .env
4. Delete flag from provider (PostHog/Flagsmith)
5. Run tests to ensure nothing broke:
```bash
pnpm typecheck 2>&1 | tail -5
pnpm test --bail 2>&1 | tail -10
```

6. Commit:
```bash
git commit -m "chore: cleanup feature flag <flag-name>"
```

## Report

```
=== FLAG: <name> ===
Status: active (25% rollout)
Provider: PostHog
Usage: 3 files (component.tsx, handler.ts, flags.ts)
Created: May 07

NEXT: Monitor errors. If stable, /st-flag rollout <name> 50
```

## Rules

- Flag names: kebab-case (my-feature)
- Always start at 0% rollout
- Never delete flag before full rollout is stable (48h)
- Cleanup is mandatory — flags are temporary, not permanent
- Truncate all output
- If no provider: env vars are acceptable for solo projects
