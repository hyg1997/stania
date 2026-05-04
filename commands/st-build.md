Generacion controlada capa por capa. Etapa 2 del pipeline.
Requiere spec aprobada. Actualiza `.stania/progress.json` al completar cada capa.

## Pre-requisito

Verificar:
1. Existe spec aprobada? Buscar en `.stania/specs/` o preguntar: "Corro /st-spec primero?"
2. Leer `.stania/config.json` para stack y arquitectura
3. Leer `.stania/domain-model.json` para contexto del dominio
4. Leer la spec relevante

Si no hay spec y la tarea es trivial (fix, config): proceder sin spec.
Si toca domain: spec obligatoria.

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

Presentar al usuario. Esperar aprobacion.

Al aprobar, actualizar `.stania/progress.json`:
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

Presentar al usuario. Esperar aprobacion.

Al aprobar:
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

Correr automaticamente:
1. Typecheck (tsc / mypy)
2. Lint (biome / ruff)
3. Tests (vitest / pytest)

Si algo falla → arreglar antes de reportar.

Reportar:
- Archivos creados/modificados
- Tests: X passing, 0 failing
- "Listo para /st-check o commit"

## Sin modelo DDD

Si `config.architecture !== "clean"`:
- Saltar separacion en capas
- Generar codigo segun la spec
- Correr tests y validacion
- Actualizar progress.json

## Reglas de estado

- Si `.stania/` no existe, generar codigo sin tracking
- Nunca bloquear por falta de estado — el estado facilita, no restringe
- Si el usuario interrumpe entre fases, el progress refleja hasta donde llego
- En la siguiente sesion, /st-status mostrara que capa falta
