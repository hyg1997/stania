Extrae un modelo de dominio DDD completo a partir de una descripcion de negocio.
Reemplaza la necesidad de disenar bounded contexts manualmente.

## Cuando usar

- Al iniciar un proyecto nuevo (despues de /bootstrap)
- Cuando agregas un nuevo dominio de negocio
- Para refinar el modelo existente

## Paso 1: Verificar estado

Buscar si ya existe un modelo de dominio:
- docs/02-architecture.md con bounded contexts definidos
- CLAUDE.md con seccion de bounded contexts
- Cualquier archivo de modelo de dominio existente

Si existe: preguntar "Ya tienes un modelo. Quieres refinarlo o empezar de cero?"
Si no existe: proceder a extraccion.

## Paso 2: Recopilar descripcion del negocio

Pedir al usuario que describa su negocio/producto. Guiar con preguntas:

1. **Que hace el sistema?** (1-3 oraciones)
2. **Quienes son los usuarios/actores?** (roles)
3. **Cuales son los procesos principales?** (flujos de trabajo)
4. **Que reglas de negocio son criticas?** (invariantes)
5. **Que eventos importantes ocurren?** (triggers)

Si la descripcion es menor a 3 oraciones, hacer preguntas de follow-up.
NO inventar — extraer solo de lo que el usuario dice.

## Paso 3: Extraer modelo

A partir de la descripcion, identificar:

### Bounded Contexts
Agrupar conceptos que van juntos. Regla: si dos conceptos usan la misma
palabra con significado distinto, van en contextos diferentes.

### Por cada Bounded Context:

**Aggregates** (raiz de consistencia transaccional):
- Nombre
- Invariantes (reglas que nunca se violan)
- Comandos que acepta
- Eventos que emite

**Value Objects** (inmutables, auto-validantes):
- Nombre
- Campos
- Reglas de validacion

**Domain Events** (hechos que ya ocurrieron):
- Nombre (pasado: OrderPlaced, AppointmentBooked)
- Payload (datos que lleva)
- Quien lo emite
- Quien reacciona

**Ports** (interfaces que el dominio necesita):
- Repositories (persistencia)
- External services (APIs, email, SMS)

## Paso 4: Presentar modelo

Formato de presentacion:

```markdown
# Modelo de Dominio: [nombre del sistema]

## Bounded Context: [nombre]

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
(repetir por cada bounded context)
```

## Paso 5: Aprobacion y persistencia

Presentar el modelo al usuario. Esperar aprobacion.

Si aprueba: guardar en docs/02-architecture.md (seccion Bounded Contexts)
y actualizar CLAUDE.md con la lista de bounded contexts.

Si quiere cambios: iterar hasta que este satisfecho.

## Reglas

- NO inventar bounded contexts que el usuario no menciono
- Preferir menos contextos bien definidos que muchos superficiales
- Cada aggregate debe tener al menos 1 invariante — si no tiene, probablemente es un CRUD simple y no necesita DDD
- Value objects > primitivos siempre (Email, no string; Money, no number)
- Si no esta claro si algo es Entity o Value Object, preguntar: "tiene ciclo de vida propio?"
