Initialize a professional project from scratch or from existing code.

## Step 1: Diagnose

Scan current directory and report checklist:
```
[ ] Git (.git/)    [ ] GitHub (origin)     [ ] .gitignore
[ ] CLAUDE.md      [ ] .stania/           [ ] package.json
[ ] Monorepo       [ ] Linter (biome)     [ ] TypeScript strict
[ ] Tests (vitest) [ ] CI/CD (.github/)   [ ] Deploy config
```

## Step 2: Gather context

If no CLAUDE.md, ask:
1. What does the project do? (1 sentence)
2. Stack? Infer or ask: frontend (Next.js/Nuxt/None), backend (API routes/separate), DB
3. Architecture? Clean+DDD / MVC / Simple
4. Team size? Solo / Team
5. Testing profile? mvp / production / hardened
   - **mvp**: coverage 60%, no mutation testing, fast iteration
   - **production**: coverage 80%, mutation threshold 80%
   - **hardened**: coverage 90%+, mutation threshold 100%, security audit

## Step 3: GitHub repo

```bash
gh repo create <name> --private --source=. --push 2>/dev/null
gh repo edit --enable-issues
```

## Step 4: Create .stania/

Create `.stania/config.json` with: version, mode, stack, architecture, deploy, team, hardening, testFlags, testingProfile, testing.

Testing profile sets defaults in config.json:
```json
{
  "testingProfile": "mvp|production|hardened",
  "hardening": {
    "coverageTarget": { "domain": 60|80|100, "application": 40|60|80, "overall": 60|80|90 },
    "mutationThreshold": 0|80|100
  },
  "testing": {
    "testAccountEmail": null,
    "testAccountFlag": "is_test"
  }
}
```

Create `.stania/me.json`: `{ "role": "lead", "name": "<user>" }`
Create `.stania/team.json` if team mode.
Create `.stania/specs/` and `.stania/ui-specs/` directories (standardized).
Create `.stania/reviews/` directory.
Create `.stania/snapshots.json`: `{ "snapshots": [] }`
Add `.stania/me.json`, `.stania/progress.json`, `.stania/reviews/`, `.stania/snapshots.json` to `.gitignore`.

## Step 5: Project structure

**Monorepo** (frontend + backend):
```
apps/web/src/{app,components,lib}  apps/api/src/{domain,application,infrastructure}
packages/contracts/  turbo.json  pnpm-workspace.yaml  biome.json  .github/workflows/
```

**Single app** (Next.js full-stack):
```
src/{app/api,components,lib,domain}  contracts/  .github/workflows/
```

## Step 6: Tooling

Configure: pnpm-workspace.yaml, turbo.json, biome.json, tsconfig (strict), vitest.config.ts
Install base deps: typescript, vitest, biome, turbo, zod, playwright, react-query

## Step 7: CI/CD

Create `.github/workflows/ci.yml` (typecheck + lint + test on PR).
Create `.github/workflows/deploy.yml` (Vercel + Cloud Run on push to main).

## Step 8: Deploy setup

Vercel: `cd apps/web && npx vercel link`
Cloud Run: verify Dockerfile in apps/api/

## Step 9: Labels + verify + commit

```bash
gh label create "agent" "frontend" "backend" "needs-decision" "ready-to-review" "contract" "intern-ready"
pnpm install && pnpm typecheck 2>&1 | tail -3
git add . && git commit -m "chore: project bootstrap with stania" && git push
```

## Report
```
=== BOOTSTRAP COMPLETE ===
NEXT: /st-model → define domain | /st-contract <first-feature>
```
