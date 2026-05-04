# UI Standards

Rules that /st-ui ALWAYS applies when generating frontend code.
This file is copied to `.stania/ui-standards.md` during /st-bootstrap.

## Architecture

### Component Structure (feature-based)
```
features/<feature>/
├── components/
│   ├── <name>.tsx              ← Server Component (default)
│   ├── <name>.client.tsx       ← Client Component (only if interactive)
│   ├── <name>.skeleton.tsx     ← Loading state
│   └── <name>.error.tsx        ← Error boundary fallback
├── hooks/
│   └── use-<resource>.ts      ← Data fetching (TanStack Query)
├── lib/
│   └── <logic>.ts             ← Pure functions, no React
└── __tests__/
    └── <name>.test.tsx        ← Testing Library + axe-core
```

### Rules
- Server Components by default. `"use client"` ONLY for: event handlers, useState, useEffect, browser APIs
- Maximum 1 `"use client"` boundary per feature — push it as deep as possible
- Props interface exported from component file. Never `any`.
- Barrel exports prohibited. Import from specific files.
- Relative imports within feature. `@/` alias for cross-feature.

## Styling

- Tailwind CSS only. No CSS modules, no styled-components, no inline styles object.
- Mobile-first: write `sm:` `md:` `lg:` — never `max-*` breakpoints.
- Design tokens via CSS variables in `globals.css` (shadcn/ui theme).
- Spacing: use Tailwind scale (4, 6, 8, 12, 16). No arbitrary values unless unavoidable.
- Dark mode: always support via `dark:` variant. Use semantic colors from theme.

## Components

- shadcn/ui as base. Extend, don't wrap.
- Form: React Hook Form + Zod resolver. Always.
- State machines: for 3+ states, use explicit union type (not boolean flags).
- No prop drilling beyond 2 levels — use composition or context.

## Data Fetching

- TanStack Query for client-side. Server Components for static/SSR.
- API client from `packages/contracts/generated/client/`.
- Types from contract — never re-define response types locally.
- Optimistic updates for mutations that affect visible UI.

## Performance

- Images: next/image always. Explicit width/height. Priority for LCP.
- Fonts: next/font. No external font CDNs.
- Dynamic imports for below-fold content and heavy libs (charts, editors).
- No layout shift: reserve space with skeleton matching final dimensions.
- Bundle budget: < 100KB JS first-load per route.

## Accessibility

- Semantic HTML first (nav, main, section, article, button — not div for everything).
- ARIA only when semantic HTML isn't enough.
- Keyboard navigable: all interactive elements focusable, logical tab order.
- Focus management: trap in modals, restore on close.
- Color contrast: WCAG AA minimum (4.5:1 text, 3:1 large text).
- Screen reader: meaningful alt text, aria-live for dynamic content.
- Test: every component test includes `axe()` accessibility assertion.

## States (mandatory for every component with data)

Every data-driven component MUST handle all 4 states:
1. **loading** — Skeleton that matches final layout dimensions
2. **empty** — Helpful message + primary CTA (never blank screen)
3. **error** — What went wrong + retry action
4. **success** — The actual content

## Responsive Breakpoints

| Token | Width | Target |
|-------|-------|--------|
| (base) | 0-639px | Phone portrait |
| sm | 640px+ | Phone landscape |
| md | 768px+ | Tablet |
| lg | 1024px+ | Desktop |
| xl | 1280px+ | Wide desktop |

## Testing

- Testing Library: query by role, not by test-id (test-id as last resort).
- Test user behavior, not implementation (click button → see result).
- Every component test: accessibility check with `vitest-axe`.
- Hooks: test via `renderHook` from Testing Library.
- No snapshot tests. They break on any change and catch nothing.
