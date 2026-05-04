# Stania — Workflow Reference

Complete reference for the Stania engineering pipeline.
For quick command usage, see the [README](../README.md).

## Daily Workflow

```
1. Start session
   → Read CLAUDE.md (automatic)
   → /st-status to see where you left off (reads .stania/progress.json)

2. Pick next aggregate/feature
   → /st-spec to define it formally (saved to .stania/specs/)

3. Generate code
   → /st-build (layer by layer, with approval gates, progress tracked)

4. Validate
   → /st-check (automated pipeline + AI code smell scan)
   → /st-mutate (optional, recommended for domain logic)

5. Ship
   → /st-ship (full audit + PR creation)

6. Close session
   → /st-retro (capture decisions, update docs, save session summary)
```

## State Management

Stania tracks state in `.stania/` — no external runtime needed.
Claude Code reads/writes JSON directly.

### Files

| File | Purpose | Git |
|------|---------|-----|
| `config.json` | Stack, architecture, thresholds | Committed |
| `domain-model.json` | Bounded contexts, aggregates, events | Committed |
| `progress.json` | Per-aggregate layer completion | Gitignored |
| `specs/*.md` | Approved feature specs | Gitignored |

### Design rules

1. **Advisory, not blocking**: If state is missing or corrupted, commands fall back to filesystem scanning.
2. **Read-merge-write**: Always read current state, merge changes, then write. Never overwrite blindly.
3. **Human-readable**: Users can inspect and manually edit JSON if needed.
4. **Graceful degradation**: No `.stania/`? Commands still work — just without cross-session tracking.

## Stage Details

### Stage 0: /st-bootstrap

**When**: Starting a new project or joining one that lacks structure.

**What it does**:
1. Diagnoses current state (git, tooling, docs)
2. Gathers project context
3. Creates `.stania/config.json` and `.stania/progress.json`
4. Sets up: git, CLAUDE.md, docs/, monorepo, quality tooling, pre-commit hooks
5. Verifies everything works
6. Makes initial commit

**State created**: `config.json`, `progress.json` (empty)

### Stage 1: /st-spec

**When**: Before generating ANY code for a feature.

**What it produces**: Formal spec with invariants, errors, edge cases, critical tests.

**State**: Reads `domain-model.json` for context. Saves approved spec to `.stania/specs/{slug}.md`. Updates `progress.json` with specPath.

### Stage 2: /st-build

**When**: After spec is approved.

**Generation order** (strict):
1. **Domain** — Value Objects → Aggregate → Events → Ports
2. **Application** — Command/Query → Handler → DTOs
3. **Infrastructure** — Adapters → DI wiring
4. Each layer gets tests before moving to next
5. Each layer requires user approval

**State**: Updates `progress.json` layers after each phase. Marks status "in-progress" → "done".

### Stage 3: /st-check

**When**: After /st-build, or any time you want to validate.

**Phase 1 — Automated validation**: typecheck, lint, tests, format
**Phase 2 — Hardening**: architecture enforcement, 8 AI code smells, security scan

**Output**: PASS / WARN / FAIL verdict.
**State**: Updates `progress.json` lastCheck timestamp.

### Stage 4: /st-ship

**When**: Feature complete and /st-check passes.

**Checklist**: repo state, full pipeline (strict), coverage, mutation testing, manual checklist, PR creation.

### Stage 5: /st-retro

**When**: End of work session.

**What it does**: Summarize session, create ADRs, update docs, suggest next steps.
**State**: Saves `lastSession` to `progress.json`.

## AI Code Smells — Detailed

### 1. API Hallucination
AI invents methods that don't exist in the library.
**Detection**: Check every external API call against actual types.

### 2. Happy Path Bias
Only handles success. No error handling, no timeouts.
**Detection**: Missing try/catch, unchecked nulls, no retry logic.

### 3. Invisible Coupling
Domain imports from infrastructure.
**Detection**: Check import paths in domain files.

### 4. Security Blindness
Unsanitized input, PII in logs, secrets in code.
**Detection**: Trace user input from entry to usage. Check logs for PII.

### 5. Over-engineering
Premature abstractions for requirements that don't exist.
**Detection**: "Would removing this abstraction break anything?"

### 6. Test Theater
Tests pass but verify nothing. Mocking everything.
**Detection**: Check assertion count. Tests with only `toBeDefined()`.

### 7. Context Amnesia
Inconsistent patterns across files.
**Detection**: Same problem solved differently in two places.

### 8. Stale Patterns
Deprecated APIs, outdated approaches.
**Detection**: Check for deprecation warnings.

## Review Tiers

### T1 Auto
**Scope**: UI, config, cosmetic, dep bumps.
**Process**: /st-check passes → commit.

### T2 Light
**Scope**: New features, handlers, endpoints.
**Process**: /st-check + quick review of contracts.

### T3 Deep
**Scope**: Domain logic, security, billing, migrations.
**Process**: /st-check + /st-mutate + manual review.

## Clean Architecture Quick Reference

```
┌─────────────────────────────────────────┐
│              Presentation               │
│         (Routes, Controllers)           │
├─────────────────────────────────────────┤
│              Application                │
│    (Use Cases, Command/Query Handlers)  │
│         Orchestration only.             │
├─────────────────────────────────────────┤
│               Domain                    │
│  (Entities, Value Objects, Aggregates,  │
│   Domain Events, Port interfaces)       │
│      ZERO external dependencies.        │
├─────────────────────────────────────────┤
│            Infrastructure               │
│   (Repositories, External Services,     │
│    Framework adapters, DI container)     │
└─────────────────────────────────────────┘

Dependencies flow INWARD only.
Domain depends on nothing.
```

### Rules
- Private constructors + factory methods on aggregates
- Result pattern for fallible operations
- Value Objects over primitives
- Port interfaces in domain, implementations in infrastructure
- One aggregate per transaction boundary

## Test Distribution

| Layer | Target | What to test |
|-------|--------|-------------|
| Domain | 60% | Invariants, business rules, edge cases |
| Application | 25% | Use case orchestration, error flows |
| Integration | 10% | Repository implementations, external APIs |
| E2E | 5% | Critical user flows only |

## Mutation Testing

**What**: Modify code automatically and check if tests catch it.
**When**: /st-mutate on demand, or during /st-ship for T3 reviews.
**Target**: >80% kill rate on domain logic.
**Tools**: Stryker (TS), mutmut (Python), go-mutesting (Go)
