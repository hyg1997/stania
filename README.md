# Stania

**From vibe coding to production-ready engineering.**

Stania is a set of Claude Code commands with cross-session state tracking. Every feature goes through **SPEC → BUILD → CHECK → SHIP → RETRO** before reaching production. Progress is tracked in `.stania/` so you never lose context between sessions.

Works with any stack. No external runtime. Just Claude Code.

## Philosophy

```
Vibe coding:    "hey AI, build me a booking system"
Stania:         spec the invariants → generate domain first → validate → harden → ship
```

The difference: **70% thinking/designing/specifying, 30% generating/reviewing.** The quality of AI output depends entirely on the quality of the spec you give it.

## What's different from other tools

- **Cross-session state**: `.stania/` tracks your domain model, specs, and per-aggregate progress. Resume exactly where you left off.
- **No runtime**: No Node.js, no dependencies, no build step. Claude Code reads/writes JSON directly.
- **Graceful degradation**: Everything works without `.stania/`. State enhances the experience but never blocks it.
- **Stack-agnostic**: Detects your stack and adapts — TypeScript, Python, Go, Rust.

## Commands

### Core Pipeline

| Command | Stage | What it does |
|---------|-------|-------------|
| `/bootstrap` | 0 | From idea → configured project + `.stania/` init |
| `/spec` | 1 | Formal spec: invariants, errors, edge cases. Saved to `.stania/specs/` |
| `/build` | 2 | Controlled generation: domain → app → infra, with progress tracking |
| `/check` | 3 | Validate (typecheck, lint, tests) + Harden (architecture, AI smells, security) |
| `/ship` | 4 | Pre-deploy audit: full pipeline + coverage + mutations + PR |
| `/retro` | — | Session close: capture decisions, update docs, suggest next steps |

### Extra

| Command | What it does |
|---------|-------------|
| `/mutate` | Mutation testing on demand. "Do your tests actually catch bugs?" |
| `/model` | Extract DDD domain model → `.stania/domain-model.json` |
| `/status` | Show progress per bounded context and aggregate |

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

## State Tracking

Stania creates a `.stania/` directory in each project:

```
.stania/
├── config.json          ← Stack, architecture, hardening thresholds
├── domain-model.json    ← Bounded contexts, aggregates, VOs, events
├── progress.json        ← Per-aggregate status (which layers are done)
└── specs/               ← Approved specs (one .md per feature)
```

- `config.json` and `domain-model.json` are committed to git (shared context)
- `progress.json` and `specs/` are gitignored (local working state)
- If `.stania/` is missing, commands fall back to filesystem scanning

## Install

One line:

```bash
curl -fsSL https://raw.githubusercontent.com/cloudpetals/stania/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/cloudpetals/stania.git ~/.stania-cli
cd ~/.stania-cli && bash install.sh
```

### Options

```bash
bash install.sh --dry-run    # Preview what would be installed
bash install.sh --minimal    # Commands only, no skill
bash install.sh --uninstall  # Remove all Stania commands
```

## Documentation

- [Workflow Reference](docs/workflow.md) — Full pipeline details, AI code smells, review tiers, Clean Architecture rules
- [Skill Definition](skills/stania/SKILL.md) — Core behavior rules and state schemas

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

## Requirements

- [Claude Code](https://claude.ai/code) installed
- Git initialized in your project
- That's it. No runtime dependencies.

## Stack Support

Stania is stack-agnostic. It detects your project's stack and adapts:

- **TypeScript**: tsc strict, Biome, Vitest, Stryker
- **Python**: mypy strict, ruff, pytest, mutmut
- **Go**: go vet, golangci-lint, go test
- **Rust**: cargo clippy, cargo test

## License

MIT

## Author

Built by [Cloudpetals](https://github.com/cloudpetals) — Hugo Yupanqui
