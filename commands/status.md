Muestra el estado de implementacion del proyecto por bounded context y aggregate.
Util para saber donde retomar trabajo entre sesiones.

## Que hace

Escanea el codebase y reporta el estado de cada pieza del dominio.

## Paso 1: Detectar modelo

Buscar bounded contexts definidos en:
1. CLAUDE.md (seccion de bounded contexts)
2. docs/02-architecture.md
3. Estructura de directorios (src/domain/*, apps/*/src/domain/*)

Si no encuentra modelo definido:
"No encuentro bounded contexts definidos. Corre /model primero."

## Paso 2: Escanear implementacion

Para cada bounded context y aggregate, verificar:

### Domain Layer
```bash
# Buscar archivos de aggregate/entity
find . -path "*/domain/*" -name "*.ts" -o -name "*.py" | head -50

# Buscar value objects
find . -path "*/domain/value-objects/*" -o -path "*/domain/*vo*" | head -20

# Buscar eventos
find . -path "*/domain/events/*" -o -path "*/domain/*event*" | head -20

# Buscar ports/interfaces
find . -path "*/domain/ports/*" -o -path "*/domain/*port*" -o -path "*/domain/*repository*" | head -20
```

### Application Layer
```bash
find . -path "*/application/*" -name "*.ts" -o -path "*/application/*" -name "*.py" | head -30
```

### Infrastructure Layer
```bash
find . -path "*/infrastructure/*" -name "*.ts" -o -path "*/infrastructure/*" -name "*.py" | head -30
```

### Tests
```bash
find . -path "*/tests/*" -o -path "*test*" -o -path "*spec*" | grep -v node_modules | head -30
```

## Paso 3: Reportar

Formato:

```
=== PROJECT STATUS ===

Bounded Context: [nombre]
┌──────────────┬────────┬───────┬───────┬───────┐
│ Aggregate    │ Domain │ App   │ Infra │ Tests │
├──────────────┼────────┼───────┼───────┼───────┤
│ Appointment  │ ✅     │ ✅    │ ⬜    │ ✅    │
│ Tenant       │ ✅     │ ✅    │ ✅    │ ✅    │
│ VoiceSession │ ⬜     │ ⬜    │ ⬜    │ ⬜    │
└──────────────┴────────┴───────┴───────┴───────┘

Bounded Context: [nombre]
┌──────────────┬────────┬───────┬───────┬───────┐
│ Aggregate    │ Domain │ App   │ Infra │ Tests │
├──────────────┼────────┼───────┼───────┼───────┤
│ ...          │        │       │       │       │
└──────────────┴────────┴───────┴───────┴───────┘

Overall: 4/12 aggregates complete (33%)

NEXT STEP: /spec → VoiceSession aggregate (first incomplete)
```

## Paso 4: Sugerir siguiente accion

Basado en el estado:
- Si hay aggregates sin domain → "/spec para [aggregate]"
- Si hay domain sin app → "/build para [aggregate] (ya tiene domain)"
- Si hay app sin infra → "/build para [aggregate] (falta infra)"
- Si hay todo sin tests → "Faltan tests para [aggregate]"
- Si todo esta completo → "/check para validar, despues /ship"
