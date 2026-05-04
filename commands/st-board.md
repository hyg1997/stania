Muestra estado del proyecto leyendo GitHub Issues y PRs.
Vista de PM/Tech Lead: que necesita atencion, que esta en progreso, que viene despues.

## Proceso

### 1. Leer datos de GitHub

```bash
# PRs abiertas
gh pr list --json number,title,labels,author,reviewDecision,statusCheckRollup,updatedAt --limit 20 2>&1 | tail -30

# Issues abiertos
gh issue list --json number,title,labels,assignees,state,updatedAt --limit 30 2>&1 | tail -40
```

### 2. Clasificar y mostrar

Agrupar por estado de accion:

```
=== BOARD ===

REVIEW NEEDED (tu accion):
  PR #34: feat(appointments): booking flow [agent] — checks ✓
  PR #37: ui(calendar): slot picker [carlos] — checks ✓

IN PROGRESS (sin accion):
  Issue #38: payment contract backend → agent running
  Issue #39: booking confirmation page → carlos

BLOCKED (decision needed):
  Issue #40: "cancel policy < 1hr" → needs-decision

BACKLOG (next up):
  Issue #41: notifications contract
  Issue #42: tenant settings page

RECENTLY SHIPPED:
  PR #32: feat(auth): login flow → merged 2h ago
  PR #33: ui(landing): hero section → merged yesterday
```

### 3. Sugerir acciones

Basado en el estado:
- Si hay PRs ready-to-review → "gh pr review [n] --approve"
- Si hay issues blocked → preguntar decision al usuario
- Si backlog esta vacio → "Definir proximos contratos con /st-contract"
- Si no hay issues con label "agent" → "Todo asignado. Backlog vacio."

## Alternativa sin GitHub

Si no hay repo en GitHub (proyecto local):
- Leer `.stania/progress.json` como fallback
- Mostrar /st-status normal
- Sugerir: "Crea un repo con /st-bootstrap para habilitar el board completo"

## Reglas

- Output maximo 25 lineas — si hay mas, agrupar con conteos
- No leer contenido de PRs/Issues, solo metadata
- Ordenar por prioridad: review needed > blocked > in-progress > backlog
