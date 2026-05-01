Mutation testing: verifica que tus tests realmente detectan bugs.
Solo correr bajo demanda o antes de deploy, NO en cada commit.

## Como funciona

```
Tu codigo:    if (price > 0) return ok
Mutante:      if (price >= 0) return ok   <- cambio sutil
Si tu test NO falla -> test debil (mutante sobrevivio)
Si tu test SI falla -> test fuerte (mutante murio)
```

Target: >80% mutantes muertos en domain layer.

## Deteccion de stack

Detectar que herramienta usar:

### TypeScript (Stryker)
Si existe package.json y hay tests con vitest/jest:
```bash
# Si no esta instalado
pnpm add -D @stryker-mutator/core @stryker-mutator/vitest-runner @stryker-mutator/typescript-checker

# Configurar si no existe stryker.config.json
# Limitar a domain layer para velocidad
pnpm dlx stryker run --mutate "src/domain/**/*.ts,apps/*/src/domain/**/*.ts"
```

### Python (mutmut)
Si existe pyproject.toml o setup.py:
```bash
pip install mutmut  # si no esta instalado
mutmut run --paths-to-mutate src/domain/
mutmut results
```

### Go
```bash
go install github.com/zimmski/go-mutesting/cmd/go-mutesting@latest
go-mutesting ./domain/...
```

## Reporte

Para cada mutante sobreviviente:
1. Mostrar la mutacion exacta (que linea cambio y como)
2. Explicar por que ningun test lo detecto
3. Sugerir un test especifico que lo mataria

Formato:
```
=== MUTATION TESTING REPORT ===
Total mutants:     42
Killed:            36 (86%)
Survived:          6 (14%)
Score:             86% (target: >80%) ✅

SURVIVING MUTANTS:
1. src/domain/appointment.ts:23
   - price > 0  →  price >= 0
   - Missing test: "should reject zero price"

2. src/domain/appointment.ts:45
   - status === 'confirmed'  →  status !== 'confirmed'
   - Missing test: "should not complete unconfirmed appointment"
```
