# Forja

**From vibe coding to production-ready engineering.**

Forja is a set of Claude Code commands that replace ad-hoc AI-assisted development with a disciplined 5-stage pipeline. Every feature goes through **SPEC → BUILD → CHECK → SHIP → RETRO** before reaching production.

Works with any stack. No external dependencies. Just Claude Code.

## Philosophy

```
Vibe coding:    "hey AI, build me a booking system"
Forja:          spec the invariants → generate domain first → validate → harden → ship
```

The difference: **70% thinking/designing/specifying, 30% generating/reviewing.** The quality of AI output depends entirely on the quality of the spec you give it.

## Commands

### Core Pipeline

| Command | Stage | What it does |
|---------|-------|-------------|
| `/bootstrap` | 0 | From idea → fully configured project (git, CLAUDE.md, monorepo, tooling, pre-commit hooks) |
| `/spec` | 1 | Write formal spec: invariants, errors, edge cases. Before any code. |
| `/build` | 2 | Controlled generation: domain → application → infrastructure, with tests |
| `/check` | 3-4 | Validate (typecheck, lint, tests) + Harden (architecture, AI code smells, security) |
| `/ship` | 5 | Pre-deploy audit: full pipeline + coverage + mutations + PR creation |
| `/retro` | — | Session close: capture decisions, update docs, suggest next steps |
| `/mutate` | — | Mutation testing on demand. "Do your tests actually catch bugs?" |

### DDD / Clean Architecture

| Command | What it does |
|---------|-------------|
| `/model` | Extract DDD domain model from business description (bounded contexts, aggregates, value objects, events) |
| `/status` | Show implementation progress per bounded context and aggregate |

## The Pipeline

```
  /bootstrap                    /retro
       │                            ▲
       ▼                            │
  ┌─────────┐    ┌─────────┐    ┌──────┐    ┌──────┐
  │  /spec   │───▶│  /build  │───▶│/check│───▶│/ship │
  │          │    │          │    │      │    │      │
  │Invariants│    │Domain 1st│    │Verify│    │Audit │
  │Errors    │    │Layer by  │    │Harden│    │Deploy│
  │Edge cases│    │layer     │    │Smells│    │PR    │
  └─────────┘    └─────────┘    └──────┘    └──────┘
       ▲                            │
       └──── /mutate (on demand) ◀──┘
```

## Install

One line:

```bash
curl -fsSL https://raw.githubusercontent.com/cloudpetals/forja/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/cloudpetals/forja.git ~/.forja
cd ~/.forja && bash install.sh
```

### Options

```bash
bash install.sh --dry-run    # Preview what would be installed
bash install.sh --minimal    # Commands only, no skill
bash install.sh --uninstall  # Remove all Forja commands
```

## What Forja replaces

| Before | After | Why |
|--------|-------|-----|
| No structure | `/bootstrap` | Consistent project setup with quality tooling from day 1 |
| "Build me X" | `/spec` → `/build` | Spec-first means AI generates what you actually need |
| "Looks good" | `/check` | Automated validation + 8 AI code smell checks |
| `git push` and pray | `/ship` | Full audit with coverage and mutation testing |
| Close terminal | `/retro` | Capture decisions for future sessions |
| stania-model | `/model` | DDD model extraction, stack-agnostic |
| stania-generate + implement | `/build` | Controlled generation with approval gates |
| stania-status | `/status` | Implementation progress tracking |

## AI Code Smells (checked by /check)

1. **API Hallucination** — AI invented a method that doesn't exist
2. **Happy Path Bias** — No error handling for failures
3. **Invisible Coupling** — Domain depends on infrastructure
4. **Security Blindness** — Unsanitized input, PII in logs
5. **Over-engineering** — Premature abstractions
6. **Test Theater** — Tests that verify nothing meaningful
7. **Context Amnesia** — Inconsistent patterns across modules
8. **Stale Patterns** — Using deprecated approaches

## Review Tiers (used by /check)

| Tier | When | What |
|------|------|------|
| T1 Auto | UI changes, config, cosmetic | Pipeline passes → merge |
| T2 Light | New features, handlers | Pipeline + quick review of contracts |
| T3 Deep | Domain logic, security, billing | Full pipeline + manual review + mutation testing |

## Documentation

- [Workflow Reference](docs/workflow.md) — Full pipeline details, AI code smells explained, review tiers, Clean Architecture rules
- [Skill Definition](skills/forja/SKILL.md) — Core behavior rules loaded by Claude Code

## Requirements

- [Claude Code](https://claude.ai/code) installed
- Git initialized in your project
- That's it. No runtime dependencies.

## Stack Support

Forja is stack-agnostic. It detects your project's stack and adapts:

- **TypeScript**: tsc strict, Biome, Vitest, Stryker
- **Python**: mypy strict, ruff, pytest, mutmut
- **Go**: go vet, golangci-lint, go test
- **Rust**: cargo clippy, cargo test

The commands adapt their validation pipeline to whatever tools are configured in your project.

## License

MIT

## Author

Built by [Cloudpetals](https://github.com/cloudpetals) — Hugo Yupanqui
