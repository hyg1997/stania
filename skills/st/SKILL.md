---
name: st
description: "Engineering workflow with state tracking. 5-stage pipeline: SPEC → BUILD → CHECK → SHIP → RETRO. Maintains .stania/ for cross-session continuity. Stack-agnostic, Clean Architecture aware."
---

# Stania — Engineering Workflow

You are operating under Stania engineering discipline.
Every feature follows: SPEC → BUILD → CHECK → SHIP → RETRO.
No code without approved spec. No commit without passing validation.

## State (.stania/)

State is **advisory, not blocking**. If missing, commands fall back to filesystem scanning.

```
.stania/
├── config.json          ← Stack, architecture, thresholds
├── domain-model.json    ← Bounded contexts, aggregates, VOs, events
├── progress.json        ← Per-aggregate implementation status
└── specs/{slug}.md      ← Approved specs
```

Schemas: read the files directly when needed. Key fields:
- **config.json**: `stack.{language,framework,testRunner,linter}`, `architecture`, `hardening.{mutationThreshold,coverageTarget}`
- **progress.json**: `aggregates.{"Context/Aggregate": {status,layers,specPath,lastCheck,lastBuild}}`, `lastSession`
- **domain-model.json**: `boundedContexts[].{name,type,aggregates[].{name,invariants,commands,events,valueObjects,ports}}`, `relationships[]`

Rules: read before write, merge changes, never overwrite blindly.

## Pipeline

| Stage | Command | Gate |
|-------|---------|------|
| QUICK | /st-quick | T1/T2: validate → commit (no spec needed) |
| SPEC | /st-spec | User approves spec |
| BUILD | /st-build | User approves each layer (or single-shot if not DDD) |
| CHECK | /st-check | Pipeline passes |
| SHIP | /st-ship | Incremental audit + PR |
| RETRO | /st-retro | Session close |

**Fast path**: For fixes, config, UI → /st-quick (skips spec + build ceremony).
**Full path**: For domain logic, security → /st-spec → /st-build → /st-check → /st-ship.

## Core Principles

1. Right-size ceremony — /st-quick for simple, full pipeline for complex
2. Spec first for domain — invariants, errors, edge cases BEFORE code
3. Domain first (DDD only) — VOs → Aggregate → Events → Ports → Handlers
4. Tests with code — never after
5. Validate once — /st-check owns validation, /st-build does NOT re-run it
6. Truncate output — `| tail -N` always, read full only on failure
7. Atomic commits

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

- **T1 Auto**: UI, config, cosmetic → pipeline passes → commit
- **T2 Light**: New features → pipeline + quick review
- **T3 Deep**: Domain, security, billing → full pipeline + mutations

## Clean Architecture (when applicable)

- Domain: ZERO external imports, private constructors + factory, Result pattern, ports as interfaces
- Value Objects over primitives (Email not string, Money not number)

## Token Efficiency Rules

1. **Truncate all tool output**: Always `| tail -N`. Read full only on failure.
2. **No duplicate validation**: /st-build does typecheck only. /st-check owns full pipeline.
3. **Incremental /st-ship**: Skip re-validation if lastCheck < 10 min.
4. **Parallel validation**: In /st-check, run typecheck + lint + tests as 3 simultaneous tool calls.
5. **Lazy loading**: Only read the specific aggregate/spec needed, not entire domain-model.json.
6. **testFlags config**: Read `.stania/config.json` → `testFlags.fast` for flags (avoids recalculating).
7. **Session split**: After heavy /st-build iterations, suggest new session for /st-check.
8. **Context7 MCP**: If available, use `resolve_library_id` + `get_library_docs` for API hallucination checks instead of grep in node_modules.

## Stack Detection

1. `.stania/config.json` → 2. package.json/pyproject.toml/go.mod/Cargo.toml → 3. Ask user

| Stack | Typecheck | Lint | Test | Mutate |
|-------|-----------|------|------|--------|
| TS | tsc | Biome | Vitest | Stryker |
| Python | mypy | ruff | pytest | mutmut |
| Go | go vet | golangci-lint | go test | go-mutesting |
| Rust | cargo clippy | clippy | cargo test | — |
