Build, push, and deploy backend to Cloud Run. Reads config from `.stania/config.json` → `deploy`.

## Steps

1. Read `.stania/config.json` → `deploy` fields: `gcpProject`, `imageName`, `serviceName`, `region`, `dockerfile`, `platform`.
   If missing, error: "Add deploy config to .stania/config.json first."

2. Auto-detect next tag version:
```bash
gcloud container images list-tags <imageName> --project=<gcpProject> --format="value(tags)" --limit=5 2>&1 | grep -oP 'v\d+' | sort -t'v' -k2 -n | tail -1
```
Increment to next version. If none found, start at v1.

3. **Run as subagent** (Agent tool) to keep build output out of main context. The subagent should:
   - `docker build --platform <platform> -t <imageName>:<nextTag> -f <dockerfile> .`
   - `docker push <imageName>:<nextTag>`
   - `gcloud run deploy <serviceName> --image <imageName>:<nextTag> --region <region> --project <gcpProject>`
   - Return only: tag, revision name, service URL, or error message.

4. Report one line:
```
Deployed <serviceName> → <revision> (image <tag>)
```

## Flags

- `--skip-build`: Only deploy existing latest image (skip docker build/push)
- `--dry-run`: Show commands without executing

## Rules

- Always use `--platform` from config (ARM→amd64 cross-compile)
- If docker push fails with auth error, run `gcloud auth configure-docker gcr.io --quiet` and retry once
- Timeout: build 10min, push 5min, deploy 5min
- On failure, report which step failed — don't retry automatically
