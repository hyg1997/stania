Dependency health management. Audita seguridad, detecta paquetes desactualizados,
y clasifica updates por riesgo. Funciona con pnpm o npm (detectar automaticamente).

## Modos

- Sin flags: health check completo (audit + outdated + clasificacion)
- `--fix`: actualizar CRITICAL + SAFE automaticamente y correr tests
- `--audit`: solo auditoria de seguridad

## Paso 1: Detectar package manager

```bash
if [ -f pnpm-lock.yaml ]; then PM="pnpm"; elif [ -f package-lock.json ]; then PM="npm"; fi
```

Si no hay lockfile → reportar "No package manager detected" y salir.

## Paso 2: Security audit

```bash
$PM audit --json 2>&1 | tail -50
```

Parsear vulnerabilidades. Clasificar como CRITICAL:
- Cualquier severidad "high" o "critical"
- Incluir CVE ID si disponible
- Incluir paquete afectado y version vulnerable

Si `--audit` flag → reportar y salir aqui.

## Paso 3: Outdated packages

```bash
$PM outdated --json 2>&1 | tail -80
```

Parsear resultado y clasificar cada paquete:

### Clasificacion

- **CRITICAL**: tiene vulnerabilidad de seguridad conocida → update inmediato
- **SAFE**: patch o minor update sin breaking changes (1.2.3 → 1.2.5, 1.2.3 → 1.3.0)
- **RISKY**: major update (1.x → 2.x, react 18 → 19, next 14 → 15)

## Paso 4: Bundle impact (solo RISKY)

Para cada dependencia RISKY, evaluar impacto:

```bash
# Tamano del paquete en node_modules
du -sh node_modules/<pkg> 2>/dev/null | tail -1
# Cuantos archivos lo importan
grep -rn "from ['\"]<pkg>" src/ apps/ 2>/dev/null | wc -l
```

Reportar dependencias con alto acoplamiento (>10 imports) como mayor riesgo.

## Paso 5: Reporte

```
DEPENDENCY HEALTH:
  CRITICAL (2): lodash (CVE-...), axios (CVE-...)
  OUTDATED (5): react 18->19, next 14->15, ...
  SAFE (12): patch updates available

Action: /st-deps --fix to update 14 safe packages
```

## Paso 6: Acciones (solo con --fix)

### CRITICAL updates

```bash
$PM update <pkg1> <pkg2> ... 2>&1 | tail -5
```

Despues de actualizar, correr tests para verificar:

```bash
$PM test --bail 2>&1 | tail -10
```

Si tests fallan → revertir con `git checkout -- package.json pnpm-lock.yaml`
y reportar al usuario.

### SAFE updates

Actualizar todos juntos:

```bash
$PM update <safe-pkg1> <safe-pkg2> ... 2>&1 | tail -5
```

Correr tests:

```bash
$PM test --bail 2>&1 | tail -10
```

Si tests pasan → ofrecer crear commit:
"Updated X safe dependencies (patch/minor)"

Si tests fallan → bisect: actualizar de a uno para encontrar cual rompe.
Revertir el que falla, reportar al usuario.

### RISKY updates

NO actualizar automaticamente. Para cada uno, reportar:

```
RISKY: react 18.2.0 -> 19.0.0
  - Breaking changes: concurrent mode default, removed legacy APIs
  - Imports affected: 47 files
  - Recommendation: Create dedicated branch + PR
```

Si el usuario confirma, crear branch individual:

```bash
git checkout -b deps/update-<pkg>-<version>
$PM install <pkg>@<version> 2>&1 | tail -5
$PM test --bail 2>&1 | tail -10
```

Si pasan tests → commit + push + PR con `gh pr create`.
Si fallan → reportar que necesita intervencion manual.

## Truncado de output

SIEMPRE truncar output de comandos con `| tail -N` para evitar context explosion.
Valores por defecto:
- audit: `| tail -50`
- outdated: `| tail -80`
- install/update: `| tail -5`
- test: `| tail -10`

## Degradacion graceful

- Si `$PM audit` no soporta `--json` → correr sin flag y parsear texto
- Si no hay tests configurados → skip validacion post-update, advertir al usuario
- Si `gh` no esta instalado → skip creacion de PR, sugerir manual
- Si no hay vulnerabilidades ni outdated → reportar "All dependencies healthy"
