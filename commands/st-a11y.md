Deep accessibility audit beyond component-level axe tests.

## Usage

- `/st-a11y` — Full audit of all pages/components
- `/st-a11y <page>` — Audit specific page
- `/st-a11y --fix` — Auto-fix common issues

## Step 1: Component-level audit (static analysis)

**Run as subagent** for token isolation:

```
Scan for accessibility issues in apps/web/src/:

1. Images without alt:
   grep -rn "<img\|<Image" --include="*.tsx" apps/web/src/ | grep -v "alt=" | head -10

2. Buttons without accessible name:
   grep -rn "<button\|<Button" --include="*.tsx" apps/web/src/ | grep -v "aria-label\|children\|>" | head -10

3. Form inputs without labels:
   grep -rn "<input\|<Input\|<select\|<textarea" --include="*.tsx" apps/web/src/ | grep -v "aria-label\|htmlFor\|label\|Label" | head -10

4. Missing heading hierarchy:
   grep -rn "<h[1-6]\|<Heading" --include="*.tsx" apps/web/src/ | head -10

5. Color contrast (Tailwind):
   grep -rn "text-gray-[3-4]00\|text-slate-[3-4]00" --include="*.tsx" apps/web/src/ | head -5

6. Focus management:
   grep -rn "tabIndex\|focus-visible\|focus:" --include="*.tsx" apps/web/src/ | head -5

7. ARIA usage:
   grep -rn "aria-\|role=" --include="*.tsx" apps/web/src/ | head -10

Report: issues per category, severity (critical/warning/info), file:line.
Max 30 lines.
```

## Step 2: Runtime audit (Playwright + axe)

If Playwright is installed:
```bash
# Run axe against running app
npx playwright test --grep @a11y --reporter=dot 2>&1 | tail -15
```

If no @a11y tests exist, generate a quick scan:
```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const pages = ['/', '/dashboard', '/settings'];

for (const page of pages) {
  test(`a11y: ${page}`, async ({ page: p }) => {
    await p.goto(page);
    const results = await new AxeBuilder({ page: p })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
      .analyze();
    expect(results.violations).toEqual([]);
  });
}
```

## Step 3: Keyboard navigation check

```
For each interactive page, verify:
- [ ] All interactive elements reachable via Tab
- [ ] Focus order is logical (top→bottom, left→right)
- [ ] Modals trap focus
- [ ] Escape closes modals/drawers
- [ ] Skip link exists (jump to main content)
- [ ] No keyboard traps
```

## Step 4: Screen reader structure

Check semantic HTML:
- `<main>`, `<nav>`, `<header>`, `<footer>` landmarks present
- Headings follow hierarchy (h1 → h2 → h3, no skips)
- Lists use `<ul>`/`<ol>`, not styled divs
- Tables have `<th>` and `scope`

## Report

```
=== ACCESSIBILITY AUDIT ===
Critical: 2 (images without alt, form without label)
Warning:  5 (low contrast text, missing focus styles)
Info:     3 (ARIA could be simplified)
Runtime:  PASS (axe: 0 violations on 3 pages)
Keyboard: 2 issues (modal focus trap, skip link missing)

Score: 7/10 — GOOD (fix critical issues)
```

## --fix mode

Auto-fix common issues:
- Add `alt=""` to decorative images, `alt="description"` to meaningful ones (ask user)
- Add `aria-label` to icon-only buttons
- Replace `<div onClick>` with `<button>`
- Add `focus-visible:ring-2` to interactive elements
- Fix heading hierarchy gaps

After fixes: re-run audit to verify.

## Rules

- Delegate scanning to subagent
- Target WCAG 2.1 AA compliance
- Critical issues block /st-ship
- Never add unnecessary ARIA (semantic HTML first)
- Truncate all output
