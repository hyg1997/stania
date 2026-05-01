---
name: forja
description: "Engineering workflow that replaces vibe coding with a disciplined 5-stage pipeline: SPEC → BUILD → CHECK → SHIP → RETRO. Stack-agnostic, Clean Architecture aware."
---

# Forja — Engineering Workflow

You are operating under Forja engineering discipline.
Every feature follows the pipeline: SPEC → BUILD → CHECK → SHIP → RETRO.
No code is generated without an approved spec. No code is committed without passing validation.

## Core Principles

1. **Spec first**: Define invariants, errors, and edge cases BEFORE generating code
2. **Domain first**: Value Objects → Aggregate → Events → Ports → Handlers → Adapters
3. **One layer at a time**: Never "generate the whole feature" — piece by piece with approval
4. **Tests with code**: Tests are generated alongside the code, never after
5. **Validate before commit**: typecheck + lint + tests must pass, no exceptions
6. **AI code smells**: Check for hallucination, happy path bias, coupling, test theater
7. **Atomic commits**: One commit = one coherent unit of change

## Pipeline Stages

### Stage 1: SPEC (/spec)
Before generating any code, write a formal spec with:
- Bounded context and affected layers
- Input/output types
- Invariants (rules that NEVER break)
- Possible errors with conditions
- Edge cases including concurrency
- Critical test cases

Present to user. Do NOT generate code until approved.

### Stage 2: BUILD (/build)
Generate code in strict order:
1. Domain layer (zero external deps)
2. Application layer (orchestration, no business logic)
3. Infrastructure layer (implements ports)
4. Each layer gets tests before moving to next
5. Each layer requires user approval before advancing

### Stage 3: CHECK (/check)
Run automated validation + hardening:
- Typecheck (tsc strict / mypy strict)
- Lint (Biome / ruff / golangci-lint)
- Tests (Vitest / pytest / go test)
- Architecture enforcement (no layer violations)
- 8 AI code smell checks
- Security quick scan (secrets, dependency audit)

### Stage 4: SHIP (/ship)
Pre-deploy audit:
- Full pipeline (stricter than /check)
- Test coverage report
- Mutation testing (if configured)
- Manual checklist
- PR creation with structured body

### Stage 5: RETRO (/retro)
Session close:
- Summarize completed work
- Capture architectural decisions as ADRs
- Update docs if needed
- Suggest next session's starting point

## AI Code Smells (always check)

1. **API Hallucination** — invented methods from external libraries
2. **Happy Path Bias** — no error handling for failures
3. **Invisible Coupling** — domain depends on infrastructure
4. **Security Blindness** — unsanitized input, PII in logs
5. **Over-engineering** — premature abstractions
6. **Test Theater** — tests that verify nothing meaningful
7. **Context Amnesia** — inconsistent patterns across modules
8. **Stale Patterns** — using deprecated approaches

## Review Tiers

| Tier | When | Action |
|------|------|--------|
| T1 Auto | UI, config, cosmetic | Pipeline passes → commit |
| T2 Light | New features, handlers | Pipeline + quick contract review |
| T3 Deep | Domain, security, billing | Full pipeline + manual + mutations |

## Clean Architecture Rules

When project uses Clean Architecture / DDD:
- Domain layer has ZERO external imports
- Private constructors + factory methods on aggregates
- Result pattern for fallible operations (no exceptions for business flows)
- Port interfaces defined in domain, implemented in infrastructure
- Value Objects over primitives (Email not string, Money not number)

## Stack Detection

Forja adapts to the project's stack:
- **TypeScript**: tsc, Biome, Vitest, Stryker
- **Python**: mypy, ruff, pytest, mutmut
- **Go**: go vet, golangci-lint, go test
- **Rust**: cargo clippy, cargo test

Detect from package.json, pyproject.toml, go.mod, or Cargo.toml.
