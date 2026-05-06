Generate E2E tests with Playwright from API contracts.

## Usage

- `/st-e2e <contract-name>` — generate for one contract
- `/st-e2e --all` — generate for all contracts missing E2E tests

## Process

### 1. Read contract
```bash
cat packages/contracts/src/<name>.ts
ls apps/web/e2e/*.spec.ts 2>/dev/null
```
Extract: request fields (form inputs), response fields (UI assertions), error types, endpoints.
If contract missing → "Run /st-contract <name> first"

### 2. Generate Page Object

Create `apps/web/e2e/pages/<name>.page.ts`:
- Locators via `getByRole`, `getByLabel`, `getByText` — avoid test IDs except skeletons
- Methods: `goto()`, `fill(data)`, `submit()`, `expectSuccess()`, `expectError()`
- Import types from contract
- NO test logic in Page Object

### 3. Generate test spec

Create `apps/web/e2e/<name>.spec.ts`:
- **Happy path**: fill → submit → assert UI updates
- **Validation**: submit empty → assert error messages
- **API error**: trigger known error condition → assert error shown
- **Network error**: `page.route('**/api/**', route => route.abort())` → assert retry
- **Loading**: slow route → assert skeleton visible
- Factory function with unique data per run (`Date.now().toString(36)`)
- Each test is independent — own setup, no order dependency

### 4. Run and fix
```bash
npx playwright test apps/web/e2e/<name>.spec.ts 2>&1 | tail -10
```
If selectors fail → read actual component, adjust locators.

### 5. Commit
```bash
git add apps/web/e2e/ && git commit -m "e2e(<name>): generate Playwright tests from contract"
```

## --all mode

List contracts without matching .spec.ts. Generate Page Object + spec for each.
Run all at end: `npx playwright test apps/web/e2e/ 2>&1 | tail -10`

## Rules
- E2E uses real API — never mock (except network failure simulation)
- Never `page.waitForTimeout()` — use locator assertions
- Never fragile CSS selectors (`div > span:nth-child(2)`)
- Never `any` — import types from contract
- Truncate output: `2>&1 | tail -10`
