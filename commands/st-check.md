Pipeline de validacion + hardening. Etapa 3 del pipeline.
Corre despues de /st-build o antes de commit. Actualiza `.stania/progress.json` con resultado.

## Fase 1: Validacion automatizada (PARALELA)

Detectar stack (de `.stania/config.json` o del filesystem).
Leer `.stania/config.json` campo `testFlags` si existe para override de flags.

**Correr typecheck, lint, y tests en PARALELO** (3 tool calls simultaneos).
Truncar output siempre — solo leer ultimas lineas para evitar context explosion.

### TypeScript
```bash
# En paralelo:
pnpm typecheck 2>&1 | tail -5
pnpm lint 2>&1 | tail -5
pnpm test --bail --reporter=dot 2>&1 | tail -10
```

### Python
```bash
# En paralelo:
mypy . 2>&1 | tail -5
ruff check . 2>&1 | tail -5
pytest -x -q 2>&1 | tail -10
```

### Go
```bash
# En paralelo:
go vet ./... 2>&1 | tail -5
golangci-lint run 2>&1 | tail -5
go test ./... -count=1 -short 2>&1 | tail -10
```

### Rust
```bash
# En paralelo:
cargo clippy 2>&1 | tail -5
cargo test 2>&1 | tail -10
```

Si no hay scripts configurados, inferir del package.json / pyproject.toml.
Si no hay tooling → reportar como gap critico.

Reportar resultado por etapa:
```
Typecheck:  PASS (0 errors)
Lint:       WARN (2 warnings, non-blocking)
Tests:      PASS (14 passed, 0 failed)
```

Si hay errores → leer output completo SOLO del paso fallido, arreglar y re-correr.
Si no puede arreglar → reportar al usuario con contexto.
Maximo 2 intentos de autofix por paso.

## Fase 2: Hardening

### 2.1 Architecture enforcement

Solo si architecture = "clean". Saltar para mvc/simple.

```bash
# Domain no debe importar de infrastructure o application
grep -rn "from.*infrastructure" src/domain/ apps/*/src/domain/ 2>/dev/null
grep -rn "from.*application" src/domain/ apps/*/src/domain/ 2>/dev/null
```

### 2.2 AI Code Smells

Revisar SOLO archivos modificados (git diff --name-only HEAD~1):

1. **API Hallucination**: Si hay Context7 MCP disponible, verificar metodos
   contra documentacion real. Si no, buscar en node_modules/tipos.
2. **Happy Path Bias**: hay manejo para cada error del Result?
3. **Invisible Coupling**: domain importa algo que no deberia?
4. **Security Blindness**: datos de usuario sin sanitizar? PII en logs?
5. **Test Theater**: los tests verifican RESULTADO, no solo "no tira error"?
6. **Over-engineering**: abstracciones con una sola implementacion?
7. **Context Amnesia**: patrones inconsistentes?
8. **Stale Patterns**: APIs deprecated?

### 2.3 Security quick scan

```bash
grep -rn "sk-\|api_key\|password\s*=\s*[\"']" --include="*.ts" --include="*.py" --include="*.env" . 2>/dev/null | head -5
pnpm audit --json 2>/dev/null | tail -3 || pip audit 2>/dev/null | tail -3
```

No fallar si la herramienta no esta instalada — reportar como "skipped".

## Reporte final

```
=== VALIDATION ===
Typecheck:     PASS
Lint:          PASS
Tests:         PASS (14/14)

=== HARDENING ===
Architecture:  PASS (no layer violations)
AI Smells:     WARN (1 finding: happy path bias in X handler)
Security:      PASS (no secrets, no vulns)

=== VERDICT ===
[PASS] Ready for commit
[WARN] 1 non-blocking finding — fix now or next session
[FAIL] X blocking issues — must fix before commit
```

## Actualizar estado

Si `.stania/progress.json` existe, actualizar lastCheck de los aggregates afectados:
```json
{ "lastCheck": "[ISO8601]" }
```

## Acciones segun veredicto

- **PASS** → "Listo para commit. Queres que commitee?"
- **WARN** → mostrar findings, preguntar si procede o arregla
- **FAIL** → arreglar automaticamente si puede, sino reportar

## Session splitting

Si el contexto de la conversacion ya tiene mucho output acumulado
(por ejemplo, despues de /st-build con multiples iteraciones):
Sugerir al usuario: "La sesion tiene mucho contexto acumulado. Quieres
que haga el commit y continues en una nueva sesion con /st-ship?"
