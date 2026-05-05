Fast path para cambios simples (T1/T2). Salta spec, salta approval gates.
Validar → arreglar → commit. Para cuando la ceremonia completa no vale la pena.

## Cuando usar

- Fix de bugs
- Config changes
- CSS/UI cosmetic
- Dependency bumps
- Refactors sin cambio de contrato
- Cualquier cosa que NO toque domain logic ni seguridad

Si toca domain layer o seguridad → rechazar: "Esto necesita /st-spec + /st-build."

## Proceso

### 1. Verificar que es T1/T2

Leer los archivos modificados (o escuchar al usuario).
Si algun archivo esta en `domain/` o toca auth/payments/billing → STOP.

### 2. Implementar el cambio

Generar codigo directamente. Sin spec formal, sin approval gates por capa.
Aplicar las mismas reglas de calidad (no happy path bias, no hallucination).

### 3. Validar

Detectar stack y correr:
```bash
# TypeScript
pnpm typecheck 2>&1 | tail -5
pnpm lint 2>&1 | tail -5
pnpm test -- --reporter=dot --bail 2>&1 | tail -10

# Python
mypy . 2>&1 | tail -5
ruff check . 2>&1 | tail -5
pytest -x -q 2>&1 | tail -10

# Go
go vet ./... 2>&1 | tail -5
go test ./... -count=1 -short 2>&1 | tail -10
```

Si falla → arreglar y re-correr. Maximo 2 intentos, despues reportar al usuario.

### 4. Commit

Si todo pasa:
```bash
git add [archivos relevantes]
git commit -m "[tipo]: [descripcion concisa]"
```

Tipos: fix, style, refactor, chore, docs, test

## Reporte

```
[QUICK] fix: handle null avatar in profile card
  Files: src/components/ProfileCard.tsx, src/components/ProfileCard.test.tsx
  Pipeline: PASS (typecheck ✓, lint ✓, tests 14/14 ✓)
```

## Mode-aware behavior

In solo mode (`config.json` → `mode: "solo"`):
- Skip PR creation — commit directly
- Skip issue reference — just commit with descriptive message
- Still run validation (typecheck + lint + tests)

In team mode: keep existing behavior (PR if on feature branch).

## Reglas

- NUNCA usar /st-quick para domain logic, security, o billing
- Si durante la implementacion descubres que es mas complejo de lo esperado → STOP: "Esto merece /st-spec"
- No actualizar progress.json (estos cambios no son features tracked)
- No crear spec (el commit message es suficiente documentacion)
- Output del pipeline: solo ultimas lineas (tail). No volcar output completo.
