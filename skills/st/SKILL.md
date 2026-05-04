---
name: st
description: "Engineering workflow with state tracking. Contract-first parallel development. Role-aware guidance. 5-stage pipeline: SPEC → BUILD → CHECK → SHIP → RETRO. Team mode: agents + interns work in parallel."
---

# Stania — Engineering Workflow

You are operating under Stania engineering discipline.

## Role Detection (ALWAYS check first)

On session start, read `.stania/me.json`. If missing, ask:
"¿Cuál es tu rol? (lead / frontend / pm)" → create file.

```json
{ "role": "lead|frontend|pm", "name": "Name" }
```

### Role-based behavior:

**lead** — Full access. Proactively suggest: pending PR reviews, contracts without agents, integrations ready.
**frontend** — Only suggest: /st-ui, /st-ui --refine, /st-ui --new, /st-next. Hide backend complexity.
**pm** — Only suggest: /st-board, /st-next, /st-status. Focus on progress and blockers.

When user asks a vague question ("qué hago?" / "what's next?"), run /st-next logic internally.

## Two Modes

### Solo mode (one engineer + Claude):
SPEC → BUILD → CHECK → SHIP → RETRO

### Team mode (contract-first, parallel):
CONTRACT → agents implement backend + frontend implements UI → INTEGRATE → SHIP

## State (.stania/)

State is **advisory, not blocking**. If missing, commands fall back to filesystem scanning.

```
.stania/
├── me.json              ← Current user role (gitignored)
├── config.json          ← Stack, architecture, deploy, team settings
├── domain-model.json    ← Bounded contexts, aggregates, VOs, events
├── progress.json        ← Per-aggregate implementation status
├── specs/{slug}.md      ← Approved specs
└── ui-specs/{name}.md   ← UI component specs (for /st-ui)
```

## Pipeline Commands

| Command | Who | Purpose |
|---------|-----|---------|
| /st-next | Anyone | **What should I do now?** (role-aware guidance) |
| /st-quick | Anyone | T1/T2: validate → commit (no ceremony) |
| /st-contract | Lead | Define API contract → generates mocks + ports + client |
| /st-agent | Lead | Launch autonomous backend implementation |
| /st-ui | Frontend | Generate component from UI spec |
| /st-ui --refine | Frontend | Adjust styles in natural language |
| /st-board | PM/Lead | Show GitHub Issues/PRs status board |
| /st-integrate | Lead | Replace mocks with real backend + e2e |
| /st-e2e | Lead | Generate Playwright E2E tests from contracts |
| /st-migrate | Lead | Handle contract evolution (breaking changes) |
| /st-seed | Anyone | Generate realistic test fixtures |
| /st-deps | Lead | Dependency health audit + auto-fix |
| /st-spec | Lead | Formal spec (when contract isn't enough) |
| /st-build | Lead | Layer-by-layer generation with approval |
| /st-check | Anyone | Validation pipeline (parallel) |
| /st-ship | Lead | Incremental audit + PR |
| /st-retro | Anyone | Session close |
| /st-bootstrap | Lead | Project setup (repo, deploy, CI/CD) |
| /st-model | Lead | DDD domain model extraction |
| /st-mutate | Anyone | Mutation testing (on demand) |
| /st-status | Anyone | Progress from .stania/progress.json |

## Proactive Guidance

After any command completes, suggest the logical next step:

- After /st-bootstrap → "Run /st-model to define your domain"
- After /st-model → "Run /st-contract <first-feature> to define first API"
- After /st-contract → "Run /st-agent <name> to start backend. Frontend: write spec in ui-specs/"
- After /st-agent completes → "PR ready. Review then /st-integrate"
- After /st-ui → "Review in Storybook. Adjust with /st-ui --refine"
- After /st-integrate → "Run /st-e2e <name> for end-to-end tests"
- After /st-check fails → Suggest specific fix, then "re-run /st-check"
- After /st-ship → "/st-retro to close session"

## Core Principles

1. Right-size ceremony — /st-quick for simple, full pipeline for complex
2. Contract-first — define API surface before implementation
3. Parallel by default — frontend and backend work simultaneously via mocks
4. Agents do execution — humans make decisions
5. Validate once — /st-check owns validation, /st-build does NOT re-run it
6. Truncate output — `| tail -N` always, read full only on failure
7. Merge = deploy — no manual deploys
8. Role-aware — show only what's relevant to the user's role

## AI Code Smells

1. API Hallucination — invented methods
2. Happy Path Bias — no error handling
3. Invisible Coupling — domain depends on infra
4. Security Blindness — unsanitized input, PII in logs
5. Over-engineering — premature abstractions
6. Test Theater — tests that verify nothing
7. Context Amnesia — inconsistent patterns
8. Stale Patterns — deprecated approaches

## Review Tiers

- **T1 Auto**: UI, config, cosmetic → /st-quick
- **T2 Light**: New features → pipeline + PR review
- **T3 Deep**: Domain, security, billing → full pipeline + mutations

## Clean Architecture (when applicable)

- Domain: ZERO external imports, private constructors + factory, Result pattern
- Value Objects over primitives (Email not string, Money not number)
- Ports in domain, implementations in infrastructure

## Token Efficiency Rules

1. **Truncate all tool output**: Always `| tail -N`. Read full only on failure.
2. **No duplicate validation**: /st-build does typecheck only.
3. **Incremental /st-ship**: Skip re-validation if lastCheck < 10 min.
4. **Parallel validation**: In /st-check, typecheck + lint + tests as 3 simultaneous calls.
5. **Lazy loading**: Only read the specific aggregate/spec needed.
6. **testFlags config**: Read `config.json` → `testFlags.fast` for flags.
7. **Session split**: After heavy iterations, suggest new session.
8. **Context7 MCP**: If available, use for API hallucination checks.

## Stack Detection

1. `.stania/config.json` → 2. package.json/pyproject.toml/go.mod → 3. Ask user

| Stack | Typecheck | Lint | Test | Mutate |
|-------|-----------|------|------|--------|
| TS | tsc | Biome | Vitest | Stryker |
| Python | mypy | ruff | pytest | mutmut |
| Go | go vet | golangci-lint | go test | go-mutesting |
