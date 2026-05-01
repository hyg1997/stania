Loop completo de generacion controlada. Etapas 2-3 del pipeline.
Requiere que /spec ya se haya corrido y el usuario haya aprobado.

## Pre-requisito

Si no hay spec aprobada para esta feature, decir:
"Necesito la spec primero. Corro /spec?"
No generar codigo sin spec aprobada (excepto fixes triviales).

## Loop de generacion

### Fase A: Domain Layer (si aplica)

Generar en este orden exacto:
1. Value Objects (inmutables, auto-validantes, constructor privado + factory)
2. Entity / Aggregate Root (constructor privado + factory, invariantes en metodos)
3. Domain Events (records/clases inmutables)
4. Port interfaces (output ports para infrastructure)
5. Tests de dominio para cada pieza

Reglas de domain:
- Zero imports de infrastructure, framework, o librerias externas
- Constructor privado + static factory method (Create, From, etc)
- Invariantes validados DENTRO del aggregate, no en el handler
- Result pattern para operaciones que pueden fallar
- Cada metodo publico tiene al menos un test

Presentar codigo al usuario. Esperar aprobacion antes de Fase B.

### Fase B: Application Layer

1. Command/Query record/class con campos tipados
2. Handler que orquesta: recibe command → llama domain → llama ports
3. DTOs para response (separados de domain entities)
4. Tests de handler con in-memory fakes de los ports

Reglas de application:
- Sin logica de negocio — eso va en domain
- Handler recibe dependencias via constructor (ports)
- Retorna Result<DTO, Error>, nunca lanza excepciones para flujos de negocio
- Fakes en tests, no mocks (implementar la interface con Map/Array en memoria)

Presentar al usuario. Esperar aprobacion antes de Fase C.

### Fase C: Infrastructure Layer

1. Adapters que implementan los port interfaces
2. Configuracion de DI (registrar adapter → port)
3. Tests de integracion (solo si hay I/O real: DB, API externa)

Reglas de infrastructure:
- Implementa exactamente la interface del port, nada mas
- Manejo de errores de I/O: capturar y mapear a domain errors
- No exponer detalles de infra al domain (no SqlException en domain)

### Fase D: Wiring

1. Registrar en el contenedor de DI / modulo
2. Exponer via API endpoint si es necesario (controller/route)
3. Verificar que todo compila y tests pasan

## Post-generacion

Correr automaticamente:
1. Typecheck (tsc / mypy)
2. Lint (biome / ruff)
3. Tests (vitest / pytest)

Si algo falla → arreglar antes de reportar al usuario.

Reportar:
- Archivos creados/modificados
- Tests: X passing, 0 failing
- "Listo para /check o commit"
