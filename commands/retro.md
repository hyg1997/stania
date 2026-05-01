Cierre de sesion. Captura lo aprendido y actualiza contexto para futuras sesiones.
Correr al final de una sesion de trabajo productiva.

## Paso 1: Resumen de la sesion

Revisar git log de la sesion (commits de hoy):
```bash
git log --oneline --since="today" --author=""
```

Listar:
- Features/cambios completados
- Decisiones tecnicas tomadas
- Problemas encontrados y como se resolvieron
- Cosas que quedaron pendientes

## Paso 2: Actualizar docs (si aplica)

Revisar si alguna decision tomada en la sesion debe reflejarse en:
- CLAUDE.md (cambio de stack, nuevo principio, nueva restriccion)
- docs/02-architecture.md (nueva decision tecnica, nuevo ADR)
- docs/05-roadmap.md (marcar items como completados)
- docs/01-product-spec.md (cambio de spec basado en lo aprendido)

Proponer los cambios al usuario. Solo aplicar si aprueba.
NO agregar cosas triviales — solo lo que de verdad cambia como
deberia trabajar Claude en sesiones futuras.

## Paso 3: Crear ADR si hubo decision importante

Si se tomo una decision arquitectonica significativa en la sesion,
crear un ADR en docs/decisions/:

```markdown
# ADR-XXX: [titulo]

## Status
Accepted

## Context
[Por que necesitabamos decidir]

## Decision
[Que decidimos y por que]

## Consequences
[Trade-offs aceptados, que ganamos, que perdemos]
```

## Paso 4: Estado del proyecto

Mostrar al usuario:
```
=== SESSION RETRO ===
Completado:    [lista]
Pendiente:     [lista]
Decisiones:    [lista]
Docs updated:  [lista]

Proximo paso sugerido: [que hacer en la siguiente sesion]
```

## Reglas

- No guardar info trivial (fixes cosmeticos, renames)
- Si no hubo decisiones ni aprendizajes → skip retro, solo mostrar resumen
- No ser verbose — el usuario quiere cerrar rapido
- Si hay algo pendiente critico, mencionarlo claramente
