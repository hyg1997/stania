Performance audit: Lighthouse CI, bundle analysis, Web Vitals tracking.

## Usage

- `/st-perf` — Full performance audit
- `/st-perf --lighthouse` — Lighthouse only
- `/st-perf --bundle` — Bundle analysis only
- `/st-perf --vitals` — Web Vitals check

## Step 1: Lighthouse CI

```bash
if command -v lhci &>/dev/null || npx lhci --version &>/dev/null; then
  npx lhci autorun --collect.url=http://localhost:3000 --collect.numberOfRuns=3 2>&1 | tail -20
else
  npx lighthouse http://localhost:3000 --output=json --quiet --chrome-flags="--headless" 2>&1 | tail -20
fi
```

Extract scores:
```
Performance: 92  Accessibility: 98  Best Practices: 95  SEO: 100
```

Thresholds (from config or defaults):
- Performance: >= 90
- Accessibility: >= 95
- Best Practices: >= 90

## Step 2: Bundle analysis

### Next.js
```bash
ANALYZE=true pnpm build --filter web 2>&1 | tail -20
# Or use @next/bundle-analyzer
npx next build 2>&1 | grep -E "Route|Size|First Load" | head -20
```

Check for:
- Any route > 200KB first load JS
- Total JS bundle > 500KB
- Duplicate dependencies in bundle
- Large dependencies that could be lazy-loaded

### Hono/API
```bash
pnpm build --filter api 2>&1 | tail -10
ls -lh apps/api/dist/ 2>/dev/null | tail -5
```

## Step 3: Web Vitals

If the app is running:
```bash
# Use Playwright to measure CWV
npx playwright test --grep @perf --reporter=dot 2>&1 | tail -10
```

Generate CWV test if none exists:
```typescript
test('Core Web Vitals', async ({ page }) => {
  await page.goto('/');
  const metrics = await page.evaluate(() =>
    new Promise(resolve => {
      new PerformanceObserver(list => {
        const entries = {};
        for (const entry of list.getEntries()) {
          entries[entry.name] = entry.value ?? entry.startTime;
        }
        resolve(entries);
      }).observe({ type: 'largest-contentful-paint', buffered: true });
      setTimeout(() => resolve({}), 5000);
    })
  );
});
```

Targets:
- LCP: < 2.5s
- FID/INP: < 200ms
- CLS: < 0.1

## Step 4: Optimization suggestions

Based on findings, suggest specific fixes:

| Issue | Fix | Impact |
|-------|-----|--------|
| Large images | next/image + WebP | High |
| Unoptimized fonts | next/font/google | Medium |
| Large bundle | Dynamic imports | High |
| No caching headers | Cache-Control headers | Medium |
| Render-blocking CSS | Critical CSS inline | Medium |
| Unused JS | Tree shaking + dead code | Medium |

## Report

```
=== PERFORMANCE AUDIT ===
Lighthouse:    92 / 98 / 95 / 100 (perf / a11y / bp / seo)
Bundle (web):  First Load JS: 145KB — OK
Bundle (api):  Build: 2.1MB — OK
Web Vitals:    LCP 1.8s / INP 120ms / CLS 0.05 — ALL GOOD

ISSUES:
- /dashboard route: 280KB first load (over 200KB target)
  → Dynamic import for chart component

VERDICT: [PASS] Performance within targets
```

## Rules

- Dev server must be running for Lighthouse/Vitals
- If no dev server: suggest `pnpm dev` first
- Lighthouse runs 3 times, reports median
- Bundle thresholds are warnings, not blockers
- Truncate all output
- Suggest only actionable improvements (no theoretical optimizations)
