Inicializa un proyecto profesional desde cero o desde lo que ya exista.
Crea repo en GitHub, configura deploy (Vercel + Cloud Run), y monta la estructura.

## Paso 1: Diagnostico

Escanea el directorio actual y reporta:

```
[ ] Git inicializado (.git/)
[ ] GitHub repo (origin configurado)
[ ] .gitignore configurado
[ ] CLAUDE.md (contexto maestro)
[ ] .stania/ (state tracking)
[ ] package.json / pyproject.toml / go.mod
[ ] Monorepo configurado (turbo.json / pnpm-workspace.yaml)
[ ] Linter configurado (biome.json)
[ ] TypeScript strict (tsconfig con strict: true)
[ ] Test framework (vitest)
[ ] CI/CD (.github/workflows/)
[ ] Deploy configurado (vercel.json / Dockerfile)
```

Muestra el diagnostico y espera confirmacion.

## Paso 2: Recopilar contexto

Si no existe CLAUDE.md, pregunta:

1. **Que es el proyecto?** (1 oracion)
2. **Para quien?** (cliente ideal)
3. **Stack?** Inferir o preguntar:
   - Frontend: Next.js 15 (default) / Nuxt / Astro / None
   - Backend: Next.js API routes (simple) / Separado en Cloud Run (DDD)
   - DB: Postgres / MySQL / MongoDB / SQLite
4. **Arquitectura?** Clean Architecture + DDD / Simple MVC
5. **Monorepo?** Si tiene frontend + backend separado → si

No preguntar todo — inferir lo posible del contexto.

## Paso 3: Crear GitHub repo

```bash
# Solo si no tiene origin
gh repo create <project-name> --private --source=. --push
gh repo edit --enable-issues --enable-projects

# Branch protection
gh api repos/{owner}/{repo}/branches/main/protection -X PUT \
  -f required_status_checks='{"strict":true,"contexts":["ci"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":1}' 2>/dev/null || true
```

Crear GitHub Projects board:
```bash
gh project create --title "<project-name>" --owner @me 2>/dev/null || true
```

## Paso 4: Crear .stania/

Crear `.stania/config.json`:
```json
{
  "version": "2.0.0",
  "projectName": "[nombre]",
  "stack": {
    "language": "typescript",
    "framework": "[next | fastify | none]",
    "packageManager": "pnpm",
    "testRunner": "vitest",
    "linter": "biome",
    "typeChecker": "tsc"
  },
  "architecture": "[clean | mvc | simple]",
  "deploy": {
    "frontend": "vercel",
    "backend": "cloud-run",
    "region": "us-central1"
  },
  "team": {
    "workflow": "contract-first",
    "agents": true,
    "labels": ["agent", "frontend", "backend", "needs-decision", "ready-to-review"]
  },
  "hardening": {
    "mutationThreshold": 80,
    "coverageTarget": { "domain": 80, "application": 60, "overall": 60 }
  },
  "testFlags": {
    "fast": "--bail --reporter=dot",
    "full": "--coverage"
  },
  "createdAt": "[ISO8601]"
}
```

Copiar UI templates a `.stania/`:
- `.stania/ui-standards.md` ← desde templates/ui-standards.md (o inline)
- `.stania/layout-catalog.md` ← desde templates/layout-catalog.md (o inline)
- `.stania/ui-specs/` ← crear directorio vacío

Crear `.stania/ui-specs/_TEMPLATE.md` desde templates/ui-spec-template.md.
El frontend copia este template para cada nuevo componente.

## Paso 5: Montar estructura

### Si es monorepo (frontend + backend separado):

```
project/
├── apps/
│   ├── web/                  ← Next.js 15 (Vercel)
│   │   ├── src/
│   │   │   ├── app/          ← App Router
│   │   │   ├── components/
│   │   │   └── lib/
│   │   ├── next.config.ts
│   │   └── package.json
│   └── api/                  ← Backend (Cloud Run)
│       ├── src/
│       │   ├── domain/
│       │   ├── application/
│       │   ├── infrastructure/
│       │   └── main.ts
│       ├── Dockerfile
│       └── package.json
├── packages/
│   └── contracts/            ← Fuente de verdad compartida
│       ├── index.ts
│       └── generated/
│           ├── mocks/
│           ├── client/
│           └── ports/
├── turbo.json
├── pnpm-workspace.yaml
├── biome.json
├── .github/workflows/
│   ├── ci.yml
│   └── deploy.yml
└── .stania/
```

### Si es full-stack Next.js (simple):

```
project/
├── src/
│   ├── app/
│   │   ├── api/              ← API routes
│   │   └── (pages)/
│   ├── components/
│   ├── lib/
│   └── domain/              ← Si usa DDD
├── contracts/
│   └── generated/
├── .github/workflows/ci.yml
└── .stania/
```

## Paso 6: Tooling

Configurar:
- `pnpm-workspace.yaml` (monorepo)
- `turbo.json` con: build, dev, test, lint, typecheck
- `biome.json` (reemplaza eslint + prettier)
- `tsconfig.json` con strict: true, noUncheckedIndexedAccess: true
- `vitest.config.ts` por app
- `.npmrc` con `shamefully-hoist=false`

Instalar dependencias base:
```bash
pnpm add -D typescript @types/node vitest @biomejs/biome turbo
pnpm add -D msw @storybook/react --filter web
pnpm add -D @testing-library/react @testing-library/user-event vitest-axe --filter web
pnpm add -D @tanstack/react-query --filter web
pnpm add zod --filter web --filter api
```

## Paso 7: CI/CD

Crear `.github/workflows/ci.yml`:
```yaml
name: CI
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm typecheck
      - run: pnpm lint
      - run: pnpm test --bail

  lighthouse:
    runs-on: ubuntu-latest
    needs: check
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm build --filter web
      - uses: treosh/lighthouse-ci-action@v12
        with:
          configPath: ./lighthouserc.json
          uploadArtifacts: true
```

Crear `lighthouserc.json` en la raiz:
```json
{
  "ci": {
    "collect": {
      "startServerCommand": "pnpm --filter web start",
      "url": ["http://localhost:3000"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "categories:accessibility": ["error", { "minScore": 0.95 }],
        "categories:best-practices": ["error", { "minScore": 0.9 }]
      }
    }
  }
}
```

Crear `.github/workflows/deploy.yml`:
```yaml
name: Deploy
on:
  push: { branches: [main] }
jobs:
  deploy-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'

  deploy-api:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      - uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: ${{ github.event.repository.name }}-api
          source: apps/api
          region: us-central1
```

## Paso 8: Deploy setup

### Vercel (frontend):
```bash
cd apps/web && npx vercel link 2>/dev/null && cd ../..
```
Si no tiene vercel CLI: "Instala vercel: pnpm add -g vercel && vercel login"

### Cloud Run (backend):
Verificar Dockerfile en apps/api/:
```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:22-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 8080
CMD ["node", "dist/main.js"]
```

## Paso 9: GitHub Labels

```bash
gh label create "agent" --color "0E8A16" --description "For autonomous agent implementation"
gh label create "frontend" --color "1D76DB" --description "Frontend task"
gh label create "backend" --color "D93F0B" --description "Backend task"
gh label create "needs-decision" --color "FBCA04" --description "Blocked - needs human decision"
gh label create "ready-to-review" --color "7057FF" --description "PR ready for review"
gh label create "contract" --color "006B75" --description "API contract definition"
```

## Paso 10: Verificacion + Commit

```bash
pnpm install
pnpm typecheck 2>&1 | tail -5
pnpm lint 2>&1 | tail -5
git add .
git commit -m "chore: project bootstrap with stania"
git push
```

## Paso 11: Reporte

```
=== BOOTSTRAP COMPLETE ===
Repo:     github.com/<owner>/<name> (private)
Frontend: Vercel (connected)
Backend:  Cloud Run (Dockerfile ready)
CI/CD:    GitHub Actions (ci.yml + deploy.yml)
Labels:   6 created
Board:    GitHub Projects created

NEXT STEPS:
  1. /st-model — Define domain model (if DDD)
  2. /st-contract <first-feature> — Define first API contract
  3. Add secrets to GitHub: VERCEL_TOKEN, GCP_SA_KEY
```
