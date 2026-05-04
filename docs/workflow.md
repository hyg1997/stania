# Stania — Workflow Reference

Complete reference for both team and solo workflows.

## Team Workflow (Contract-First)

### Overview

```
CONTRACT → parallel { agent(backend), frontend(UI) } → INTEGRATE → SHIP
```

The contract is the interface between frontend and backend. Once defined, both sides work independently using mocks.

### Day-by-Day Example

#### Day 0: Project Setup

```
/st-bootstrap     → repo, CI/CD, monorepo, deploy config
/st-model         → domain model (bounded contexts, aggregates)
```

**Output**: GitHub repo (private), apps/web + apps/api + packages/contracts, CI/CD workflows, .stania/ initialized.

#### Day 1: First Feature

**Tech Lead:**
```
/st-contract create-reservation    → defines endpoint, types, mocks
/st-agent create-reservation       → autonomous backend implementation
```

**Frontend (simultaneously):**
```
# Write .stania/ui-specs/reservation-form.md (from template)
/st-ui reservation-form            → generates component with mocks
/st-ui --refine reservation-form   → visual adjustments
```

#### Day 2: Integration

**When agent finishes (push notification):**
```
# Review PR → approve → merge
/st-integrate reservation-form     → replace mocks with real API
```

#### Day 3+: Steady Cadence

```
MORNING:   /st-board → see all work status
           /st-contract X → define next feature
           /st-agent X → launch agent

DURING:    Frontend writes specs → /st-ui → /st-ui --refine

ON PR:     Review → merge → /st-integrate

FRIDAY:    /st-retro → close week
```

### Roles

| Role | Responsibilities | Commands Used |
|------|-----------------|--------------|
| Tech Lead | Architecture, contracts, decisions, review PRs | /st-bootstrap, /st-contract, /st-agent, /st-integrate, /st-ship |
| Frontend | UI specs, visual review in Storybook | /st-ui, /st-ui --refine |
| PM/Lead | Track progress, priorities | /st-board, /st-status |

### Contract Flow (detailed)

```
/st-contract create-order
     │
     ├── packages/contracts/create-order.ts (Zod schemas + types)
     │
     ├── packages/contracts/generated/
     │   ├── mocks/create-order.mock.ts     (MSW handler)
     │   ├── client/create-order.ts         (typed fetch wrapper)
     │   └── ports/create-order.port.ts     (backend interface)
     │
     └── GitHub Issue (label: "agent")
```

Frontend imports from `generated/client/` and `generated/mocks/`.
Backend implements `generated/ports/`.
Types are shared — zero drift.

---

## Solo Workflow (Pipeline)

### Overview

```
SPEC → BUILD → CHECK → SHIP → RETRO
```

For individual features where you're doing both design and implementation.

### Fast Path (/st-quick)

For T1/T2 changes (UI tweaks, config, simple features):
```
/st-quick    → implement → validate (truncated) → commit
```

No spec, no approval gates. Just validated code.

### Full Pipeline

```
/st-spec     → invariants, errors, edge cases → .stania/specs/
/st-build    → domain → application → infrastructure (layer by layer)
/st-check    → typecheck + lint + tests (parallel) + AI smell scan
/st-ship     → audit + PR
/st-retro    → session close
```

---

## Frontend Workflow (detailed)

### What the frontend person does

1. **Copies template**: `.stania/ui-specs/_TEMPLATE.md` → `.stania/ui-specs/<name>.md`
2. **Picks a layout** from `.stania/layout-catalog.md` (8 options)
3. **Fills slots**: what goes in each area of the layout
4. **Defines states**: loading, empty, error, success
5. **Lists interactions**: what the user can do
6. **Optionally adds design notes**: animations, specific component choices

### What Claude generates

```
features/<name>/
├── components/
│   ├── <name>.tsx              ← Server Component
│   ├── <name>.client.tsx       ← Client (interactive parts only)
│   ├── <name>.skeleton.tsx     ← Loading state
│   └── <name>.error.tsx        ← Error boundary
├── hooks/
│   └── use-<resource>.ts      ← TanStack Query with contract types
├── lib/
│   └── <name>.utils.ts        ← Pure functions
└── __tests__/
    └── <name>.test.tsx        ← Testing Library + axe-core
```

### Making visual adjustments

**Option A — Direct edit** (if frontend knows Tailwind):
Edit classes in the .tsx file directly.

**Option B — /st-ui --refine** (natural language):
```
/st-ui --refine order-list
> "hover shadow on cards, fade-in animation, status badges with colored backgrounds"
```

Claude edits Tailwind classes only. Never breaks architecture.

**Option C — Update spec + regenerate** (structural changes):
Update the spec → run `/st-ui <name>` again.

### Layout Catalog Reference

| Layout | Slots | Mobile Behavior |
|--------|-------|-----------------|
| LIST | header, filters, item-row, pagination | Filters above list, rows become cards |
| DETAIL | header, hero, key-info, tabs | Hero above info, tabs become accordion |
| FORM | header, fields, footer | Full-width, sticky footer |
| DASHBOARD | header, kpi-cards, main-chart, side-panel, table | KPIs 2-col, chart full-width, panel below |
| GRID | header, card (repeated) | 1→2→3-4 columns |
| SIDEBAR | nav, content | Nav becomes drawer |
| MODAL | header, body, footer | Full-screen sheet |
| SPLIT | left-panel, right-panel | One panel at a time |
| EMPTY | illustration, title, description, cta | Centered, constrained width |

---

## State Management

### Files in .stania/

| File | Purpose | Git |
|------|---------|-----|
| `config.json` | Stack, architecture, deploy, team settings | Committed |
| `domain-model.json` | Bounded contexts, aggregates, events | Committed |
| `ui-standards.md` | Frontend architecture rules | Committed |
| `layout-catalog.md` | Pre-defined layout patterns | Committed |
| `progress.json` | Per-aggregate layer completion | Gitignored |
| `specs/*.md` | Approved feature specs | Gitignored |
| `ui-specs/*.md` | UI component specs | Committed |

### Design Rules

1. **Advisory, not blocking** — commands work without `.stania/`
2. **Read-merge-write** — never overwrite blindly
3. **Human-readable** — users can inspect and edit JSON
4. **Graceful degradation** — missing state = filesystem scanning fallback

---

## Agent Workflow (detailed)

### What /st-agent does

1. Reads contract + domain model
2. Creates feature branch (`feat/<context>/<name>`)
3. Implements: domain → application → infrastructure → route
4. Runs /st-check (typecheck + lint + tests)
5. Commits with conventional message
6. Creates PR with description + labels
7. Sends push notification

### Requirements

- Claude Code Max plan (for background agents)
- GitHub CLI (`gh`) authenticated
- Contract must exist (run /st-contract first)

### What to review in agent PRs

- Domain model alignment (are invariants correct?)
- Error handling (all contract error codes covered?)
- Security (input validation at boundary)
- Tests meaningful (not test theater)

---

## CI/CD Pipeline

### PR Checks (ci.yml)

```yaml
jobs:
  check:          # typecheck + lint + test
  lighthouse:     # Performance ≥90, A11y ≥95, BP ≥90
```

### Deploy (deploy.yml, on merge to main)

```yaml
jobs:
  deploy-web:     # Vercel (frontend)
  deploy-api:     # Cloud Run (backend)
```

### Required Secrets

| Secret | For |
|--------|-----|
| `VERCEL_TOKEN` | Frontend deploy |
| `VERCEL_ORG_ID` | Vercel organization |
| `VERCEL_PROJECT_ID` | Vercel project |
| `GCP_SA_KEY` | Cloud Run deploy |

---

## Review Tiers

| Tier | Scope | Process |
|------|-------|---------|
| T1 Auto | UI, config, cosmetic | /st-quick → commit |
| T2 Light | New features | Pipeline + PR review |
| T3 Deep | Domain, security, billing | Full pipeline + mutations + manual review |

---

## Clean Architecture Reference

```
┌─────────────────────────────────────────┐
│              Presentation               │
│         (Routes, Controllers)           │
├─────────────────────────────────────────┤
│              Application                │
│    (Use Cases, Command/Query Handlers)  │
├─────────────────────────────────────────┤
│               Domain                    │
│  (Entities, Value Objects, Aggregates,  │
│   Domain Events, Port interfaces)       │
│      ZERO external dependencies.        │
├─────────────────────────────────────────┤
│            Infrastructure               │
│   (Repositories, External Services,     │
│    Framework adapters, DI container)    │
└─────────────────────────────────────────┘
```

### Rules
- Dependencies flow inward only
- Domain depends on nothing
- Private constructors + factory methods
- Result pattern for fallible operations
- Value Objects over primitives
- Ports in domain, implementations in infrastructure

---

## AI Code Smells

| # | Smell | Detection |
|---|-------|-----------|
| 1 | API Hallucination | Check external calls against actual types |
| 2 | Happy Path Bias | Missing try/catch, unchecked nulls |
| 3 | Invisible Coupling | Domain imports from infrastructure |
| 4 | Security Blindness | Unsanitized input, PII in logs |
| 5 | Over-engineering | Abstractions for non-existent requirements |
| 6 | Test Theater | Tests with only `toBeDefined()` |
| 7 | Context Amnesia | Same problem solved differently |
| 8 | Stale Patterns | Deprecated APIs |

---

## Token Efficiency

| Strategy | Savings |
|----------|---------|
| Per-project install (not global) | ~52K tokens/turn in other projects |
| Output truncation (`\| tail -N`) | ~80% less context from tool output |
| Parallel validation (3 simultaneous) | Same result, fewer turns |
| Incremental /st-ship | Skip re-validation if <10 min |
| Lazy domain model loading | Only read relevant bounded context |
| testFlags in config | No re-calculating runner flags |
