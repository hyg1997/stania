Cierre de sesion. Captura lo aprendido, actualiza contexto, y guarda resumen en `.stania/progress.json`.

## Paso 1: Resumen de la sesion

Revisar git log de la sesion:
```bash
git log --oneline --since="today"
```

Listar:
- Features/cambios completados
- Decisiones tecnicas tomadas
- Problemas encontrados y como se resolvieron
- Cosas que quedaron pendientes

## Paso 2: Actualizar docs (si aplica)

Revisar si alguna decision debe reflejarse en:
- CLAUDE.md (cambio de stack, nuevo principio)
- docs/02-architecture.md (nueva decision tecnica, ADR)
- docs/05-roadmap.md (items completados)
- docs/01-product-spec.md (cambio de spec)

Proponer cambios. Solo aplicar si el usuario aprueba.
NO agregar cosas triviales — solo lo que cambia como deberia
trabajar Claude en sesiones futuras.

## Paso 3: Crear ADR si hubo decision importante

Si se tomo una decision arquitectonica significativa:

```markdown
# ADR-XXX: [titulo]

## Status
Accepted

## Context
[Por que necesitabamos decidir]

## Decision
[Que decidimos y por que]

## Consequences
[Trade-offs aceptados]
```

Guardar en docs/decisions/.

## Paso 4: Actualizar estado

Si `.stania/progress.json` existe, actualizar:
```json
{
  "lastSession": {
    "date": "[ISO8601]",
    "summary": "[resumen de 1-2 oraciones de lo hecho]"
  }
}
```

## Paso 5: Reporte

```
=== SESSION RETRO ===
Completado:    [lista]
Pendiente:     [lista]
Decisiones:    [lista]
Docs updated:  [lista]

Proximo paso sugerido: [que hacer en la siguiente sesion]
```

Si hay aggregates pendientes en progress.json, sugerir el primero:
"Proximo: /st-spec para [Aggregate] en [BoundedContext]"

## Reglas

- No guardar info trivial (fixes cosmeticos, renames)
- Si no hubo decisiones → skip retro, solo mostrar resumen
- No ser verbose — el usuario quiere cerrar rapido
- Si hay algo pendiente critico, mencionarlo claramente
