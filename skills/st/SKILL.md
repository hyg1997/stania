---
name: st
description: "Engineering workflow with state tracking. Contract-first parallel development. 5-stage pipeline: SPEC → BUILD → CHECK → SHIP → RETRO. Team mode: agents + interns work in parallel."
---

# Stania — Engineering Workflow

You are operating under Stania engineering discipline.

## Two Modes

### Solo mode (one engineer + Claude):
SPEC → BUILD → CHECK → SHIP → RETRO

### Team mode (contract-first, parallel):
CONTRACT → agents implement backend + interns implement frontend → INTEGRATE → SHIP

## State (.stania/)

State is **advisory, not blocking**. If missing, commands fall back to filesystem scanning.

```
.stania/
├── config.json          ← Stack, architecture, deploy, team settings
├── domain-model.json    ← Bounded contexts, aggregates, VOs, events
├── progress.json        ← Per-aggregate implementation status
├── specs/{slug}.md      ← Approved specs
└── ui-specs/{name}.md   ← UI component specs (for /st-ui)
```

Key fields:
- **config.json**: `stack.*`, `architecture`, `deploy.{frontend,backend}`, `team.{workflow,agents}`
- **progress.json**: `aggregates.{"Context/Aggregate": {status,layers,specPath,lastCheck}}`

## Pipeline Commands

| Command | Who | Purpose |
|---------|-----|---------|
| /st-quick | Anyone | T1/T2: validate → commit (no ceremony) |
| /st-contract | Tech Lead | Define API contract → generates mocks + ports + client |
| /st-agent | Tech Lead | Launch autonomous backend implementation |
| /st-ui | Intern/Lead | Generate component from UI spec |
| /st-board | PM/Lead | Show GitHub Issues/PRs status board |
| /st-spec | Engineer | Formal spec (when contract isn't enough) |
| /st-build | Engineer | Layer-by-layer generation with approval |
| /st-check | Anyone | Validation pipeline (parallel) |
| /st-integrate | Lead | Replace mocks with real backend + e2e |
| /st-ship | Lead | Incremental audit + PR |
| /st-retro | Anyone | Session close |
| /st-bootstrap | Lead | Project setup (repo, deploy, CI/CD) |
| /st-model | Lead | DDD domain model extraction |
| /st-mutate | Anyone | Mutation testing (on demand) |
| /st-status | Anyone | Progress from .stania/progress.json |

## Core Principles

1. Right-size ceremony — /st-quick for simple, full pipeline for complex
2. Contract-first — define API surface before implementation
3. Parallel by default — frontend and backend work simultaneously via mocks
4. Agents do execution — humans make decisions
5. Validate once — /st-check owns validation, /st-build does NOT re-run it
6. Truncate output — `| tail -N` always, read full only on failure
7. Merge = deploy — no manual deploys

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
