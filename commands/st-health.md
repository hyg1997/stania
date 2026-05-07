Post-deploy health verification. Quick smoke test after /st-deploy or manual deploy.

## Usage

- `/st-health` — Check production endpoints
- `/st-health --staging` — Check staging/preview

## Step 1: Resolve URLs

Read `.stania/config.json` → `deploy`:
- `productionUrl` / `stagingUrl` for frontend
- `apiUrl` / `stagingApiUrl` for backend

If missing: ask user for URLs.

## Step 2: Frontend health

```bash
HTTP_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" <frontendUrl> 2>/dev/null)
LOAD_TIME=$(curl -sf -o /dev/null -w "%{time_total}" <frontendUrl> 2>/dev/null)
```

Check:
- HTTP 200
- Load time < 3s
- Response contains expected content (title tag, main div)

## Step 3: API health

```bash
curl -sf <apiUrl>/health -w "\n%{http_code} %{time_total}s" 2>/dev/null | tail -2
```

Check:
- HTTP 200
- Response time < 1s
- Body contains expected shape (e.g., `{"status":"ok"}`)

## Step 4: Critical endpoints

If `.stania/domain-model.json` exists, check first 3 aggregate endpoints:
```bash
curl -sf -o /dev/null -w "%{http_code}" <apiUrl>/api/<aggregate> 2>/dev/null
```

Expect: 200 or 401 (auth required = endpoint exists and is protected).

## Step 5: Database connectivity (via API)

The health endpoint should verify DB connection. If it returns degraded status, flag it.

## Report

```
=== HEALTH CHECK: [env] ===
Frontend:  OK (200, 1.2s) | FAIL
API:       OK (200, 0.3s) | FAIL
DB:        OK (via health) | DEGRADED | UNKNOWN
Endpoints: 3/3 responding

VERDICT: [HEALTHY] | [DEGRADED: ...] | [DOWN: ...]
```

## Rules

- Total execution: <15 seconds
- No authentication required (health endpoints should be public)
- On failure: suggest `/st-monitor` for detailed E2E diagnosis
- Never modify any data — purely read-only checks
- Truncate all curl output
