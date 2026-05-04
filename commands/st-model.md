Extrae un modelo de dominio DDD y lo persiste en `.stania/domain-model.json` y `docs/02-architecture.md`.

## Cuando usar

- Al iniciar un proyecto nuevo (despues de /st-bootstrap)
- Cuando agregas un nuevo dominio de negocio
- Para refinar el modelo existente

## Paso 1: Verificar estado

Leer `.stania/domain-model.json` si existe.
Si no, buscar en:
- docs/02-architecture.md (seccion bounded contexts)
- CLAUDE.md (seccion bounded contexts)

Si existe modelo:
"Ya tienes un modelo con N bounded contexts. Quieres refinarlo o empezar de cero?"

Si no existe: proceder a extraccion.

## Paso 2: Recopilar descripcion

Pedir al usuario que describa su negocio. Guiar con:

1. **Que hace el sistema?** (1-3 oraciones)
2. **Quienes son los usuarios/actores?** (roles)
3. **Cuales son los procesos principales?** (flujos)
4. **Que reglas de negocio son criticas?** (invariantes)
5. **Que eventos importantes ocurren?** (triggers)

Si la descripcion es corta, hacer preguntas de follow-up.
NO inventar — extraer solo de lo que el usuario dice.

## Paso 3: Extraer modelo

Identificar:

### Bounded Contexts
Agrupar conceptos relacionados. Regla: si dos conceptos usan la misma
palabra con significado distinto, van en contextos diferentes.

Clasificar:
- **core**: ventaja competitiva, logica de negocio principal
- **supporting**: necesario pero no diferenciador
- **generic**: commodity (auth, notificaciones)

### Por cada Bounded Context

**Aggregates** (raiz de consistencia transaccional):
- Nombre
- Invariantes (reglas que NUNCA se violan)
- Comandos que acepta
- Eventos que emite

**Value Objects** (inmutables, auto-validantes):
- Nombre
- Campos con tipos
- Reglas de validacion

**Domain Events** (hechos que ya ocurrieron):
- Nombre en pasado (OrderPlaced, AppointmentBooked)
- Payload
- Quien lo emite / quien reacciona

**Ports** (interfaces que el dominio necesita):
- Repositories (persistencia)
- External services (APIs, email, SMS)
- Metodos con firmas

### Relationships
- upstream_downstream (uno provee, otro consume)
- shared_kernel (comparten tipos)
- anti_corruption_layer (traductor entre contextos)

## Paso 4: Presentar modelo

```markdown
# Modelo de Dominio: [nombre]

## Bounded Context: [nombre] (core|supporting|generic)

### Aggregate: [nombre]
- **Invariantes**: [lista]
- **Comandos**: [lista]
- **Eventos**: [lista]

### Value Objects
- **[nombre]**: [campos] — [validacion]

### Ports
- I[nombre]Repository: [metodos]
- I[nombre]Service: [metodos]

---

## Relaciones
- [source] → [target]: [tipo]
```

## Paso 5: Persistir

Si el usuario aprueba:

1. Guardar `.stania/domain-model.json`:
```json
{
  "name": "[nombre]",
  "boundedContexts": [...],
  "relationships": [...]
}
```

2. Actualizar `docs/02-architecture.md` (version legible)

3. Actualizar CLAUDE.md con la lista de bounded contexts

4. Inicializar `.stania/progress.json` con aggregates en status "pending":
```json
{
  "aggregates": {
    "ContextName/AggregateName": {
      "status": "pending",
      "layers": { "domain": false, "application": false, "infrastructure": false, "tests": false },
      "specPath": null, "lastCheck": null, "lastBuild": null
    }
  }
}
```

Si quiere cambios: iterar hasta que este satisfecho.

## Refinamiento

Si el usuario quiere modificar un modelo existente:

1. Leer `.stania/domain-model.json`
2. Preguntar que quiere cambiar
3. Aplicar cambios
4. Presentar modelo actualizado
5. Si aprueba: actualizar domain-model.json, docs, y progress.json
   - Agregar nuevos aggregates como "pending"
   - Mantener estado de aggregates existentes

## Reglas

- NO inventar bounded contexts que el usuario no menciono
- Preferir menos contextos bien definidos que muchos superficiales
- Cada aggregate debe tener al menos 1 invariante. Sin invariantes = CRUD simple
- Value Objects > primitivos siempre (Email, no string; Money, no number)
- Si no esta claro si es Entity o Value Object → preguntar: "tiene ciclo de vida propio?"
- Maximo 6-8 bounded contexts. Si hay mas, probablemente se pueden fusionar
