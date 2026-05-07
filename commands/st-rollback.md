Revert a failed deployment. Supports Vercel (frontend) and Cloud Run (backend).

## Usage

- `/st-rollback` — Rollback both frontend and backend to last known good
- `/st-rollback --web` — Rollback frontend only (Vercel)
- `/st-rollback --api` — Rollback backend only (Cloud Run)

## Step 1: Detect deploy targets

Read `.stania/config.json` → `deploy`:
- `frontend`: vercel / netlify / other
- `backend`: cloudrun / railway / fly / other

## Step 2: Identify current and previous deployments

### Vercel (frontend)
```bash
npx vercel ls --limit 5 2>&1 | tail -7
```
Show last 5 deployments with status (READY/ERROR/BUILDING).

### Cloud Run (backend)
```bash
gcloud run revisions list --service=<service> --region=<region> --limit=5 --format="table(name,status,traffic)" 2>&1 | tail -7
```

## Step 3: Confirm rollback target

Show user:
```
=== ROLLBACK TARGETS ===
Frontend (Vercel):
  Current: deployment-abc123 (May 07, ERROR)
  Rollback to: deployment-xyz789 (May 06, READY)

Backend (Cloud Run):
  Current: revision-003 (May 07, 100% traffic)
  Rollback to: revision-002 (May 06, 0% traffic)

Proceed? [y/N]
```

## Step 4: Execute rollback

### Vercel
```bash
npx vercel promote <previous-deployment-url> 2>&1 | tail -5
```

### Cloud Run
```bash
gcloud run services update-traffic <service> --region=<region> \
  --to-revisions=<previous-revision>=100 2>&1 | tail -5
```

## Step 5: Verify

Run /st-health logic internally:
```bash
curl -sf -o /dev/null -w "%{http_code} %{time_total}s" <frontendUrl> 2>/dev/null
curl -sf -o /dev/null -w "%{http_code} %{time_total}s" <apiUrl>/health 2>/dev/null
```

## Report

```
=== ROLLBACK COMPLETE ===
Frontend: Rolled back to deployment-xyz789 — OK (200, 1.1s)
Backend:  Rolled back to revision-002 — OK (200, 0.3s)

NEXT: Investigate failure, fix, then /st-ship again.
```

## Database rollback

If the failed deploy included a migration:
1. Warn: "This deploy included DB migration 0003_xxx. Database rollback may be needed."
2. Suggest: "/st-migrate-db rollback to revert schema changes"
3. NEVER auto-rollback database — always require explicit confirmation

## Rules

- ALWAYS confirm before executing rollback
- Verify health after rollback
- If rollback fails: show error + suggest manual intervention
- Truncate all output
- Log rollback in progress.json → lastSession
