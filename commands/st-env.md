Compare `.env.example` with deployed environment variables. Detect missing or extra vars.

## Steps

1. Read `.env.example` → extract variable names (left side of `=`).

2. Read deployed env vars:
```bash
gcloud run services describe <serviceName> --region <region> --project <gcpProject> --format="yaml(spec.template.spec.containers[0].env)" 2>&1
```
Read `serviceName`, `region`, `gcpProject` from `.stania/config.json` → `deploy`.

3. Compare and report:
```
=== ENV SYNC ===
[x] DATABASE_URL — set in Cloud Run
[x] JWT_SECRET — set in Cloud Run
[ ] SENTRY_DSN — in .env.example but MISSING in Cloud Run
[+] EXTRA_VAR — in Cloud Run but NOT in .env.example

Missing: 1 | Extra: 0
```

4. If `--set VAR=value` argument provided:
```bash
gcloud run services update <serviceName> --region <region> --project <gcpProject> --update-env-vars "VAR=value"
```

## Rules

- Never print actual values — only variable names
- If `.env.example` doesn't exist: "No .env.example found."
- If gcloud fails: report auth issue, don't retry
