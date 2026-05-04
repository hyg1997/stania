# Stania

**AI engineering workflow for Claude Code. Ship production software with a 2-person team.**

Stania turns Claude Code into a disciplined engineering system: contract-first parallel development, autonomous agents for backend, structured specs for frontend, and a pipeline that catches AI mistakes before they hit production.

## Who is this for

- Small teams (2-3 engineers + frontend interns) building SaaS products
- Teams using Claude Code Max that want predictable, high-quality output
- Anyone tired of "vibe coding" producing fragile, untested code

## How it works

```
Tech Lead                    Frontend                  Agent (background)
─────────                    ────────                  ──────────────────
/st-bootstrap                                         
/st-model                                             
     │                                                
/st-contract ──────────────→ writes UI spec           
/st-agent ─────────────────────────────────────────→ implements backend
     │                       /st-ui (generates code)  
     │                       /st-ui --refine          
     │                            │                        │
review PR ←─────────────────────────────────────────── creates PR
/st-integrate                adjusts in Storybook     
/st-contract (next) ───────→ next spec                
```

**Frontend and backend never block each other.** The contract (types + mocks) is the interface.

## Install

```bash
npx stania
```

Installs commands and skill to `.claude/` in your current project. Per-project only — doesn't pollute other projects.

```bash
npx stania@latest     # Update to latest
npx stania uninstall  # Remove from project
```

Or via curl:
```bash
curl -fsSL https://raw.githubusercontent.com/cloudpetals/stania/main/install.sh | bash
```

## Quick Start

```bash
mkdir my-project && cd my-project
npx stania                      # Install Stania
# Open Claude Code, then:
/st-bootstrap                   # Creates repo, CI/CD, monorepo, .stania/
/st-model                       # Define domain model
/st-contract create-user        # First API contract → mocks + types + client
/st-agent create-user           # Agent builds backend autonomously
# Meanwhile, frontend writes spec → /st-ui generates component
```

## Commands

### Team Workflow (contract-first)

| Command | Who | What |
|---------|-----|------|
| `/st-bootstrap` | Tech Lead | Project setup: GitHub repo, CI/CD, monorepo, deploy |
| `/st-contract` | Tech Lead | Define API contract → generates mocks + ports + client |
| `/st-agent` | Tech Lead | Launch autonomous backend implementation (background) |
| `/st-ui` | Frontend | Generate component from structured UI spec |
| `/st-ui --refine` | Frontend | Adjust styles/effects in natural language |
| `/st-board` | PM/Lead | GitHub Issues/PRs status board |
| `/st-integrate` | Tech Lead | Replace mocks with real backend + e2e tests |

### Engineering Pipeline (solo mode)

| Command | Stage | What |
|---------|-------|------|
| `/st-quick` | — | Fast path: validate → commit (T1/T2 changes) |
| `/st-spec` | 1 | Formal spec with invariants and edge cases |
| `/st-build` | 2 | Layer-by-layer generation (domain → app → infra) |
| `/st-check` | 3 | Parallel validation (typecheck + lint + tests) + AI smell scan |
| `/st-ship` | 4 | Pre-deploy audit + PR creation |
| `/st-retro` | 5 | Session close: decisions, docs, next steps |

### Utilities

| Command | What |
|---------|------|
| `/st-model` | Extract DDD domain model → `.stania/domain-model.json` |
| `/st-mutate` | Mutation testing (are your tests actually catching bugs?) |
| `/st-status` | Progress report from `.stania/progress.json` |

## Frontend Workflow

The frontend person **never writes component code**. They write a structured spec and Claude generates everything.

### 1. Copy template

```bash
cp .stania/ui-specs/_TEMPLATE.md .stania/ui-specs/my-component.md
```

### 2. Fill the spec

```markdown
# Order List

## Meta
- **Type**: page
- **Route**: /orders
- **Contract**: list-orders
- **Priority**: P0

## Layout
**Layout**: LIST    ← pick from catalog (LIST, DETAIL, FORM, DASHBOARD, GRID, SIDEBAR, MODAL, SPLIT)

**Slots**:
  - header: "Orders" + date filter + export button
  - filters: status (all/pending/confirmed/cancelled)
  - item-row: order card with guest name, date, party size, status badge
  - pagination: infinite scroll

## States
| State | UI |
|-------|-----|
| loading | 5 skeleton rows |
| empty | "No orders yet" + CTA to create |
| error | "Failed to load" + retry |
| success | order list |

## Interactions
| Trigger | Action | Result |
|---------|--------|--------|
| click order | navigate | /orders/:id |
| change filter | refetch | filtered list |
| scroll bottom | load more | append orders |
```

### 3. Generate

```
/st-ui order-list
```

Claude reads your spec + `ui-standards.md` + `layout-catalog.md` + contract types, and generates:
- Server + Client components (proper RSC split)
- TanStack Query hooks with contract types
- Loading skeletons matching layout dimensions
- Tests with accessibility assertions (axe-core)
- Mobile-first responsive from layout catalog

### 4. Refine visually

```
/st-ui --refine order-list
```

> "More shadow on hover, fade-in animation when items load, status badges with colored backgrounds"

Claude edits only Tailwind classes. No architecture changes.

## Layout Catalog

Pre-defined layouts in `.stania/layout-catalog.md`. Each has slots, responsive behavior, and component structure:

| Layout | Use for |
|--------|---------|
| **LIST** | Tables, feeds, search results |
| **DETAIL** | Single resource view with tabs |
| **FORM** | Single or multi-step forms |
| **DASHBOARD** | KPIs, charts, metrics overview |
| **GRID** | Card grids (products, gallery, team) |
| **SIDEBAR** | Settings, admin, docs navigation |
| **MODAL** | Confirmations, quick-create, previews |
| **SPLIT** | Chat, master-detail, comparisons |
| **EMPTY** | Zero-data states, onboarding |

## Architecture

### Project Structure (monorepo)

```
project/
├── apps/
│   ├── web/                  ← Next.js 15 (Vercel)
│   └── api/                  ← Backend (Cloud Run)
├── packages/
│   └── contracts/            ← Source of truth (shared types + mocks)
│       ├── create-order.ts
│       └── generated/
│           ├── mocks/        ← MSW handlers (frontend uses these)
│           ├── client/       ← Typed API client
│           └── ports/        ← Backend interfaces
├── .stania/
│   ├── config.json
│   ├── domain-model.json
│   ├── ui-standards.md
│   ├── layout-catalog.md
│   └── ui-specs/
└── .github/workflows/
```

### Frontend Architecture (enforced by ui-standards.md)

- **Server Components by default** — `"use client"` only for interactivity
- **Feature-based folders** — component + hook + test colocated
- **TanStack Query** for client data fetching
- **React Hook Form + Zod** for forms
- **shadcn/ui** as component library
- **Tailwind CSS** mobile-first
- **axe-core** in every test (accessibility)
- **4 states mandatory**: loading, empty, error, success

### Backend Architecture (Clean Architecture + DDD)

- **Domain**: Zero external imports, private constructors, Result pattern
- **Application**: Use cases, command/query handlers
- **Infrastructure**: Adapters, repositories, framework wiring
- **Ports in domain**, implementations in infrastructure

## Quality Gates

### In development (/st-check)
- TypeScript strict (no `any`, no unchecked index)
- Biome lint + format
- Vitest tests with axe-core accessibility
- AI code smell scan (8 patterns)

### In CI (GitHub Actions)
- All of the above +
- Lighthouse CI: Performance ≥90, Accessibility ≥95, Best Practices ≥90
- Bundle size budget: <100KB JS first-load per route

### On demand (/st-mutate)
- Mutation testing: >80% kill rate on domain logic

## Token Efficiency

Stania is designed to minimize Claude Code token consumption:

1. **Per-project install** — skill only loads in this project (~1,100 tokens vs 0 in others)
2. **Output truncation** — all tool output piped through `| tail -N`
3. **Parallel validation** — typecheck + lint + tests as 3 simultaneous calls
4. **Incremental /st-ship** — skips re-validation if lastCheck < 10 minutes
5. **Lazy loading** — only reads the specific aggregate/spec needed
6. **No duplicate validation** — /st-build only typechecks, /st-check owns full validation

## AI Code Smells (checked by /st-check)

1. **API Hallucination** — invented methods that don't exist
2. **Happy Path Bias** — no error handling
3. **Invisible Coupling** — domain depends on infrastructure
4. **Security Blindness** — unsanitized input, PII in logs
5. **Over-engineering** — premature abstractions
6. **Test Theater** — tests that verify nothing
7. **Context Amnesia** — inconsistent patterns
8. **Stale Patterns** — deprecated approaches

## Requirements

- [Claude Code](https://claude.ai/code) (Max plan recommended for agents)
- Node.js ≥18
- Git
- GitHub CLI (`gh`) for /st-bootstrap, /st-board, /st-agent

## Stack Support

Stania detects and adapts to your stack:

| Stack | Typecheck | Lint | Test | Mutate |
|-------|-----------|------|------|--------|
| TypeScript | tsc strict | Biome | Vitest | Stryker |
| Python | mypy | ruff | pytest | mutmut |
| Go | go vet | golangci-lint | go test | go-mutesting |

## License

MIT — [Cloudpetals](https://github.com/cloudpetals)
