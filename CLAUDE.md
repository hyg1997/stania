# Stania — Repository Guide

This repo contains Stania, a set of Claude Code commands and skills for disciplined
AI-assisted engineering. It replaces vibe coding with a structured pipeline and
cross-session state tracking.

## Repo Structure

```
stania/
├── commands/              ← Slash commands (copied to ~/.claude/commands/)
│   ├── st-bootstrap.md    ← /st-bootstrap: project setup + .stania/ init
│   ├── st-spec.md         ← /st-spec: formal spec, saved to .stania/specs/
│   ��── st-build.md        ← /st-build: controlled generation with progress tracking
│   ├── st-check.md        ← /st-check: validate + harden
│   ├── st-ship.md         ← /st-ship: pre-deploy audit
│   ├── st-retro.md        ← /st-retro: session close
│   ├── st-mutate.md       ← /st-mutate: mutation testing
│   ├── st-model.md        ← /st-model: DDD domain model → .stania/domain-model.json
│   └── st-status.md       ← /st-status: progress from .stania/progress.json
├── skills/st/             ← Skill definition (auto-loaded by Claude Code)
│   └── SKILL.md           ← Core behavior rules, state schemas, pipeline spec
├── hooks/             ← Claude Code hooks (optional)
├── docs/              ← Workflow documentation
│   └── workflow.md    ← Full engineering workflow reference
├── install.sh         ← One-line installer
├── README.md          ← Public README
├── LICENSE            ← MIT
└── CLAUDE.md          ← This file
```

## Source of Truth

- `skills/st/SKILL.md` — Core behavior: pipeline stages, state schemas, AI code smells, review tiers
- `commands/*.md` — Individual command implementations
- `docs/workflow.md` — Detailed workflow reference with examples

## Key Design Principles

1. **State is advisory, not blocking**: Commands work without `.stania/`. State enhances cross-session continuity but never gates functionality.
2. **No external runtime**: Claude Code reads/writes JSON directly. No Node.js, no dependencies, no build step.
3. **Stack-agnostic**: Detect and adapt, don't assume. Works with TypeScript, Python, Go, Rust.
4. **Graceful degradation**: If a tool isn't installed (stryker, semgrep), skip and report — don't fail.
5. **Idempotent**: install.sh and /st-bootstrap are safe to re-run.

## Development Rules

- Commands must be stack-agnostic (detect and adapt, don't assume)
- Never hardcode file paths — use relative paths or environment variables
- Every command must work in an empty project and in an existing one
- Every command must work with AND without `.stania/` directory
- install.sh must be idempotent (safe to re-run)
- Test changes by running install.sh then using commands in a real project
