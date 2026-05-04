Comando para frontend devs (interns) que necesitan un endpoint que no existe.
Crea un stub de contrato, mock MSW, y un issue para el tech lead.

## Flujo

### 1. Recopilar necesidad

Preguntar al frontend dev:
- Que accion quiere hacer en la UI? (ej: "eliminar un workout", "editar perfil")
- Que datos enviar al backend? (campos conocidos)
- Que espera recibir? (campos de respuesta, si sabe)
- Que metodo HTTP y ruta sugiere? (opcional — el lead puede cambiarla)

### 2. Crear stub de contrato

Crear `packages/contracts/src/{name}.stub.ts`:

```typescript
/**
 * STUB — pendiente de aprobacion por tech lead.
 * Creado por frontend para desbloquear UI.
 * Issue: #{issue_number}
 */
import { z } from "zod";

// Request/Response — propuesta inicial, sujeta a revision
export const [Name]Request = z.object({
  // campos que el frontend sabe que necesita
});
export type [Name]Request = z.infer<typeof [Name]Request>;

export const [Name]Response = z.object({
  // campos esperados
});
export type [Name]Response = z.infer<typeof [Name]Response>;

export const [name]StubEndpoints = {
  [action]: { method: '[METHOD]' as const, path: '/api/[path]' },
} as const;
```

Nota: archivo con extension `.stub.ts` para diferenciarlo de contratos aprobados.

### 3. Crear mock MSW

Crear `packages/contracts/src/generated/mocks/{name}.stub.ts`:

```typescript
import { http, HttpResponse } from 'msw';

export const [name]StubHandlers = [
  http.[method]('/api/[path]', async () => {
    return HttpResponse.json({
      // datos fake realistas basados en el dominio
    }, { status: [code] });
  }),
];
```

### 4. Crear GitHub Issue

```bash
gh issue create \
  --title "contract-needed: [descripcion corta]" \
  --label "contract-needed,frontend" \
  --body "## Contexto
El frontend necesita este endpoint para [accion UI].

## Propuesta
- **Metodo**: [METHOD]
- **Ruta**: /api/[path]
- **Request**: ver \`packages/contracts/src/[name].stub.ts\`
- **Response**: ver stub

## Stub
Archivo: \`packages/contracts/src/[name].stub.ts\`
Mock: \`packages/contracts/src/generated/mocks/[name].stub.ts\`

## Estado
- [ ] Contrato aprobado por lead (/st-contract --from-stub [name])
- [ ] Backend implementado
- [ ] Mock reemplazado por client real"
```

### 5. Agregar TODO en el codigo del frontend

Donde el frontend necesita el endpoint, agregar:
```typescript
// TODO(contract-needed): [name] — issue #[number]
```

### 6. Commit

```bash
git add packages/contracts/src/[name].stub.ts packages/contracts/src/generated/mocks/[name].stub.ts
git commit -m "stub([name]): frontend needs [descripcion] — issue #[number]"
```

## Cuando el lead aprueba

El lead corre `/st-contract --from-stub [name]`, lo que:
1. Lee el stub como punto de partida
2. Refina tipos y validaciones
3. Reemplaza `[name].stub.ts` → `[name].ts` (contrato real)
4. Genera port interfaces y client real
5. Cierra el issue

## Reglas

- Stubs NUNCA se importan en codigo de produccion — solo en mocks/tests
- El archivo `.stub.ts` es una propuesta, no un contrato final
- El frontend NO debe esperar al lead para seguir trabajando — usa el mock
- Si el lead rechaza la propuesta, actualiza el stub y notifica al frontend
- Maximo 1 stub por feature/accion — no fragmentar
