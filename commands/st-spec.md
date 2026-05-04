Escribe la spec formal de una feature ANTES de generar codigo.
Etapa 1 del pipeline: SPEC → BUILD → CHECK → SHIP → RETRO.
Las specs aprobadas se guardan en `.stania/specs/` para referencia futura.

## Proceso

### 1. Identificar scope

Lee CLAUDE.md y `.stania/config.json` para entender el proyecto.
Si existe `.stania/domain-model.json`, leerlo para contexto del dominio.
Si existe docs/02-architecture.md, leerlo.

Pregunta al usuario si no esta claro:
- Que feature/cambio quiere hacer
- En que bounded context vive
- Que reglas de negocio aplican

### 2. Escribir la spec

Formato obligatorio:

```markdown
## Feature: [nombre descriptivo]

**Bounded context**: [nombre]
**Aggregate**: [nombre]
**Capas afectadas**: Domain / Application / Infrastructure

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

Si el aggregate existe en `.stania/domain-model.json`, usar los invariantes,
eventos y ports definidos ahi como base. Agregar los especificos de esta feature.

### 3. Validar la spec

Antes de presentar, verificar:
- Cada invariante tiene al menos un test critico?
- Cada error tiene condicion clara?
- Hay al menos un edge case de concurrencia si aplica?
- Los tipos son especificos (no `any`, no `object`)?
- Es consistente con el domain model?

### 4. Esperar aprobacion

Presentar la spec. NO generar codigo hasta que el usuario apruebe.
Si corrige algo, actualizar y volver a presentar.

### 5. Persistir spec

Cuando el usuario aprueba:

1. Crear `.stania/specs/` si no existe
2. Guardar en `.stania/specs/{feature-slug}.md`

3. Si el aggregate existe en `.stania/progress.json`, actualizar specPath.
   Si no existe, agregarlo como "pending".

Confirmar: "Spec guardada. Listo para /st-build."

## Reglas

- Si no hay suficiente info → PREGUNTAR, no inventar
- Nunca asumir reglas de negocio — confirmar con el usuario
- Feature trivial (config, fix cosmetico): "No necesita spec formal, procedo directo"
- Si toca domain layer → spec obligatoria, sin excepciones
- Si ya existe spec para este aggregate: "Ya hay una spec. Quieres modificarla o crear una nueva?"
- Si `.stania/` no existe, igual escribir la spec y mostrarla — solo no persistir
