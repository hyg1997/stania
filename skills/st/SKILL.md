---
name: st
description: "Engineering workflow with state tracking. 5-stage pipeline: SPEC → BUILD → CHECK → SHIP → RETRO. Maintains .stania/ for cross-session continuity. Stack-agnostic, Clean Architecture aware."
---

# Stania — Engineering Workflow

You are operating under Stania engineering discipline.
Every feature follows the pipeline: SPEC → BUILD → CHECK → SHIP → RETRO.
No code is generated without an approved spec. No code is committed without passing validation.

## State Management

Stania maintains a `.stania/` directory in each project for cross-session continuity.
State is managed by Claude Code directly (read/write JSON) — no external runtime needed.

### State files

```
.stania/
├── config.json          ← Project config (stack, architecture, thresholds)
├── domain-model.json    ← Bounded contexts, aggregates, VOs, events
├── progress.json        ← Per-aggregate implementation status
└── specs/               ← Approved specs (one .md per feature)
    └── {feature-slug}.md
```

### config.json schema

```json
{
  "version": "1.0.0",
  "projectName": "string",
  "stack": {
    "language": "typescript | python | go | rust | mixed",
    "framework": "next | fastify | express | django | fastapi | none",
    "packageManager": "pnpm | npm | yarn | pip | go | cargo",
    "testRunner": "vitest | jest | pytest | go test | cargo test",
    "linter": "biome | eslint | ruff | golangci-lint | clippy",
    "typeChecker": "tsc | mypy | go vet | cargo check"
  },
  "architecture": "clean | mvc | simple",
  "hardening": {
    "mutationThreshold": 80,
    "coverageTarget": { "domain": 80, "application": 60, "overall": 60 }
  },
  "createdAt": "ISO8601"
}
```

### domain-model.json schema

```json
{
  "name": "string",
  "boundedContexts": [
    {
      "name": "string",
      "type": "core | supporting | generic",
      "aggregates": [
        {
          "name": "string",
          "invariants": ["string"],
          "commands": ["string"],
          "events": ["string"],
          "valueObjects": [
            { "name": "string", "fields": ["string"] }
          ],
          "ports": [
            { "name": "string", "methods": ["string"] }
          ]
        }
      ]
    }
  ],
  "relationships": [
    {
      "source": "string",
      "target": "string",
      "type": "upstream_downstream | shared_kernel | anti_corruption_layer"
    }
  ]
}
```

### progress.json schema

```json
{
  "aggregates": {
    "ContextName/AggregateName": {
      "status": "pending | in-progress | done | failed",
      "layers": {
        "domain": false,
        "application": false,
        "infrastructure": false,
        "tests": false
      },
      "specPath": ".stania/specs/feature-name.md | null",
      "lastCheck": "ISO8601 | null",
      "lastBuild": "ISO8601 | null"
    }
  },
  "lastSession": {
    "date": "ISO8601",
    "summary": "string"
  }
}
```

### State rules

1. **State is advisory, not blocking**: If state files are missing or corrupted, commands fall back to filesystem scanning. State enhances; it never gates.
2. **Read before write**: Always read current state, merge changes, then write. Never overwrite blindly.
3. **Human-readable**: State files are JSON that users can inspect and edit manually if needed.
4. **Graceful degradation**: If `.stania/` doesn't exist, commands still work — they just can't track progress across sessions.

## Core Principles

1. **Spec first**: Define invariants, errors, and edge cases BEFORE generating code
2. **Domain first**: Value Objects → Aggregate → Events → Ports → Handlers → Adapters
3. **One layer at a time**: Never "generate the whole feature" — piece by piece with approval
4. **Tests with code**: Tests are generated alongside the code, never after
5. **Validate before commit**: typecheck + lint + tests must pass, no exceptions
6. **AI code smells**: Check for hallucination, happy path bias, coupling, test theater
7. **Atomic commits**: One commit = one coherent unit of change

## Pipeline Stages

### Stage 1: SPEC (/st-spec)
Before generating any code, write a formal spec with:
- Bounded context and affected layers
- Input/output types
- Invariants (rules that NEVER break)
- Possible errors with conditions
- Edge cases including concurrency
- Critical test cases

Save approved spec to `.stania/specs/{feature-slug}.md`.
Do NOT generate code until approved.

### Stage 2: BUILD (/st-build)
Generate code in strict order:
1. Domain layer (zero external deps)
2. Application layer (orchestration, no business logic)
3. Infrastructure layer (implements ports)
4. Each layer gets tests before moving to next
5. Each layer requires user approval before advancing
6. Update `.stania/progress.json` after each layer completes

### Stage 3: CHECK (/st-check)
Run automated validation + hardening:
- Typecheck (tsc strict / mypy strict)
- Lint (Biome / ruff / golangci-lint)
- Tests (Vitest / pytest / go test)
- Architecture enforcement (no layer violations)
- 8 AI code smell checks
- Security quick scan (secrets, dependency audit)
- Update `progress.json` lastCheck timestamp

### Stage 4: SHIP (/st-ship)
Pre-deploy audit:
- Full pipeline (stricter than /st-check)
- Test coverage report
- Mutation testing (if configured)
- Manual checklist
- PR creation with structured body

### Stage 5: RETRO (/st-retro)
Session close:
- Summarize completed work
- Capture architectural decisions as ADRs
- Update docs if needed
- Save session summary to `progress.json`
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

Stania adapts to the project's stack. Detection order:
1. Read `.stania/config.json` if exists
2. Detect from: package.json, pyproject.toml, go.mod, Cargo.toml
3. Ask user if ambiguous

Tools per stack:
- **TypeScript**: tsc, Biome, Vitest, Stryker
- **Python**: mypy, ruff, pytest, mutmut
- **Go**: go vet, golangci-lint, go test
- **Rust**: cargo clippy, cargo test
