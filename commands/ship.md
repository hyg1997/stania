Auditoria pre-deploy / pre-PR. Solo correr cuando el usuario esta listo para deploy o PR.

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

## Paso 2: Pipeline completo

Correr todo lo de /check pero mas estricto:

### Validacion
- Typecheck (zero errors, zero warnings)
- Lint (zero errors, warnings aceptables solo si son pre-existentes)
- ALL tests (run completo, no watch)
- Build (debe compilar sin errores)

### Hardening
- Architecture enforcement
- AI Code Smells (todos los archivos modificados, no solo sesion)
- Security scan completo
- Dependency audit

### Coverage
```bash
pnpm test -- --coverage  # o equivalente
```
Reportar coverage por capa:
- Domain: target >80%
- Application: target >60%
- Overall: target >60%

Leer targets de `.stania/config.json` si existe (hardening.coverageTarget).

## Paso 3: Mutation testing (si aplica)

Si hay tests de domain y el usuario tiene stryker/mutmut instalado:
```bash
pnpm test:mutate  # o equivalente
```

Reportar mutation score. Si <80% en domain → WARNING.
Leer threshold de `.stania/config.json` si existe.

Si la herramienta no esta instalada, reportar "skipped" — no bloquear.

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
