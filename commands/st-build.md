Generacion controlada capa por capa. Etapa 2 del pipeline.
Requiere spec aprobada. Actualiza `.stania/progress.json` al completar cada capa.

## Pre-requisito

Verificar:
1. Existe spec aprobada? Buscar en `.stania/specs/` o preguntar: "Corro /st-spec primero?"
2. Leer `.stania/config.json` para stack y arquitectura

**Lazy loading** (no leer todo al inicio):
3. Leer `.stania/domain-model.json` SOLO el bounded context afectado, no el modelo entero.
   Si el modelo es grande, filtrar: leer, extraer el aggregate relevante, descartar el resto.
4. Leer la spec relevante (solo el archivo de la feature, no todas las specs)

Si no hay spec y la tarea es trivial (fix, config): proceder sin spec.
Si toca domain: spec obligatoria.

## Mode Detection

Read `.stania/config.json` → `mode` field.

### Si mode = "solo"

**NO approval gates**. Build all layers in sequence without pausing:
1. Domain layer (VOs, aggregate, events, ports, tests)
2. Application layer (handler, DTOs, tests) 
3. Infrastructure layer (adapters, DI, integration tests)
4. Wiring (endpoint, DI registration)
5. Run /st-check internally
6. Report result to user

If building multiple aggregates: spawn parallel agents (one per aggregate using Agent tool with run_in_background: true). Each agent builds all 4 layers + runs check. Only surface when done or blocked.

**Skip**: spec file requirement (inline plan is enough), progress.json approval updates between layers.
**Keep**: progress.json update at the end, Clean Architecture rules, domain model reading.

Format for reporting after solo build:
```
✅ Built [Aggregate] — all layers + tests
   Domain: X files | App: Y files | Infra: Z files | Tests: W
   Check: typecheck ✓ lint ✓ tests ✓ (N passed)
⚡ ~15K tokens estimated
```

### Si mode = "team" (default, current behavior)

Keep ALL existing behavior unchanged. The approval gates between layers remain.

## Loop de generacion

### Fase A: Domain Layer

Generar en este orden:
1. Value Objects (inmutables, auto-validantes, constructor privado + factory)
2. Entity / Aggregate Root (constructor privado + factory, invariantes en metodos)
3. Domain Events (records inmutables)
4. Port interfaces (output ports para infrastructure)
5. Tests de dominio para cada pieza

Reglas de domain:
- Zero imports de infrastructure, framework, o librerias externas
- Constructor privado + static factory method
- Invariantes validados DENTRO del aggregate, no en el handler
- Result pattern para operaciones que pueden fallar
- Cada metodo publico tiene al menos un test

Si mode = "team": Presentar al usuario. Esperar aprobacion.
Si mode = "solo": Continuar sin pausa.

Al aprobar (o automaticamente en solo), actualizar `.stania/progress.json`:
```json
{ "status": "in-progress", "layers": { "domain": true, "tests": true } }
```

### Fase B: Application Layer

1. Command/Query con campos tipados
2. Handler que orquesta: recibe command → llama domain → llama ports
3. DTOs para response (separados de domain entities)
4. Tests de handler con in-memory fakes

Reglas:
- Sin logica de negocio — eso va en domain
- Handler recibe dependencias via constructor (ports)
- Result<DTO, Error>, no excepciones para flujos de negocio
- Fakes en tests, no mocks (implementar interface con Map/Array en memoria)

Si mode = "team": Presentar al usuario. Esperar aprobacion.
Si mode = "solo": Continuar sin pausa.

Al aprobar (o automaticamente en solo):
```json
{ "layers": { "domain": true, "application": true, "tests": true } }
```

### Fase C: Infrastructure Layer

1. Adapters que implementan port interfaces
2. Configuracion de DI
3. Tests de integracion (solo si hay I/O real)

Reglas:
- Implementa exactamente la interface del port
- Capturar errores de I/O y mapear a domain errors
- No exponer detalles de infra al domain

Al aprobar:
```json
{
  "status": "done",
  "layers": { "domain": true, "application": true, "infrastructure": true, "tests": true },
  "lastBuild": "[ISO8601]"
}
```

### Fase D: Wiring

1. Registrar en contenedor de DI / modulo
2. Exponer via API endpoint si necesario
3. Verificar que todo compila y tests pasan

## Post-generacion

NO correr validacion completa aqui — eso es trabajo de /st-check.
Solo verificar que compila (typecheck basico) para no entregar codigo roto.

```bash
# Solo typecheck rapido — lint y tests van en /st-check
pnpm typecheck 2>&1 | tail -5   # TS
mypy . 2>&1 | tail -5           # Python
go vet ./... 2>&1 | tail -5     # Go
```

Si typecheck falla → arreglar antes de reportar.

## Visual self-verification (agent-browser)

If `agent-browser` is installed and the build includes UI (frontend files modified):

```bash
if command -v agent-browser &>/dev/null; then
  # Start dev server if not running
  pnpm dev --filter web &
  sleep 3
  # Snapshot the page via accessibility tree (compact, ~1K tokens)
  agent-browser open http://localhost:3000/<route>
  agent-browser snapshot
  # Verify key elements exist
  agent-browser get text @e1  # main heading
fi
```

Use accessibility tree snapshots (NOT screenshots) for token efficiency.
Only verify: page loads, key elements present, no error states visible.
Skip if agent-browser not installed — never block on this.

Reportar:
- Archivos creados/modificados
- Visual check: PASS/SKIP
- "Listo para /st-check"

## Sin modelo DDD (architecture = "mvc" o "simple")

Si `config.architecture !== "clean"`:
- NO separar en capas, NO pedir approval por capa
- Generar codigo completo segun la spec en un solo paso
- Generar tests junto al codigo
- Verificar typecheck basico
- Presentar al usuario una sola vez para aprobacion
- Actualizar progress.json

## Reglas de estado

- Si `.stania/` no existe, generar codigo sin tracking
- Nunca bloquear por falta de estado — el estado facilita, no restringe
- Si el usuario interrumpe entre fases, el progress refleja hasta donde llego
- En la siguiente sesion, /st-status mostrara que capa falta
