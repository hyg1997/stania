Setup observability: error tracking, structured logging, health endpoints.

## Usage

- `/st-observe` — Full observability audit + setup recommendations
- `/st-observe --setup <tool>` — Install and configure a specific tool
- `/st-observe --check` — Verify existing observability is working

## Step 1: Audit current state

**Run as subagent** (keeps verbose grep output out of main context):

```
Check these 5 categories and report as [x]/[ ] checklist:

1. Error Tracking:
   grep -rn "sentry\|@sentry" package.json apps/ 2>/dev/null | head -3
   grep -rn "Sentry.init\|captureException" apps/ 2>/dev/null | head -3

2. Structured Logging:
   grep -rn "pino\|winston\|console.log\|console.error" apps/api/src/ 2>/dev/null | head -5
   (console.log = unstructured = bad)

3. Health Endpoint:
   grep -rn "health\|/health\|healthcheck" apps/api/src/ 2>/dev/null | head -3

4. Error Boundaries (frontend):
   grep -rn "ErrorBoundary\|error.tsx\|global-error" apps/web/ 2>/dev/null | head -3

5. Environment Variables:
   grep -rn "SENTRY_DSN\|LOG_LEVEL\|NODE_ENV" .env* apps/ 2>/dev/null | head -5

Report: [x]/[ ] per category, max 15 lines.
```

## Step 2: Report findings

```
=== OBSERVABILITY AUDIT ===
[x] Error Tracking:    Sentry configured (apps/api, apps/web)
[ ] Structured Logging: Using console.log (12 occurrences) — needs pino/winston
[x] Health Endpoint:    /health exists at apps/api/src/routes/health.ts
[ ] Error Boundaries:   Missing global-error.tsx in apps/web
[x] Env Variables:      SENTRY_DSN set in .env

Score: 3/5 — NEEDS IMPROVEMENT
```

## Step 3: Setup recommendations

For each missing item, provide specific setup:

### Error Tracking (Sentry)
```bash
pnpm add @sentry/nextjs --filter web 2>&1 | tail -3
pnpm add @sentry/node --filter api 2>&1 | tail -3
```
Generate: `sentry.client.config.ts`, `sentry.server.config.ts`, instrumentation hook.

### Structured Logging (Pino)
```bash
pnpm add pino pino-pretty --filter api 2>&1 | tail -3
```
Generate: `apps/api/src/lib/logger.ts` with structured JSON output.
Replace all `console.log` with `logger.info/error/warn`.

### Health Endpoint
Generate `apps/api/src/routes/health.ts`:
- Check DB connectivity
- Check external service connectivity
- Return `{ status: "ok", uptime, version, checks: {...} }`

### Error Boundaries
Generate `apps/web/src/app/global-error.tsx` + `apps/web/src/app/error.tsx`:
- Capture error to Sentry
- Show user-friendly error page with retry

### Environment Variables
Generate `.env.example` with all required vars documented.

## --check mode

Verify observability is actually working:
```bash
# Sentry: trigger test error
curl -X POST <apiUrl>/api/debug-sentry 2>/dev/null
# Health: verify endpoint
curl -sf <apiUrl>/health 2>/dev/null | head -5
# Logs: verify structured output
pnpm --filter api dev &
sleep 2
curl -sf <apiUrl>/health 2>/dev/null
# Check logs are JSON, not plain text
```

## Rules

- NEVER expose debug/test endpoints in production (guard with NODE_ENV)
- Delegate audit scanning to subagent (token isolation)
- Truncate all output
- Setup is interactive — confirm each tool before installing
- Prefer pino over winston (faster, lower memory)
- Prefer Sentry free tier (5K errors/month) for solopreneurs
