Define un contrato API que desbloquea frontend y backend en paralelo.
Genera: tipos TypeScript, mock handlers (MSW), port interfaces, y API client.

## Modos

- `/st-contract <name>` — Define contrato nuevo interactivamente
- `/st-contract --extract` — Extrae contratos de endpoints existentes en el proyecto

## Modo: Nuevo contrato

### 1. Recopilar

Preguntar al usuario:
- Que hace este endpoint?
- Que recibe? (campos, tipos)
- Que devuelve? (success y error cases)
- Que metodo HTTP y ruta?

Leer `.stania/domain-model.json` si existe para contexto de invariantes.

### 2. Generar contrato

Crear `packages/contracts/{name}.ts`:

```typescript
// Request/Response types
export interface Create[Name]Request {
  // campos tipados, nunca any
}

export interface Create[Name]Response {
  // campos de respuesta
}

export type Create[Name]Error =
  | { code: 'ERROR_CODE'; message: string }

// Endpoint metadata
export const [name]Endpoints = {
  create: { method: 'POST' as const, path: '/api/[name]' },
  get: { method: 'GET' as const, path: '/api/[name]/:id' },
} as const;
```

### 3. Generar mock handlers

Crear `packages/contracts/generated/mocks/{name}.ts`:

```typescript
import { http, HttpResponse } from 'msw';

export const [name]Handlers = [
  http.post('/api/[name]', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({
      // response con datos fake realistas
    }, { status: 201 });
  }),
];
```

### 4. Generar port interfaces (backend)

Crear `packages/contracts/generated/ports/{name}.ts`:

```typescript
import type { Create[Name]Request, Create[Name]Response, Create[Name]Error } from '../{name}';

export interface I[Name]Service {
  create(request: Create[Name]Request): Promise<Result<Create[Name]Response, Create[Name]Error>>;
}
```

### 5. Generar API client (frontend)

Crear `packages/contracts/generated/client/{name}.ts`:

```typescript
import type { Create[Name]Request, Create[Name]Response, Create[Name]Error } from '../{name}';
import { [name]Endpoints } from '../{name}';

export async function create[Name](data: Create[Name]Request): Promise<Create[Name]Response> {
  const { method, path } = [name]Endpoints.create;
  const res = await fetch(path, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw await res.json() as Create[Name]Error;
  return res.json();
}
```

### 6. Crear GitHub Issue

```bash
gh issue create \
  --title "implement: [name] backend" \
  --label "agent,backend,contract" \
  --body "Contract: packages/contracts/[name].ts
Implement backend for this contract.
Port interface: packages/contracts/generated/ports/[name].ts"
```

### 7. Commit + push

```bash
git add packages/contracts/
git commit -m "contract([name]): define API contract with mocks and client"
git push
```

## Modo: --extract

Escanear el proyecto buscando endpoints existentes:
```bash
# Next.js API routes
find apps/web/app/api -name "route.ts" 2>/dev/null

# Express/Fastify routes
grep -rn "router\.\(get\|post\|put\|delete\)" --include="*.ts" apps/api/src/ 2>/dev/null
```

Para cada endpoint encontrado:
1. Leer request/response types
2. Generar contrato en `packages/contracts/`
3. Generar mock + client
4. NO tocar el codigo existente

## Reglas

- Nunca usar `any` en contratos — tipos exactos siempre
- Error types deben ser union discriminada con `code`
- Mocks deben devolver datos realistas (no "test", "foo", "bar")
- Un contrato por feature/recurso, no un archivo gigante
- Si el contrato cambia, regenerar mocks y client (idempotente)
