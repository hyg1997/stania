Pipeline de validacion + hardening. Etapa 3 del pipeline.
Corre despues de /build o antes de commit. Actualiza `.stania/progress.json` con resultado.

## Fase 1: Validacion automatizada

Detectar stack (de `.stania/config.json` o del filesystem) y correr:

### TypeScript
```bash
pnpm typecheck 2>&1      # tsc --strict --noEmit
pnpm lint 2>&1            # Biome check
pnpm test 2>&1            # Vitest
```

### Python
```bash
mypy . 2>&1               # Type checking
ruff check . 2>&1         # Lint
pytest 2>&1               # Tests
```

### Go
```bash
go vet ./... 2>&1
golangci-lint run 2>&1
go test ./... 2>&1
```

### Rust
```bash
cargo clippy 2>&1
cargo test 2>&1
```

Si no hay scripts configurados, inferir del package.json / pyproject.toml.
Si no hay tooling → reportar como gap critico.

Reportar resultado por etapa:
```
Typecheck:  PASS (0 errors)
Lint:       WARN (2 warnings, non-blocking)
Tests:      PASS (14 passed, 0 failed)
```

Si hay errores → arreglar automaticamente y re-correr.
Si no puede arreglar → reportar al usuario con contexto.

## Fase 2: Hardening

### 2.1 Architecture enforcement

Verificar que las capas no se violan:

```bash
# Domain no debe importar de infrastructure o application
grep -rn "from.*infrastructure" src/domain/ apps/*/src/domain/ 2>/dev/null
grep -rn "from.*application" src/domain/ apps/*/src/domain/ 2>/dev/null

# Application no debe importar de infrastructure directamente
grep -rn "from.*infrastructure" src/application/ apps/*/src/application/ 2>/dev/null
```

Adaptar paths al proyecto. Si no usa Clean Architecture, saltar.

### 2.2 AI Code Smells

Revisar archivos modificados (git diff --name-only):

1. **API Hallucination**: metodos de librerias externas existen realmente?
   Si hay duda, buscar en node_modules o tipos.
2. **Happy Path Bias**: hay manejo para cada error del Result?
   Hay fallback si un servicio externo falla?
3. **Invisible Coupling**: domain importa algo que no deberia?
4. **Security Blindness**: datos de usuario sin sanitizar? PII en logs?
   Endpoints sin auth?
5. **Test Theater**: los tests verifican RESULTADO correcto,
   no solo que "no tira error"? Hay assertions reales?
6. **Over-engineering**: abstracciones que solo tienen una implementacion
   y no la necesitan todavia?
7. **Context Amnesia**: patrones inconsistentes entre modulos?
8. **Stale Patterns**: APIs deprecated? Metodos obsoletos?

### 2.3 Security quick scan

```bash
# Secrets en codigo
grep -rn "sk-\|api_key\|password\s*=\s*[\"']" --include="*.ts" --include="*.py" --include="*.env" . 2>/dev/null

# Dependencias con vulnerabilidades (si la herramienta existe)
pnpm audit 2>/dev/null || npm audit 2>/dev/null
pip audit 2>/dev/null
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
