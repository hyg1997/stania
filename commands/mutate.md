Mutation testing: verifica que tus tests realmente detectan bugs.
Solo bajo demanda o antes de deploy — NO en cada commit.

## Como funciona

```
Tu codigo:    if (price > 0) return ok
Mutante:      if (price >= 0) return ok   ← cambio sutil
Si tu test NO falla → test debil (mutante sobrevivio)
Si tu test SI falla → test fuerte (mutante murio)
```

Target: >80% mutantes muertos en domain layer.
Leer threshold de `.stania/config.json` si existe (hardening.mutationThreshold).

## Deteccion de stack

Detectar herramienta de `.stania/config.json` o del filesystem:

### TypeScript (Stryker)
```bash
# Instalar si no esta
pnpm add -D @stryker-mutator/core @stryker-mutator/vitest-runner @stryker-mutator/typescript-checker

# Limitar a domain layer
pnpm dlx stryker run --mutate "src/domain/**/*.ts,apps/*/src/domain/**/*.ts"
```

### Python (mutmut)
```bash
pip install mutmut
mutmut run --paths-to-mutate src/domain/
mutmut results
```

### Go
```bash
go install github.com/zimmski/go-mutesting/cmd/go-mutesting@latest
go-mutesting ./domain/...
```

Si la herramienta no esta instalada, preguntar si quiere instalarla.
No fallar silenciosamente — informar que falta.

## Reporte

Para cada mutante sobreviviente:
1. Mostrar la mutacion exacta (linea, cambio)
2. Explicar por que ningun test lo detecto
3. Sugerir un test especifico que lo mataria

```
=== MUTATION TESTING ===
Total mutants:     42
Killed:            36 (86%)
Survived:          6 (14%)
Score:             86% (target: >80%) PASS

SURVIVING MUTANTS:
1. src/domain/appointment.ts:23
   - price > 0  →  price >= 0
   - Missing test: "should reject zero price"

2. src/domain/appointment.ts:45
   - status === 'confirmed'  →  status !== 'confirmed'
   - Missing test: "should not complete unconfirmed appointment"
```

## Post-reporte

Preguntar: "Quieres que genere los tests para matar los mutantes sobrevivientes?"
Si dice si → generar tests, correr mutation de nuevo, reportar nuevo score.
