Trace all files that need changes for a cross-cutting feature. Shows the full stack path.

## Usage

`/st-trace <feature-name>`

Example: `/st-trace log_meal`, `/st-trace create_routine`, `/st-trace new-endpoint`

## Steps

1. Detect architecture from `.stania/config.json`. If `architecture: "clean"`, use layered trace.

2. Search for the feature across all layers:
```bash
# Contract
grep -rln "<feature>" packages/contracts/src/ 2>/dev/null
# Domain
grep -rln "<feature>" apps/api/src/domain/ 2>/dev/null
# Application (use cases)
grep -rln "<feature>" apps/api/src/application/ 2>/dev/null
# Infrastructure (routes, repos, providers)
grep -rln "<feature>" apps/api/src/infrastructure/ 2>/dev/null
# Frontend queries
grep -rln "<feature>" apps/web/src/lib/ 2>/dev/null
# Frontend UI
grep -rln "<feature>" apps/web/src/app/ apps/web/src/components/ 2>/dev/null
# Tests
grep -rln "<feature>" apps/api/src/__tests__/ apps/web/e2e/ 2>/dev/null
```

3. Report as a stack trace:
```
=== TRACE: log_meal ===

CONTRACT   packages/contracts/src/log-meal.ts
DOMAIN     apps/api/src/domain/nutrition/daily-log.ts
           apps/api/src/domain/nutrition/meal.ts
APPLICATION apps/api/src/application/advisor/apply-action.ts
ROUTES     apps/api/src/infrastructure/http/nutrition-routes.ts
           apps/api/src/infrastructure/http/advisor-routes.ts
PERSISTENCE apps/api/src/infrastructure/persistence/pg-daily-log-repository.ts
AI PROMPT  apps/api/src/infrastructure/ai/gemini-ai-provider.ts
QUERIES    apps/web/src/lib/queries/nutrition-queries.ts
           apps/web/src/lib/queries/advisor-queries.ts
UI         apps/web/src/app/nutrition/page.tsx
           apps/web/src/app/advisor/page.tsx
TESTS      apps/api/src/__tests__/nutrition-routes.test.ts

Total: 12 files across 8 layers
```

4. If `--new` flag: show template of files that WOULD need to be created/modified for a new feature of that type, based on existing patterns.

## Rules

- Only search, never modify files
- Group by layer, not alphabetically
- If a layer has 0 matches, omit it
- Max 5 seconds execution
