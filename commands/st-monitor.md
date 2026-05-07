Run Playwright E2E tests against staging or production URLs. Catches regressions in deployed environments.

## Usage

- `/st-monitor` — Run against production URL (from config)
- `/st-monitor --staging` — Run against staging/preview URL
- `/st-monitor --url <url>` — Run against custom URL

## Step 1: Resolve target URL

Priority:
1. Explicit `--url` argument
2. `.stania/config.json` → `deploy.productionUrl` (or `deploy.stagingUrl` for --staging)
3. Vercel: `npx vercel inspect 2>/dev/null | grep "Production" | head -1`
4. Ask user

## Step 2: Find E2E tests

```bash
find . -path "*/e2e/*.spec.ts" -o -path "*/e2e/*.test.ts" -o -path "*/__e2e__/*.ts" 2>/dev/null | head -20
```

If no E2E tests exist: "No E2E tests found. Run /st-e2e first."

## Step 3: Run Playwright against target

```bash
BASE_URL=<target_url> npx playwright test --reporter=dot 2>&1 | tail -20
```

If specific tests for monitoring exist (tagged `@monitor` or in `e2e/monitor/`):
```bash
BASE_URL=<target_url> npx playwright test --grep @monitor --reporter=dot 2>&1 | tail -20
```

## Step 4: API health check

If `.stania/config.json` has `deploy.apiUrl`:
```bash
curl -sf <apiUrl>/health -o /dev/null -w "%{http_code} %{time_total}s" 2>/dev/null || echo "FAIL"
```

## Step 5: Schemathesis (if OpenAPI spec available)

```bash
if command -v schemathesis &>/dev/null; then
  schemathesis run <apiUrl>/openapi.json --checks all --max-response-time 2000 2>&1 | tail -15
fi
```

If not installed: skip silently.

## Step 6: Test account isolation

If running against production, check for test account config:
- `.stania/config.json` → `testing.testAccountEmail`
- If configured: run tests authenticated as test account
- If not: run only unauthenticated flows + warn "Configure testing.testAccountEmail for auth flows"

## Report

```
=== MONITOR: [target] ===
E2E:          PASS (N/N) | FAIL (N failures)
API Health:   PASS (200, 0.15s) | FAIL (status/timeout)
Schema:       PASS | WARN (N issues) | SKIPPED
Auth flows:   PASS | SKIPPED (no test account)

[If failures: list first 3 failing test names]
```

## Scheduling (optional)

To run on a schedule in CI, suggest adding to `.github/workflows/monitor.yml`:
```yaml
on:
  schedule:
    - cron: '*/15 * * * *'  # every 15 min
```

## Rules

- Never modify production data — read-only tests only
- Truncate all output (tail -20 max)
- If Playwright not installed: `npx playwright install chromium 2>&1 | tail -3` first
- Timeout per test: 30s (production should be fast)
- Total timeout: 2 minutes
- On failure: suggest `/st-check` locally to diagnose
