Sugiere las siguientes 1-3 acciones concretas segun el rol del usuario y el estado del proyecto.
Output maximo 5 lineas, formato accionable con comandos exactos.

## Paso 1: Detectar rol

Leer `.stania/me.json`:

```json
{ "role": "lead" | "frontend" | "pm" }
```

Also read `.stania/config.json` → `mode`.
If mode = "solo", skip role detection — treat as "solo" role regardless of me.json.

Si no existe, preguntar:

> ¿Cuál es tu rol? (lead / frontend / pm)

Al recibir respuesta, crear `.stania/me.json`:

```bash
mkdir -p .stania
cat > .stania/me.json << 'EOF'
{ "role": "<respuesta>" }
EOF
```

## Paso 2: Leer estado del proyecto

Recopilar datos (solo lo necesario, no leer contenido completo):

```bash
# Progress general
cat .stania/progress.json 2>/dev/null

# PRs abiertas
gh pr list --json number,title,labels,reviewDecision,isDraft --limit 10 2>&1

# Issues abiertos con labels
gh issue list --json number,title,labels,assignees --limit 15 2>&1

# UI specs pendientes
ls .stania/ui-specs/ 2>/dev/null

# Contratos existentes
ls packages/contracts/*.ts 2>/dev/null

# Contratos sin agent (sin branch feat/ correspondiente)
for f in packages/contracts/*.ts; do
  name=$(basename "$f" .ts)
  if ! git branch -a 2>/dev/null | grep -q "feat/$name"; then
    echo "no-agent: $name"
  fi
done 2>/dev/null
```

## Paso 3: Generar sugerencias por rol

### Si role = "lead"

Prioridad:
1. Stubs de frontend pendientes de aprobacion (`ls packages/contracts/src/*.stub.ts` o issues con label `contract-needed`)
2. PRs listas para review (reviewDecision != APPROVED, no draft)
3. Contratos sin agent implementando (sin branch `feat/<name>`)
4. Issues con label "blocked" o "needs-decision"
5. Integraciones pendientes (contratos con agent mergeado pero sin wiring)

### Si role = "frontend"

Prioridad:
1. Stubs pendientes de aprobacion (archivos `.stub.ts` en `packages/contracts/src/`)
2. UI specs en `.stania/ui-specs/` sin implementacion (buscar archivos en `apps/` o `src/` que correspondan)
3. Issues asignados al usuario con label "frontend" o "ui"
4. Contratos listos (mergeados) que necesitan UI
5. Endpoints que necesita pero no existen → `/st-need-contract`

### Si mode = "solo"

Prioridad:
1. Uncommitted changes that need /st-check or commit
2. Next pending aggregate from progress.json (by bounded context priority: core > supporting > generic)
3. Test/mutation gaps (aggregates with low mutation score)
4. E2E tests needed for completed features

Never suggest:
- "Review PR" or "Approve stub" (no PRs in solo)
- "Create issue" (no issues in solo)
- Role-specific actions (you're everything)

Example output:
```
NEXT:
→ Uncommitted changes (routine edit): /st-check
→ Build Nutrition/Pantry (next pending core aggregate): /st-agent Nutrition/Pantry
→ Mutation gap: Training/Routine at 0% — add domain tests: /st-mutate Training/Routine
```

### Si role = "pm"

Prioridad:
1. Progreso general: X/Y aggregates completos
2. Issues o PRs bloqueados que necesitan decision
3. Timeline: que se envio esta semana, que falta para release

## Paso 4: Output

Formato exacto — maximo 5 lineas, siempre con comando ejecutable:

```
NEXT:
→ [accion 1 con contexto]: [comando exacto]
→ [accion 2 con contexto]: [comando exacto]
→ [accion 3 con contexto]: [comando exacto]
```

Ejemplos por rol:

**lead:**
```
NEXT:
→ PR #5 ready for review (agent: create-reservation): gh pr review 5
→ Contract "list-restaurants" has no agent: /st-agent list-restaurants
→ Issue #12 blocked — needs cancellation policy decision: gh issue view 12
```

**frontend:**
```
NEXT:
→ UI spec "order-list" pending implementation: /st-ui order-list
→ UI spec "restaurant-detail" pending implementation: /st-ui restaurant-detail
→ Contract "get-menu" merged — needs UI: /st-ui get-menu
```

**pm:**
```
NEXT:
→ Progress: 6/10 aggregates complete (60%)
→ PR #8 blocked 2 days — needs your decision: gh issue view 14
→ Shipped this week: 3 PRs merged. Next: payments contract
```

## Reglas

- Si no hay `.stania/` ni repo GitHub, reportar: "Corre /st-bootstrap para inicializar el proyecto."
- Nunca mostrar mas de 3 acciones — priorizar por urgencia
- Si no hay nada pendiente: "Todo al dia. Buen momento para /st-retro o planear el proximo sprint."
- No leer contenido de archivos innecesariamente — solo metadata y listados
- Comando debe completarse en < 5 segundos
