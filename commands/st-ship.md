Auditoria pre-deploy / pre-PR. Solo correr cuando el usuario esta listo para deploy o PR.

## Mode Detection

Read `.stania/config.json` → `mode` field.

## Paso 1: Estado del repo

```bash
git status
git log --oneline -10
git diff --stat main...HEAD  # o la branch base
```

Reportar:
- Branch actual
- Commits desde main
- Archivos modificados
- Hay cambios sin commitear?

## Paso 2: Validacion (incremental)

Leer `.stania/progress.json` → lastCheck timestamp.
Si lastCheck < 10 minutos → skip pipeline, reportar "Validated recently, skipping re-run."
Si lastCheck > 10 minutos o no existe → correr pipeline completo:

### Solo si necesita re-validar:
```bash
# Validacion estricta
pnpm typecheck 2>&1 | tail -5
pnpm lint 2>&1 | tail -5
pnpm test --bail 2>&1 | tail -10
pnpm build 2>&1 | tail -5

# Coverage
pnpm test -- --coverage 2>&1 | grep -E "^(All files|Statements|Branches|Functions|Lines)" | head -5
```

Reportar coverage vs targets de `.stania/config.json` (hardening.coverageTarget):
- Domain: target >80%
- Application: target >60%
- Overall: target >60%

### Hardening (siempre correr):
- Architecture enforcement (solo archivos en el diff)
- AI Code Smells (archivos modificados desde main)
- Security: `grep -rn "sk-\|api_key\|password\s*=" --include="*.ts" --include="*.py" . 2>/dev/null | head -5`
- Dependency audit: `pnpm audit 2>/dev/null | tail -5`

## Paso 3: Mutation testing (si aplica)

Si hay tests de domain y el usuario tiene stryker/mutmut instalado:
```bash
pnpm test:mutate  # o equivalente
```

Reportar mutation score. Si <80% en domain → WARNING.
Leer threshold de `.stania/config.json` → `hardening.mutationThreshold` si existe.

Si la herramienta no esta instalada, reportar "skipped" — no bloquear.

## Paso 3.5: API schema validation (Schemathesis)

If backend has OpenAPI spec and `schemathesis` is installed:
```bash
if command -v schemathesis &>/dev/null; then
  schemathesis run http://localhost:<port>/openapi.json --checks all --max-response-time 2000 --hypothesis-max-examples 50 2>&1 | tail -15
fi
```

Reports: schema violations, response time issues, unexpected status codes.
Skip silently if not installed.

## Paso 3.6: Contract vs implementation validation

If `.stania/domain-model.json` and `packages/contracts/` exist:
```bash
for contract in packages/contracts/*.ts; do
  name=$(basename "$contract" .ts)
  # Check handler exists
  grep -rn "class.*${name}.*Handler" apps/api/src/ 2>/dev/null | head -1
  # Check route exists
  grep -rn "${name}\|$(echo $name | tr '[:upper:]' '[:lower:]')" apps/api/src/**/routes* 2>/dev/null | head -1
done
```

Flag any contract without matching handler or route as WARNING.

## Paso 4: Checklist manual

Presentar al usuario para que confirme:

```
[ ] Feature funciona end-to-end (probado manualmente)
[ ] Edge cases probados
[ ] No hay console.log / print de debug
[ ] No hay TODOs criticos sin resolver
[ ] Variables de entorno documentadas si hay nuevas
[ ] Migraciones de DB incluidas si hay cambios de schema
[ ] Docs actualizados si la API cambio
```

## Paso 5: PR o Deploy

### Si mode = "solo"

Skip PR creation entirely. Solo flow:
1. Run audit (validation + hardening) — same as team
2. Commit all changes with descriptive message
3. Push to main directly (ask user first: "Push to main?")
4. No PR body generation, no gh pr create

The audit steps (Paso 1-4) remain the same for both modes.
The manual checklist (Paso 4) becomes shorter in solo:

Solo checklist:
[ ] Feature works (tested manually)
[ ] No console.log / debug prints
[ ] No TODOs without resolution

### Si mode = "team" (default)

Si el usuario quiere PR:
- Sugerir titulo (corto, <70 chars)
- Generar body con: Summary, cambios clave, test plan
- `gh pr create`

Si quiere deploy directo:
- Confirmar que CI/CD esta configurado
- `git push origin <branch>`

## Reporte final

```
=== SHIP READINESS ===
Pipeline:      PASS
Coverage:      PASS (Domain 85%, Overall 67%)
Mutations:     PASS (82% killed) | SKIPPED
Security:      PASS
Architecture:  PASS

VERDICT: Ready to ship
```

## Actualizar estado

Si `.stania/progress.json` existe, marcar aggregates relevantes con status "done".
