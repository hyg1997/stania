Auto-genera tests E2E con Playwright desde contratos API.
Lee contratos tipados y genera tests que validan el stack completo (UI → API → DB).

## Uso

- `/st-e2e <contract-name>` — Genera e2e para un contrato especifico
- `/st-e2e --all` — Genera para todos los contratos que no tienen e2e aun

## Inputs (leer antes de generar)

1. `packages/contracts/<name>.ts` — Tipos de request/response/error
2. `packages/contracts/generated/client/<name>.ts` — API client (para entender rutas)
3. `apps/web/e2e/` — Tests existentes (para no duplicar)
4. `apps/web/e2e/pages/` — Page Objects existentes (para reusar)
5. `playwright.config.ts` — Config existente (baseURL, timeouts)

## Modo: contrato especifico

### 1. Leer contrato

```bash
cat packages/contracts/<name>.ts
cat packages/contracts/generated/client/<name>.ts 2>/dev/null
```

Extraer:
- Request fields (son los inputs del form)
- Response fields (son lo que la UI muestra post-submit)
- Error types (son los mensajes de error que la UI muestra)
- Endpoint metadata (method, path)

Si el contrato no existe → "Primero /st-contract <name>"

### 2. Generar Page Object

Crear `apps/web/e2e/pages/<name>.page.ts`:

```typescript
import { type Page, type Locator } from '@playwright/test';

export class [Name]Page {
  readonly page: Page;

  // Locators — prefer role-based selectors
  readonly heading: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;
  readonly loadingSkeleton: Locator;
  // Input locators derived from contract request fields
  readonly [field]Input: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: /[feature name]/i });
    this.submitButton = page.getByRole('button', { name: /submit|create|save/i });
    this.errorMessage = page.getByRole('alert');
    this.loadingSkeleton = page.getByTestId('[name]-skeleton');
    // Map each request field to a locator
    this.[field]Input = page.getByLabel(/[field label]/i);
  }

  async goto() {
    await this.page.goto('/[route-for-feature]');
  }

  async fill(data: Partial<Create[Name]Request>) {
    // Fill each field from data
    if (data.[field]) await this.[field]Input.fill(data.[field]);
  }

  async submit() {
    await this.submitButton.click();
  }

  async expectSuccess(response: Partial<Create[Name]Response>) {
    // Assert response fields are visible in the UI
    for (const [key, value] of Object.entries(response)) {
      await expect(this.page.getByText(String(value))).toBeVisible();
    }
  }

  async expectError(code: string) {
    await expect(this.errorMessage).toBeVisible();
  }

  async expectLoading() {
    await expect(this.loadingSkeleton).toBeVisible();
  }
}
```

Reglas del Page Object:
- Locators por `getByRole`, `getByLabel`, `getByText` — evitar test IDs salvo loading skeletons
- Un metodo por accion del usuario (`fill`, `submit`, `selectOption`, etc.)
- Metodos `expect*` para verificaciones comunes
- NUNCA logica de test en el Page Object — solo acciones y locators

### 3. Generar test spec

Crear `apps/web/e2e/<name>.spec.ts`:

```typescript
import { test, expect } from '@playwright/test';
import { [Name]Page } from './pages/[name].page';

// Factory para datos de test unicos por ejecucion
function createTestData() {
  const id = Date.now().toString(36);
  return {
    // Request fields con datos realistas + id unico
    [field]: `Test ${id} [realistic value]`,
  };
}

test.describe('[Name] — Happy Path', () => {
  let [name]Page: [Name]Page;

  test.beforeEach(async ({ page }) => {
    [name]Page = new [Name]Page(page);
    await [name]Page.goto();
  });

  test('submit form → API responds → UI updates', async () => {
    const data = createTestData();

    await [name]Page.fill(data);
    await [name]Page.submit();

    // Assert: UI shows success state with response data
    await [name]Page.expectSuccess(data);
  });

  test('form shows validation errors for invalid input', async () => {
    // Submit empty or invalid data
    await [name]Page.submit();

    // Assert: validation messages appear
    await expect([name]Page.page.getByText(/required|invalid/i)).toBeVisible();
  });
});

test.describe('[Name] — Error States', () => {
  let [name]Page: [Name]Page;

  test.beforeEach(async ({ page }) => {
    [name]Page = new [Name]Page(page);
    await [name]Page.goto();
  });

  test('API error → UI shows error message', async ({ page }) => {
    // Trigger a known error condition (e.g., duplicate, invalid state)
    const data = createTestData();
    // Setup condition that causes API error
    await [name]Page.fill(data);
    await [name]Page.submit();

    // Submit again to trigger duplicate error (adapt per contract error types)
    await [name]Page.goto();
    await [name]Page.fill(data);
    await [name]Page.submit();

    await [name]Page.expectError('[ERROR_CODE]');
  });

  test('network error → UI shows retry option', async ({ page }) => {
    // Intercept API call and abort to simulate network failure
    await page.route('**/api/[name]**', (route) => route.abort());

    await [name]Page.fill(createTestData());
    await [name]Page.submit();

    await expect(page.getByText(/error|failed|try again/i)).toBeVisible();
  });
});

test.describe('[Name] — Loading States', () => {
  test('shows skeleton while loading', async ({ page }) => {
    // Slow down API response to observe loading state
    await page.route('**/api/[name]**', async (route) => {
      await new Promise((r) => setTimeout(r, 1000));
      await route.continue();
    });

    const [name]Page = new [Name]Page(page);
    await [name]Page.goto();

    await [name]Page.expectLoading();
  });
});

test.describe('[Name] — Data Cleanup', () => {
  test.afterEach(async ({ request }) => {
    // Cleanup: delete test data via API if endpoint exists
    // Adapt based on available delete endpoint in contract
  });
});
```

### 4. Adaptar al contrato real

Para cada error type del contrato (union discriminada con `code`):
- Generar un test case que provoca ese error
- Assert que el mensaje correcto aparece en la UI

Para cada campo del request:
- Generar locator en el Page Object
- Incluir en el metodo `fill()`
- Agregar test de validacion si el campo es required

### 5. Verificar que corre

```bash
npx playwright test apps/web/e2e/<name>.spec.ts 2>&1 | tail -10
```

Si falla por config faltante:
- Verificar que `playwright.config.ts` existe
- Verificar que `baseURL` apunta a la app local
- Sugerir `npx playwright install` si faltan browsers

Si falla por selectors incorrectos:
- Leer el componente real si existe (`apps/web/` o `features/`)
- Ajustar locators al HTML real
- Preferir roles sobre texto cuando el texto es dinamico

### 6. Commit

```bash
git add apps/web/e2e/
git commit -m "e2e(<name>): generate Playwright tests from contract"
```

## Modo: --all

### 1. Listar contratos sin e2e

```bash
# Todos los contratos
ls packages/contracts/*.ts 2>/dev/null | grep -v index | grep -v generated

# Tests e2e existentes
ls apps/web/e2e/*.spec.ts 2>/dev/null
```

Comparar: generar solo para contratos que no tienen su `.spec.ts` correspondiente.

### 2. Generar en secuencia

Para cada contrato sin e2e:
1. Generar Page Object (si no existe para ese feature)
2. Generar test spec
3. NO correr tests individuales — correr una vez al final

### 3. Verificar batch

```bash
npx playwright test apps/web/e2e/ 2>&1 | tail -10
```

### 4. Commit batch

```bash
git add apps/web/e2e/
git commit -m "e2e: generate Playwright tests for all contracts"
```

## Reglas

- Tests usan API real — NUNCA mockear la API en e2e (excepto para simular network failure)
- Cada test es independiente — setup propio, no depende del orden de ejecucion
- Datos de test unicos por ejecucion (usar timestamp o random suffix)
- Cleanup despues de cada test si crea datos persistentes
- Locators por role/label/text — evitar `data-testid` salvo skeletons y elementos sin semantica
- Page Objects solo contienen acciones y locators — NUNCA logica de test
- Truncar output de Playwright: `2>&1 | tail -10`
- Si el contrato no existe → "Primero /st-contract <name>"
- Si el componente UI no existe → generar tests igual (red → green workflow)
- Si Playwright no esta instalado → `npm init playwright@latest` y reportar
- NUNCA `any` en tipos del Page Object — importar types del contrato
- NUNCA `page.waitForTimeout()` — usar locator assertions que auto-esperan
- NUNCA selectores CSS fragiles (`div > span:nth-child(2)`)
