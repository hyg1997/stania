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
RESUME → SPEC → BUILD → CHECK → SHIP → HEALTH → MONITOR → RETRO
```

For individual features where you're doing both design and implementation.

### Session Start

```
/st-resume    → briefing from last session + suggested next action
```

### Fast Path (/st-quick)

For T1/T2 changes (UI tweaks, config, simple features):
```
/st-quick    → implement → validate (truncated) → commit
```

No spec, no approval gates. Just validated code.

### Full Pipeline

```
/st-spec     → invariants, errors, edge cases → .stania/specs/
/st-build    → domain → application → infrastructure (+ visual self-check with agent-browser)
/st-check    → typecheck + lint + tests (parallel) + AI smell scan + REVIEW.md
/st-ship     → audit + schema validation + PR
/st-health   → post-deploy smoke test (endpoints alive?)
/st-monitor  → E2E tests against production (Playwright + Schemathesis)
/st-retro    → session close + snapshot
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
| `config.json` | Stack, architecture, deploy, testing profile | Committed |
| `domain-model.json` | Bounded contexts, aggregates, events | Committed |
| `ui-standards.md` | Frontend architecture rules | Committed |
| `layout-catalog.md` | Pre-defined layout patterns | Committed |
| `progress.json` | Per-aggregate layer completion | Gitignored |
| `specs/*.md` | Approved feature specs | Gitignored |
| `ui-specs/*.md` | UI component specs | Committed |
| `reviews/` | REVIEW-date.md from /st-check | Gitignored |
| `snapshots.json` | State snapshots for velocity tracking | Gitignored |
| `costs.json` | Token cost history per session | Gitignored |

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

## Testing Profiles

Set during `/st-bootstrap`. Controls validation rigor across all commands.

| Profile | Coverage (Domain/App/Overall) | Mutation | Schema Validation | Use When |
|---------|-------------------------------|----------|-------------------|----------|
| **mvp** | 60% / 40% / 60% | Skipped | Skipped | Prototyping, hackathons, MVPs |
| **production** | 80% / 60% / 80% | 80% kill rate | If OpenAPI exists | Most production apps |
| **hardened** | 100% / 80% / 90% | 100% kill rate | Required | Finance, health, compliance |

Profile stored in `.stania/config.json` → `testingProfile`. All commands auto-adapt.

---

## Pre-Production & Production Testing

### Strategy

```
/st-ship (pre-deploy)
  ├── Playwright tests (local)
  ├── Schemathesis API validation (if OpenAPI spec)
  └── Contract vs implementation check
        ↓
/st-deploy
        ↓
/st-health (smoke test)
  ├── Frontend: HTTP 200, load time < 3s
  ├── API: /health endpoint, response time < 1s
  └── Critical endpoints: status codes
        ↓
/st-monitor (ongoing)
  ├── Playwright E2E against production URL
  ├── Schemathesis schema validation
  └── Authenticated flows (test account)
```

### Test Account Setup

1. Add to `.stania/config.json`:
   ```json
   { "testing": { "testAccountEmail": "test@yourapp.com", "testAccountFlag": "is_test" } }
   ```
2. Add `is_test` boolean column to user table
3. Filter test accounts from analytics and billing
4. E2E tests authenticate as test account for protected flows

### Optional: CI Monitoring

Add `.github/workflows/monitor.yml` for scheduled production tests:
```yaml
on:
  schedule:
    - cron: '*/15 * * * *'
jobs:
  monitor:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx playwright install chromium
      - run: BASE_URL=${{ secrets.PROD_URL }} npx playwright test --grep @monitor
```

### Optional: Checkly (SaaS monitoring)

If you want 24/7 monitoring from multiple locations:
```bash
npx checkly deploy  # deploys your .spec.ts files as monitors
```
Free tier: 10 monitors, 1K browser runs/month.

---

## agent-browser Integration

Vercel's agent-browser provides AI agent browser automation via CLI. Used for visual self-verification during build.

### When it's used

| Command | How | Token Cost |
|---------|-----|------------|
| /st-build | Snapshot accessibility tree after generating UI | ~1K tokens |
| /st-ui | Verify component renders, all 4 states work | ~1K tokens |

### How it works

```bash
agent-browser open http://localhost:3000/page
agent-browser snapshot                    # accessibility tree with @refs
agent-browser click @e3                   # interact by ref
agent-browser get text @e1               # extract text
```

Key: uses accessibility tree (~1K tokens) instead of screenshots (~15K tokens).
If not installed: all commands skip visual verification silently.

### vs Playwright

| Use | Tool |
|-----|------|
| AI self-verification during build | agent-browser (token-efficient) |
| Structured E2E tests in CI | Playwright (deterministic, cross-browser) |
| Production monitoring | Playwright via /st-monitor |
| Visual regression | Playwright `toHaveScreenshot()` |

They are complementary, not competing.

---

## Token Efficiency

| Strategy | Savings |
|----------|---------|
| Per-project install (not global) | ~52K tokens/turn in other projects |
| Output truncation (`\| tail -N`) | ~80% less context from tool output |
| PreToolUse hook (auto-truncate) | Prevents 5-50K accidental verbose output |
| Parallel validation (3 simultaneous) | Same result, fewer turns |
| Incremental /st-ship | Skip re-validation if <10 min |
| Lazy domain model loading | Only read relevant bounded context |
| testFlags in config | No re-calculating runner flags |
| Model routing (Haiku/Sonnet/Opus) | 40-60% on routable commands |
| Effort-level switching | Up to 3x on simple commands |
| Subagent delegation for tests | 5-10K tokens/check cycle |
| /compact after heavy commands | Extends sessions 60-80% |
| /btw for side questions | Avoids context accumulation |
| Context7 MCP | 65% less tokens for doc lookups |
| agent-browser (vs Playwright MCP) | 82% less tokens for visual checks |

### Model Routing Guide

| Model | Commands | Why |
|-------|----------|-----|
| Haiku ($1/$5 per 1M) | /st-status, /st-next, /st-cost, /st-health, /st-resume, /st-snapshot | Read-only, simple logic |
| Sonnet ($3/$15 per 1M) | /st-build, /st-agent, /st-check, /st-ui, /st-e2e, /st-monitor | Implementation, validation |
| Opus ($5/$25 per 1M) | /st-spec, /st-model, /st-migrate, /st-ship | Architecture, critical decisions |

### Effort Level Guide

| Level | Commands | Savings vs High |
|-------|----------|-----------------|
| Low | /st-quick, /st-status, /st-next, /st-health, /st-resume | ~3x cheaper |
| Medium | /st-build, /st-check, /st-ui, /st-agent, /st-e2e | ~1.5x cheaper |
| High | /st-spec, /st-model, /st-ship, /st-migrate | Full analysis |
