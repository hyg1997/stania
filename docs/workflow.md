# Forja — Workflow Reference

Complete reference for the Forja engineering pipeline.
For quick command usage, see the [README](../README.md).

## Daily Workflow

```
1. Start session
   → Read CLAUDE.md (automatic)
   → /status to see where you left off

2. Pick next aggregate/feature
   → /spec to define it formally

3. Generate code
   → /build (layer by layer, with approval gates)

4. Validate
   → /check (automated pipeline + AI code smell scan)
   → /mutate (optional, recommended for domain logic)

5. Ship
   → /ship (full audit + PR creation)

6. Close session
   → /retro (capture decisions, update docs)
```

## Stage Details

### Stage 0: /bootstrap

**When**: Starting a new project from scratch, or joining a project that lacks structure.

**What it does**:
1. Diagnoses the current state (git, package manager, tooling, docs)
2. Gathers project context from user
3. Creates/updates: git repo, CLAUDE.md, docs/, monorepo structure, quality tooling (typecheck, lint, test, pre-commit hooks)
4. Verifies everything works (build, lint, test pass)
5. Makes initial commit
6. Reports what was created

**Key rule**: Never assumes a stack — detects from existing files or asks.

### Stage 1: /spec

**When**: Before generating ANY code for a feature or aggregate.

**What it produces**:
```
=== SPEC: [Feature Name] ===

Bounded Context: [name]
Affected Layers: Domain / Application / Infrastructure

Input:  [type definition]
Output: [type definition]

Invariants:
  1. [rule that NEVER breaks]
  2. ...

Errors:
  - [ErrorName]: when [condition]
  - ...

Edge Cases:
  - [scenario including concurrency]
  - ...

Critical Test Cases:
  - [test: input → expected output]
  - ...
```

**Key rule**: Do NOT generate code until the user approves the spec.

### Stage 2: /build

**When**: After spec is approved.

**Generation order** (strict):
1. **Domain layer** — Value Objects → Aggregate → Domain Events → Port interfaces
2. **Application layer** — Command/Query → Handler → DTOs
3. **Infrastructure layer** — Repository adapters → External service adapters → DI wiring
4. **Wiring** — Routes/controllers, module registration

**Rules**:
- Each layer gets unit tests before moving to the next
- Each layer requires user approval before advancing
- Domain has ZERO external imports
- Tests are generated alongside code, never after

### Stage 3: /check

**When**: After /build completes, or any time you want to validate current state.

**Phase 1 — Automated validation**:
- Typecheck (tsc --noEmit / mypy --strict)
- Lint (biome check / ruff check)
- Tests (vitest run / pytest)
- Format check

**Phase 2 — Hardening**:
- Architecture enforcement: no domain → infrastructure imports
- 8 AI code smell checks (see below)
- Security scan: secrets in code, dependency audit
- Test quality: coverage, assertion density

**Output**: PASS / WARN / FAIL verdict with specific findings.

### Stage 4: /ship

**When**: Feature is complete and /check passes.

**Checklist**:
1. Clean working tree (no uncommitted changes)
2. Full /check pipeline (stricter thresholds)
3. Test coverage report
4. Mutation testing results (if configured)
5. Manual checklist: docs updated? Breaking changes? Migration needed?
6. PR creation with structured body

**PR body format**:
```markdown
## What
[one-line summary]

## Why
[business context]

## How
[technical approach]

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing done

## Checklist
- [ ] Types pass strict mode
- [ ] No lint warnings
- [ ] Docs updated
- [ ] No secrets in code
```

### Stage 5: /retro

**When**: End of work session.

**What it does**:
1. Summarizes git log since last retro
2. Identifies architectural decisions worth recording
3. Creates ADRs (Architecture Decision Records) if needed
4. Updates CLAUDE.md or docs/ if anything changed
5. Suggests where to start next session

## AI Code Smells — Detailed

### 1. API Hallucination
AI invents methods, parameters, or return types that don't exist in the actual library.

**Detection**: Check every external API call against actual library docs/types.
**Example**: `prisma.user.findByEmail()` — Prisma has no `findByEmail`, it's `findUnique({ where: { email } })`.

### 2. Happy Path Bias
AI writes code that only handles the success case. No error handling, no edge cases, no timeouts.

**Detection**: Look for missing try/catch, unchecked nulls, no timeout on external calls, no retry logic.
**Example**: `const user = await db.findUser(id)` followed by `user.name` with no null check.

### 3. Invisible Coupling
Domain layer imports from infrastructure. Business logic depends on framework specifics.

**Detection**: Check import paths in domain files. Domain should have zero external deps.
**Example**: `import { PrismaClient } from '@prisma/client'` in a domain service.

### 4. Security Blindness
Unsanitized user input, PII in logs, secrets in code, missing auth checks.

**Detection**: Trace user input from entry point to usage. Check log statements for PII. Grep for hardcoded secrets.
**Example**: `console.log('User login:', { email, password })` — password in logs.

### 5. Over-engineering
Premature abstractions, unnecessary design patterns, building for requirements that don't exist.

**Detection**: Ask "would removing this abstraction break anything?" If no, it's over-engineering.
**Example**: Factory pattern for a class that has exactly one implementation.

### 6. Test Theater
Tests that pass but verify nothing meaningful. Mocking everything. Testing implementation instead of behavior.

**Detection**: Check assertion count and quality. Tests with zero assertions. Tests that only check `toBeDefined()`.
**Example**: `expect(service).toBeDefined()` — this tests that JavaScript works, not your code.

### 7. Context Amnesia
AI writes inconsistent patterns across files. Different error handling strategies, naming conventions, or architectural patterns in the same project.

**Detection**: Compare patterns across modules. Same problem solved differently in two places.
**Example**: Module A uses Result pattern, Module B throws exceptions for the same kind of error.

### 8. Stale Patterns
AI uses deprecated APIs, old library versions, or outdated approaches from its training data.

**Detection**: Check for deprecation warnings. Verify API calls against current docs.
**Example**: Using `componentWillMount` in React (deprecated since React 16.3).

## Review Tiers — When to Use Each

### T1 Auto
**Scope**: UI changes, config files, cosmetic fixes, dependency bumps.
**Process**: /check passes → commit directly.
**Rationale**: Low risk, high confidence from automated checks.

### T2 Light
**Scope**: New features, handlers, API endpoints, new adapters.
**Process**: /check + quick manual review of contracts and interfaces.
**Rationale**: Medium risk, need to verify contracts are correct.

### T3 Deep
**Scope**: Domain logic, security-related code, billing/payment, data migrations.
**Process**: Full /check + /mutate + manual review of every line.
**Rationale**: High risk, bugs here cost real money or compromise security.

## Clean Architecture Quick Reference

```
┌─────────────────────────────────────────┐
│              Presentation               │
│         (Routes, Controllers)           │
├─────────────────────────────────────────┤
│              Application                │
│    (Use Cases, Command/Query Handlers)  │
│         Orchestration only.             │
│       No business logic here.           │
├─────────────────────────────────────────┤
│               Domain                    │
│  (Entities, Value Objects, Aggregates,  │
│   Domain Events, Port interfaces)       │
│      ZERO external dependencies.        │
├─────────────────────────────────────────┤
│            Infrastructure               │
│   (Repositories, External Services,     │
│    Framework adapters, DI container)     │
│     Implements domain ports.            │
└─────────────────────────────────────────┘

Dependencies flow INWARD only.
Domain depends on nothing. Everything depends on domain.
```

### Rules
- Private constructors + factory methods on aggregates
- Result pattern for fallible operations (no exceptions for business flows)
- Value Objects over primitives (`Email` not `string`, `Money` not `number`)
- Port interfaces defined in domain, implemented in infrastructure
- One aggregate per transaction boundary

## Test Distribution

| Layer | Target | What to test |
|-------|--------|-------------|
| Domain | 60% | Invariants, business rules, edge cases |
| Application | 25% | Use case orchestration, error flows |
| Integration | 10% | Repository implementations, external APIs |
| E2E | 5% | Critical user flows only |

## Mutation Testing

**What**: Automatically modify your code (mutants) and check if tests catch the changes. If a mutant survives, your tests have a gap.

**When**: /mutate on demand, or automatically during /ship for T3 reviews.

**Target**: >80% kill rate on domain logic.

**Tools**:
- TypeScript: Stryker (`npx stryker run`)
- Python: mutmut (`mutmut run`)
- Go: go-mutesting
