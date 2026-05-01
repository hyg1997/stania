Checklist pre-deploy / pre-PR. Auditoria completa antes de enviar a produccion.
Solo correr cuando el usuario dice "estoy listo para deploy" o "quiero hacer PR".

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
- ALL tests (no --watch, run completo)
- Build (debe compilar sin errores)

### Hardening
- Architecture enforcement
- AI Code Smells (todos los archivos modificados, no solo sesion)
- Security scan completo
- Dependency audit

### Coverage
```bash
pnpm test -- --coverage
```
Reportar coverage por capa:
- Domain: target >80%
- Application: target >60%
- Infrastructure: target >40%
- Overall: target >60%

## Paso 3: Mutation testing (si hay tests de domain)

```bash
pnpm test:mutate  # Stryker
```

Reportar mutation score. Si <70% en domain → WARNING.

## Paso 4: Checklist manual

Presentar al usuario para que confirme:

```
[ ] Feature funciona end-to-end (probado en browser/terminal)
[ ] Edge cases probados manualmente
[ ] No hay console.log / print de debug
[ ] No hay TODOs criticos sin resolver
[ ] Variables de entorno documentadas si hay nuevas
[ ] Migraciones de DB incluidas si hay cambios de schema
[ ] README/docs actualizados si la API cambio
```

## Paso 5: PR o Deploy

Si el usuario quiere PR:
- Sugerir titulo (corto, <70 chars)
- Generar body con: Summary (3 bullets), cambios clave, test plan
- `gh pr create`

Si el usuario quiere deploy directo:
- Confirmar que CI/CD esta configurado
- `git push origin <branch>`

## Reporte final

```
=== SHIP READINESS ===
Pipeline:      ✅ All green
Coverage:      ✅ Domain 85%, Overall 67%
Mutations:     ✅ 82% killed
Security:      ✅ No issues
Architecture:  ✅ Clean layers

VERDICT: Ready to ship ✅
```
