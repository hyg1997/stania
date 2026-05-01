Pipeline de validacion + hardening combinado. Etapas 3-4.
Corre despues de /build o antes de commit.

## Fase 1: Validacion automatizada

Detectar stack del proyecto y correr lo que aplique:

### TypeScript
```bash
pnpm typecheck 2>&1      # tsc --strict --noEmit
pnpm lint 2>&1            # Biome check
pnpm test 2>&1            # Vitest
```

### Python
```bash
mypy apps/agent 2>&1      # Type checking
ruff check apps/agent 2>&1 # Lint
pytest apps/agent 2>&1     # Tests
```

### Otros (detectar)
- Go: `go vet && golangci-lint run && go test ./...`
- Rust: `cargo clippy && cargo test`

Si no hay scripts configurados, intentar inferir del package.json / pyproject.toml.
Si no hay tooling → reportar como gap critico.

Reportar resultado por etapa:
```
Typecheck:  ✅ passed (0 errors)
Lint:       ⚠️ 2 warnings (non-blocking)
Tests:      ✅ 14 passed, 0 failed
```

Si hay errores → arreglar automaticamente y re-correr.
Si no puede arreglar → reportar al usuario con contexto.

## Fase 2: Hardening

### 2.1 Architecture enforcement

Verificar que las capas no se violan. Buscar imports prohibidos:

```bash
# Domain no debe importar de infrastructure o application
grep -rn "from.*infrastructure" src/domain/ apps/*/src/domain/ 2>/dev/null
grep -rn "from.*application" src/domain/ apps/*/src/domain/ 2>/dev/null

# Application no debe importar de infrastructure directamente
grep -rn "from.*infrastructure" src/application/ apps/*/src/application/ 2>/dev/null
```

### 2.2 AI Code Smells

Revisar archivos modificados en la sesion actual (git diff --name-only):

1. **API Hallucination**: verificar que metodos de librerias externas
   realmente existen. Si hay duda, buscar en node_modules o docs.
2. **Happy Path Bias**: hay manejo para cada error del Result?
   Hay fallback si un servicio externo falla?
3. **Invisible Coupling**: domain importa algo que no deberia?
4. **Security Blindness**: datos de usuario sin sanitizar? PII en logs?
   tenant_id sin validar? endpoints sin auth?
5. **Test Theater**: los tests verifican el RESULTADO correcto,
   no solo que "no tira error"?
6. **Over-engineering**: hay abstracciones que solo tienen una
   implementacion y no la necesitan todavia?

### 2.3 Security quick scan

```bash
# Secrets en codigo
grep -rn "sk-\|api_key\|password\s*=\s*[\"']" --include="*.ts" --include="*.py" --include="*.env" . 2>/dev/null

# Dependencias con vulns
pnpm audit 2>/dev/null || npm audit 2>/dev/null
pip audit 2>/dev/null
```

## Reporte final

```
=== VALIDATION ===
Typecheck:     ✅
Lint:          ✅
Tests:         ✅ (14/14)

=== HARDENING ===
Architecture:  ✅ No layer violations
AI Smells:     ⚠️ 1 finding (happy path bias in X handler)
Security:      ✅ No secrets, no vulns

=== VERDICT ===
[PASS] Ready for commit
[WARN] 1 non-blocking finding — fix now or next session
[FAIL] X blocking issues — must fix before commit
```

Si PASS → "Listo para commit. Queres que commitee?"
Si WARN → mostrar findings, preguntar si procede o arregla
Si FAIL → arreglar automaticamente si puede, sino reportar
