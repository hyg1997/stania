Lanza implementacion autonoma de un contrato o issue.
El agente trabaja en background: implement → check → commit → PR → notifica.

## Uso

- `/st-agent <contract-name>` — Implementa un contrato especifico
- `/st-agent #<issue-number>` — Implementa un issue de GitHub

## Mode Detection

Read `.stania/config.json` → `mode` field.

### Si mode = "solo"

Key differences:
1. **No branch** — work directly on main (or current branch)
2. **No PR** — just commit directly
3. **No GitHub issue reference needed** — can work from inline description
4. **Self-check** — run typecheck + lint + tests internally before reporting
5. **Parallel spawning** — when called with multiple aggregates, spawn one agent per aggregate with `run_in_background: true`
6. **Minimal reporting** — only surface when:
   - DONE: "✅ [name] implemented. Check passed. Ready to test."
   - BLOCKED: "🔒 [name] blocked: [specific question]. Options: A or B?"

Usage in solo mode:
- `/st-agent <aggregate-name>` — implement one aggregate inline
- `/st-agent <agg1> <agg2> <agg3>` — spawn parallel agents, one per aggregate
- `/st-agent --all-pending` — read progress.json, spawn agents for all pending aggregates

### Si mode = "team" (default)

Keep current behavior: branch, PR, labels, notifications.

## Proceso

### 1. Leer contexto

```bash
# Si es contrato:
cat packages/contracts/<name>.ts
cat packages/contracts/generated/ports/<name>.ts

# Si es issue:
gh issue view <number> --json title,body,labels
```

Leer tambien:
- `.stania/config.json` (stack, architecture)
- `.stania/domain-model.json` (solo el bounded context relevante)
- Specs existentes relacionadas en `.stania/specs/`

### 2. Crear branch

Si mode = "team":
```bash
git checkout -b feat/<name>
```

Si mode = "solo":
Stay on current branch. No branch creation.

### 3. Implementar

Seguir el mismo flujo de /st-build pero SIN approval gates:

**Si architecture = "clean":**
1. Domain layer (VOs, aggregate, events, ports, tests)
2. Application layer (handler, DTOs, tests)
3. Infrastructure layer (adapters, DI, integration tests)
4. Wiring (endpoint, DI registration)

**Si architecture != "clean":**
1. Implementar completo en un paso
2. Tests incluidos

#### Code Patterns Reference (inline — do NOT read external files)

When spawning agents in solo mode, include these patterns directly in the agent prompt
so each agent does NOT need to read pattern files. This saves ~8K tokens per agent.

**Domain entity pattern (TypeScript/Clean):**
```typescript
export class EntityName {
  private constructor(private readonly props: EntityProps) {}
  static create(input: CreateInput): Result<EntityName, string> {
    // validate invariants
    return ok(new EntityName({ id: crypto.randomUUID(), ...input, createdAt: new Date() }));
  }
  get id() { return this.props.id; }
  // domain methods that enforce invariants
}
```

**Port interface pattern:**
```typescript
export interface IEntityRepository {
  save(entity: EntityName): Promise<void>;
  findById(id: string): Promise<EntityName | null>;
  findByUserId(userId: string): Promise<EntityName[]>;
}
```

**Use case pattern:**
```typescript
export class HandleCommand {
  constructor(private readonly repo: IEntityRepository) {}
  async execute(input: CommandInput): Promise<Result<Output, Error>> {
    // validate → load → domain logic → persist → return
  }
}
```

**In-memory repository pattern:**
```typescript
export class InMemoryEntityRepository implements IEntityRepository {
  private items: Map<string, EntityName> = new Map();
  async save(entity: EntityName) { this.items.set(entity.id, entity); }
  async findById(id: string) { return this.items.get(id) ?? null; }
}
```

**Hono route pattern:**
```typescript
export function entityRoutes(repo: IEntityRepository) {
  const app = new Hono();
  app.post('/', async (c) => {
    const body = await c.req.json();
    const parsed = Schema.safeParse(body);
    if (!parsed.success) return c.json({ error: parsed.error }, 400);
    const handler = new HandleCommand(repo);
    const result = await handler.execute(parsed.data);
    if (result.isErr()) return c.json({ error: result.error }, 400);
    return c.json(result.value, 201);
  });
  return app;
}
```

#### Frontend Patterns Reference (inline — do NOT read existing pages)

When spawning frontend agents, include these patterns so agents match the existing UI:

**Design system constants:**
- Dark theme: bg `#0a0a0a`, card `#111`, border `#222`, text `#fafafa`, muted `#888`
- Primary blue `#2563eb`, green `#22c55e`, amber `#f59e0b`, purple `#8b5cf6`, red `#ef4444`
- Border radius: `12px` buttons, `10px` cards, `8px` inputs
- Max width: `480px` centered, mobile-first
- Font: system stack (-apple-system), weights 400/500/600/700/800
- All styles as inline `const styles = {}` object, NO CSS files

**Next.js page pattern:**
```typescript
"use client";
import { BottomNav } from "@/components/nav/bottom-nav";
import { useXxxQuery, useXxxMutation } from "@/lib/queries/xxx-queries";
import type { XxxResponse } from "@shenia/contracts";

const styles = { /* dark theme styles */ };

export default function XxxPage() {
  const { data, isLoading, isError, refetch } = useXxxQuery();
  return (
    <main style={styles.page}>
      <header style={styles.header}><h1 style={styles.title}>Title</h1></header>
      {isLoading && <LoadingSkeleton />}
      {isError && <ErrorRetry onRetry={refetch} />}
      {data && <Content data={data} />}
      <BottomNav />
    </main>
  );
}
```

**Query hooks pattern:**
```typescript
import type { XxxResponse, XxxRequest, XxxError } from "@shenia/contracts";
import { xxxEndpoints } from "@shenia/contracts";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "";

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: body ? { "Content-Type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw (await res.json()) as XxxError;
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

const xxxKeys = {
  all: ["xxx"] as const,
  lists: () => [...xxxKeys.all, "list"] as const,
};

export function useListXxx() {
  return useQuery({ queryKey: xxxKeys.lists(), queryFn: () => apiListXxx() });
}
export function useCreateXxx() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: XxxRequest) => apiCreateXxx(data),
    onSuccess: () => { qc.invalidateQueries({ queryKey: xxxKeys.all }); },
  });
}
```

**Navigation structure (bottom-nav.tsx):**
Current tabs: Workouts (`/workouts`, blue), Nutrition (`/nutrition`, green), Routines (`/routines`, amber), Profile (`/profile`, purple).
Do NOT modify bottom-nav.tsx unless explicitly asked — new pages are sub-pages of existing tabs or standalone.

### 3.5. Bounded Context Grouping (solo mode)

When `/st-agent --all-pending` or multiple aggregates are requested:

1. Read progress.json and group pending aggregates by bounded context
2. Spawn **one agent per bounded context**, not one per aggregate
3. Each agent builds ALL aggregates in its context sequentially

Example: Instead of 3 agents for Advisor/Conversation, Advisor/Adaptation, Advisor/Recommendation
→ spawn 1 agent that builds all 3 Advisor aggregates.

Benefits:
- Shared ports.ts file → no merge conflicts (agent owns the whole file)
- Shared test setup → no duplication
- ~4K tokens saved per merged agent (system prompt overhead)

Grouping logic:
```
pending = read progress.json → filter status != "done"
groups = group pending by boundedContext (part before "/")
for each group:
  spawn 1 agent with prompt listing ALL aggregates in the group
```

### 4. Validar

Si mode = "solo":
Run typecheck + tests only (skip lint — orchestrator handles lint once at end).
```bash
pnpm typecheck 2>&1 | tail -5
pnpm test --bail --reporter=dot 2>&1 | tail -10
```

Si mode = "team":
Correr /st-check automaticamente (paralelo: typecheck + lint + tests).

Si falla → intentar fix (maximo 2 intentos).
Si no puede → commit lo que hay, crear PR como draft, notificar que necesita ayuda.

### 5. Commit + PR

Si mode = "team":
```bash
git add .
git commit -m "feat(<name>): implement <description>"
git push -u origin feat/<name>

gh pr create \
  --title "feat(<name>): <titulo corto>" \
  --label "agent,ready-to-review" \
  --body "## Contract
packages/contracts/<name>.ts

## Changes
- [lista de archivos creados]

## Tests
- [resumen: X passing, coverage Y%]

## Notes
[cualquier decision tomada o duda]

---
Generated by Stania Agent"
```

Si mode = "solo":
```bash
git add <specific files>
git commit -m "feat(<name>): implement <description>"
# No push, no PR. Just commit locally.
```

### 6. Notificar

Si mode = "team":
El agente usa push notification al terminar.
El PR queda con label "ready-to-review" para que /st-board lo muestre.

Si mode = "solo":
Print: "✅ [name] done. typecheck ✓ lint ✓ tests ✓"
No push notification needed — user is in the same session.

## Modo background

El agente corre con `run_in_background: true`.
Hugo puede seguir trabajando o cerrar la sesion.
Recibe notificacion cuando termina.

## Reglas

- NUNCA mergear automaticamente — solo crear PR
- Si hay ambiguedad en el contrato → dejar nota en PR body, no asumir
- Si el contrato no existe → error: "Primero define el contrato con /st-contract <name>"
- Respetar todas las reglas de Clean Architecture de SKILL.md
- Si hay domain-model.json, los invariantes del modelo son obligatorios
- Si algun test falla y no puede arreglar → PR como draft con label "needs-decision"
