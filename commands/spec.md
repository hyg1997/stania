Escribe la spec formal de una feature ANTES de generar codigo.
Esta es la Etapa 1 del pipeline: SPEC → GENERATE → VALIDATE → HARDEN → REVIEW.

## Proceso

### 1. Identificar el scope

Lee CLAUDE.md para entender el proyecto y la arquitectura.
Si existe docs/02-architecture.md o equivalente, leerlo.

Pregunta al usuario si no esta claro:
- Que feature/cambio quiere hacer
- En que bounded context vive
- Que reglas de negocio aplican

### 2. Escribir la spec

Formato obligatorio:

```markdown
## Feature: [nombre descriptivo]

**Bounded context**: [nombre]
**Capas afectadas**: Domain → Application → Infrastructure (listar solo las que aplican)

**Input**: [tipo y campos]
**Output**: Result<[tipo], [ErrorType]>

**Invariantes** (reglas que NUNCA se violan):
  1. [invariante]
  2. [invariante]

**Errores posibles**:
  - [ErrorName]: cuando [condicion]
  - [ErrorName]: cuando [condicion]

**Edge cases**:
  - Que pasa si [caso]?
  - Que pasa si [caso concurrente]?

**Dependencias**: [ports/interfaces que necesita]

**Tests criticos**:
  - [caso que debe tener test obligatorio]
  - [caso que debe tener test obligatorio]
```

### 3. Validar la spec

Antes de presentarla al usuario, verificar:
- Cada invariante tiene al menos un test critico asociado?
- Cada error tiene condicion clara de cuando ocurre?
- Hay al menos un edge case de concurrencia si aplica?
- Los tipos de input/output son especificos (no `any`, no `object`)?

### 4. Esperar aprobacion

Presentar la spec al usuario. NO generar codigo hasta que diga que esta bien.
Si el usuario corrige o agrega algo, actualizar la spec y volver a presentar.

## Reglas

- Si no hay suficiente info para definir invariantes → PREGUNTAR, no inventar
- Nunca asumir reglas de negocio — confirmar con el usuario
- Si la feature es trivial (config, fix cosmético), decirlo: "esto no necesita spec formal, procedo directo"
- Si la feature toca domain layer → spec obligatoria, sin excepciones
