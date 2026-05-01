Muestra el estado de implementacion del proyecto. Lee `.stania/progress.json` primero,
con fallback a escaneo del filesystem. Util para retomar trabajo entre sesiones.

## Paso 1: Leer estado

### Fuente primaria: .stania/progress.json

Si existe, leerlo. Contiene estado preciso por aggregate:
- status: pending / in-progress / done / failed
- layers: domain, application, infrastructure, tests (true/false cada uno)
- specPath: ruta a la spec aprobada
- lastCheck, lastBuild: timestamps

Tambien leer lastSession para mostrar cuando fue la ultima sesion.

### Fallback: escaneo del filesystem

Si `.stania/progress.json` no existe, buscar bounded contexts en:
1. `.stania/domain-model.json`
2. CLAUDE.md (seccion bounded contexts)
3. docs/02-architecture.md
4. Estructura de directorios (src/domain/*, apps/*/src/domain/*)

Si no encuentra modelo: "No encuentro bounded contexts. Corre /model primero."

Para cada aggregate detectado, escanear:

```bash
# Domain
find . -path "*/domain/*" -name "*.ts" -o -name "*.py" | grep -v node_modules | head -50

# Application
find . -path "*/application/*" -name "*.ts" -o -name "*.py" | grep -v node_modules | head -30

# Infrastructure
find . -path "*/infrastructure/*" -name "*.ts" -o -name "*.py" | grep -v node_modules | head -30

# Tests
find . \( -path "*/tests/*" -o -path "*test*" -o -path "*spec*" \) -name "*.ts" -o -name "*.py" | grep -v node_modules | head -30
```

## Paso 2: Reportar

```
=== PROJECT STATUS ===
Last session: [fecha] — [resumen]

Bounded Context: [nombre]
+--------------+--------+-------+-------+-------+------+
| Aggregate    | Status | Domain| App   | Infra | Tests|
+--------------+--------+-------+-------+-------+------+
| Appointment  | done   |  Y    |  Y    |  -    |  Y   |
| Tenant       | done   |  Y    |  Y    |  Y    |  Y   |
| VoiceSession | pending|  -    |  -    |  -    |  -   |
+--------------+--------+-------+-------+-------+------+

Bounded Context: [nombre]
+--------------+--------+-------+-------+-------+------+
| Aggregate    | Status | Domain| App   | Infra | Tests|
+--------------+--------+-------+-------+-------+------+
| ...          |        |       |       |       |      |
+--------------+--------+-------+-------+-------+------+

Overall: 4/12 aggregates complete (33%)
Specs:   3 aprobadas en .stania/specs/
```

## Paso 3: Sugerir siguiente accion

Basado en el estado, en orden de prioridad:
1. Si hay aggregates sin spec → "/spec para [aggregate]"
2. Si hay spec sin domain → "/build para [aggregate]"
3. Si hay domain sin app → "/build para [aggregate] (falta application)"
4. Si hay app sin infra → "/build para [aggregate] (falta infrastructure)"
5. Si hay layers sin tests → "Faltan tests para [aggregate]"
6. Si hay done sin lastCheck → "/check para validar"
7. Si todo esta completo → "/check para validar, despues /ship"

Mostrar:
```
NEXT: /spec → VoiceSession (first incomplete aggregate)
```
