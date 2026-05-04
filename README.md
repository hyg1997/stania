<p align="center">
  <img src="https://img.shields.io/npm/v/stania?style=flat-square&color=000" alt="npm version" />
  <img src="https://img.shields.io/npm/dm/stania?style=flat-square&color=000" alt="downloads" />
  <img src="https://img.shields.io/github/license/hyg1997/stania?style=flat-square&color=000" alt="license" />
</p>

<h1 align="center">Stania</h1>

<p align="center">
  Ship production software with AI agents.<br/>
  Contract-first. Parallel by default. Role-aware.
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> ·
  <a href="docs/workflow.md">Docs</a> ·
  <a href="docs/frontend-guide.md">Frontend Guide</a> ·
  <a href="#commands">Commands</a>
</p>

---

Stania is an engineering workflow for [Claude Code](https://claude.ai/code). It replaces vibe coding with a disciplined system: define contracts, let agents build the backend, let frontends write specs instead of code, and ship through a pipeline that catches AI mistakes before production.

```bash
npx stania
```

## Why Stania

| Without Stania | With Stania |
|----------------|-------------|
| "Build me a booking system" → fragile code, no tests, inconsistent patterns | Contract → Agent → Tested PR in minutes |
| Frontend blocked waiting for backend | Frontend works on mocks from day 1 |
| Manual review of every AI-generated line | 8 AI code smell detectors + mutation testing |
| "Where did we leave off?" between sessions | `.stania/` tracks progress, domain model, specs |
| Everyone needs to know everything | Role-aware: each person sees only what's relevant |

## Quick Start

```bash
mkdir my-app && cd my-app
npx stania
```

Open Claude Code:

```
/st-next                        → "Run /st-bootstrap to initialize"
/st-bootstrap                   → repo, CI/CD, monorepo, deploy
/st-model                       → domain model
/st-contract create-user        → API types + mocks + client
/st-agent create-user           → autonomous backend (background)
```

Frontend (simultaneously):

```
/st-next                        → "UI spec 'signup-form' ready: /st-ui signup-form"
/st-ui signup-form              → generates component from spec
/st-ui --refine signup-form     → "add hover shadow, fade-in animation"
```

## How It Works

```
 YOU (Tech Lead)              FRONTEND                    AGENT (background)
 ───────────────              ────────                    ──────────────────
 /st-contract ─────────────→  writes UI spec
 /st-agent ───────────────────────────────────────────→  implements backend
                              /st-ui (generates code)
                              /st-ui --refine (styles)         │
                                   │                           │
 review PR  ←──────────────────────────────────────────── creates PR
 /st-integrate                done                        
```

**Frontend and backend never block each other.** The contract is the interface.

## Install

```bash
npx stania            # Install in current project
npx stania@latest     # Update to latest
npx stania uninstall  # Remove
```

Per-project only. Doesn't pollute other projects or waste tokens globally.

<details>
<summary>Alternative: curl</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/hyg1997/stania/main/install.sh | bash
```
</details>

## Commands

### Guidance

| Command | Description |
|---------|-------------|
| `/st-next` | **What should I do now?** Role-aware, reads project state, suggests 1-3 actions |

### Team Workflow

| Command | Description |
|---------|-------------|
| `/st-bootstrap` | Project setup — GitHub repo, CI/CD, monorepo, Vercel + Cloud Run |
| `/st-contract` | Define API contract → generates mocks, typed client, backend ports |
| `/st-agent` | Launch autonomous backend implementation in background |
| `/st-ui` | Generate frontend component from structured spec |
| `/st-ui --refine` | Adjust styles/effects in natural language |
| `/st-integrate` | Replace mocks with real backend + run e2e |
| `/st-board` | GitHub Issues/PRs kanban board |

### Quality

| Command | Description |
|---------|-------------|
| `/st-check` | Parallel validation — typecheck + lint + tests + AI smell scan |
| `/st-e2e` | Generate Playwright E2E tests from contracts |
| `/st-migrate` | Handle contract evolution — detect breaking changes, update dependents |
| `/st-seed` | Generate realistic test fixtures (builder pattern) |
| `/st-deps` | Dependency health — security audit + auto-fix |
| `/st-mutate` | Mutation testing — are your tests actually catching bugs? |

### Pipeline

| Command | Description |
|---------|-------------|
| `/st-quick` | Fast path — validate + commit (for simple changes) |
| `/st-spec` | Formal spec with invariants, errors, edge cases |
| `/st-build` | Layer-by-layer generation — domain → app → infra |
| `/st-ship` | Pre-deploy audit + PR creation |
| `/st-retro` | Session close — decisions, docs, next steps |

### Utilities

| Command | Description |
|---------|-------------|
| `/st-model` | Extract DDD domain model → `.stania/domain-model.json` |
| `/st-status` | Progress report per bounded context |

## Frontend Workflow

The frontend person **writes specs, not code.** Claude generates everything.

**1. Pick a layout** from the catalog (9 options):

> `LIST` · `DETAIL` · `FORM` · `DASHBOARD` · `GRID` · `SIDEBAR` · `MODAL` · `SPLIT` · `EMPTY`

**2. Fill the spec** (what it shows, what users can do, what happens on error):

```markdown
# Order List

## Layout
**Layout**: LIST
**Slots**:
  - header: "Orders" + date filter
  - item-row: guest name, date, party size, status badge
  - pagination: infinite scroll

## States
| loading | 5 skeleton rows |
| empty   | "No orders yet" + create CTA |
| error   | "Failed to load" + retry |

## Interactions
| click row    | navigate to /orders/:id |
| change filter | refetch with new params |
```

**3. Generate:** `/st-ui order-list`

**4. Adjust:** `/st-ui --refine order-list` → "more shadow on hover, fade-in animation"

> Full guide: [docs/frontend-guide.md](docs/frontend-guide.md)

## Architecture

```
project/
├── apps/
│   ├── web/                  ← Next.js 15 (Vercel)
│   └── api/                  ← Backend (Cloud Run)
├── packages/
│   └── contracts/            ← Source of truth
│       └── generated/        ← mocks + client + ports (auto-generated)
└── .stania/                  ← State tracking + UI specs
```

<details>
<summary>Frontend standards (enforced automatically)</summary>

- Server Components by default — `"use client"` only for interactivity
- Feature-based folders — component + hook + test colocated
- TanStack Query for data fetching
- React Hook Form + Zod for forms
- shadcn/ui + Tailwind CSS (mobile-first)
- axe-core accessibility in every test
- 4 states mandatory: loading, empty, error, success
- Lighthouse CI: Performance ≥90, Accessibility ≥95

</details>

<details>
<summary>Backend standards (Clean Architecture + DDD)</summary>

- Domain: zero external imports, private constructors, Result pattern
- Value Objects over primitives (Email not string, Money not number)
- Ports in domain, implementations in infrastructure
- One aggregate per transaction boundary

</details>

## Quality Gates

```
Development          CI (every PR)              On demand
───────────          ─────────────              ─────────
/st-check            GitHub Actions             /st-mutate
├─ TypeScript        ├─ typecheck + lint        └─ mutation testing
├─ Biome             ├─ tests                      (>80% kill rate)
├─ Vitest + axe      ├─ Lighthouse CI
└─ AI smell scan     └─ bundle budget (<100KB)
```

## AI Code Smells

Stania detects 8 patterns that AI commonly produces:

| # | Smell | What it catches |
|---|-------|-----------------|
| 1 | API Hallucination | Methods that don't exist in the library |
| 2 | Happy Path Bias | Missing error handling |
| 3 | Invisible Coupling | Domain importing from infrastructure |
| 4 | Security Blindness | Unsanitized input, PII in logs |
| 5 | Over-engineering | Abstractions for non-existent requirements |
| 6 | Test Theater | Tests that verify nothing meaningful |
| 7 | Context Amnesia | Same problem solved differently across files |
| 8 | Stale Patterns | Using deprecated approaches |

## Role System

Stania adapts to who you are:

| Role | Sees | Focus |
|------|------|-------|
| **lead** | All commands | Contracts, architecture, PR reviews |
| **frontend** | /st-ui, /st-next, /st-ui --refine | Specs and visual adjustments |
| **pm** | /st-board, /st-next, /st-status | Progress and blockers |

Set on first run: `/st-next` → "What's your role?" → saved to `.stania/me.json`

## Token Efficiency

| Strategy | Impact |
|----------|--------|
| Per-project install | ~52K tokens saved per turn in other projects |
| Output truncation | ~80% less context from tool output |
| Parallel validation | 3 simultaneous calls instead of sequential |
| Incremental validation | Skip if unchanged since last check |
| Role filtering | Smaller skill surface per user type |

## Stack Support

Stania detects and adapts:

| | TypeScript | Python | Go |
|-|-----------|--------|-----|
| **Typecheck** | tsc strict | mypy | go vet |
| **Lint** | Biome | ruff | golangci-lint |
| **Test** | Vitest | pytest | go test |
| **Mutate** | Stryker | mutmut | go-mutesting |

## Requirements

- [Claude Code](https://claude.ai/code) (Max plan recommended for background agents)
- Node.js ≥ 18
- Git + [GitHub CLI](https://cli.github.com/) (`gh`)

## Documentation

- [Workflow Reference](docs/workflow.md) — Complete team + solo workflow details
- [Frontend Guide](docs/frontend-guide.md) — Step-by-step for frontend engineers
- [Layout Catalog](templates/layout-catalog.md) — All 9 pre-defined layouts
- [UI Standards](templates/ui-standards.md) — Architecture rules enforced on generation

## Contributing

```bash
git clone https://github.com/hyg1997/stania.git
cd stania
# Edit commands in commands/, skill in skills/st/SKILL.md
# Test: cd <any-project> && bash /path/to/stania/install.sh
```

## License

[MIT](LICENSE)

---

<p align="center">
  Built by <a href="https://github.com/cloudpetals">Cloudpetals</a>
</p>
