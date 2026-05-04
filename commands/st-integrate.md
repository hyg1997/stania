Reemplaza mocks por backend real y corre tests end-to-end.
Ultimo paso antes de ship. Solo correr cuando backend y frontend estan listos.

## Pre-requisito

Verificar:
1. Backend implementado y tests passing (PR mergeado o branch lista)
2. Frontend implementado contra mocks (PR mergeado o branch lista)
3. Contrato es el mismo en ambos lados

## Proceso

### 1. Verificar alineacion de contrato

```bash
# Comparar types del contrato con la implementacion real
# Backend response debe matchear el contrato exactamente
grep -A 20 "export interface.*Response" packages/contracts/<name>.ts
```

Verificar que el endpoint real devuelve exactamente los campos del contrato.
Si hay diferencia → reportar y preguntar cual es correcto.

### 2. Conectar frontend a backend real

Actualizar environment/config para que el frontend apunte al backend real:
```bash
# apps/web/.env.local
API_URL=http://localhost:3001  # o la URL real
```

Verificar que el MSW handler se desactiva en integracion:
```typescript
// Solo activar mocks en development sin backend
if (process.env.NEXT_PUBLIC_API_MOCKING === 'true') {
  // enable MSW
}
```

### 3. Correr tests de integracion

```bash
# Backend tests (ya deben pasar)
cd apps/api && pnpm test 2>&1 | tail -10

# Frontend con backend real (e2e)
cd apps/web && pnpm test:e2e 2>&1 | tail -15
```

Si no hay tests e2e para este flujo:
- Generar un test basico con Playwright que verifica el happy path
- Un test de error case

### 4. Smoke test manual

Preguntar al usuario:
```
El flujo end-to-end funciona:
[ ] Frontend carga sin errores
[ ] Datos se envian al backend real
[ ] Respuesta se muestra correctamente
[ ] Error cases muestran mensaje adecuado
```

### 5. Reporte

```
=== INTEGRATION ===
Contract alignment: PASS (types match)
Backend tests:     PASS (23/23)
E2E tests:         PASS (4/4)
Manual smoke:      [PENDING user confirmation]

VERDICT: Ready for /st-ship
```

## Si algo no alinea

- **Contract mismatch**: Preguntar cual es correcto. Actualizar contrato + regenerar.
- **Backend error**: Reportar al agente para fix (crear issue si es complejo).
- **Frontend error**: Reportar al intern con contexto claro.

## Reglas

- NUNCA cambiar el contrato sin aprobacion — es la fuente de verdad compartida
- Si backend devuelve campos extra no en el contrato → OK, ignorar
- Si backend NO devuelve campos del contrato → FAIL, es un bug
- Generar e2e tests solo para el happy path + 1 error case — no over-test
