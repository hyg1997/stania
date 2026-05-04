Cierre de sesion. Rapido y util. Solo captura lo que cambia el comportamiento futuro.

## Proceso

```bash
git log --oneline --since="today"
```

### Si hubo decision arquitectonica significativa:
- Crear ADR en docs/decisions/ (solo si cambia como se trabaja en futuro)
- Actualizar CLAUDE.md solo si agrega info que Claude necesita en proximas sesiones

### Si NO hubo decisiones (la mayoria de sesiones):
- Solo actualizar progress.json y sugerir siguiente paso

## Actualizar estado

Si `.stania/progress.json` existe:
```json
{ "lastSession": { "date": "[ISO8601]", "summary": "[1 oracion]" } }
```

## Reporte (maximo 5 lineas)

```
Completado: [lista corta]
Pendiente:  [lista corta]
Proximo:    /st-spec → [Aggregate] | /st-build → [feature] | nada pendiente
```

## Reglas

- Si no hubo decisiones → NO crear ADR, NO proponer cambios a docs
- No ser verbose — el usuario quiere cerrar en 10 segundos
- Si algo quedo pendiente critico, una linea clara
- NUNCA volcar resumen largo de la sesion
