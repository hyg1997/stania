# Stania — Repository Guide

This repo contains Stania, a set of Claude Code commands and skills for disciplined
AI-assisted engineering. It replaces vibe coding with a structured pipeline and
cross-session state tracking.

## Repo Structure

```
stania/
├── commands/          ← Slash commands (copied to ~/.claude/commands/)
│   ├── bootstrap.md   ← /bootstrap: project setup + .stania/ init
│   ├── spec.md        ← /spec: formal spec, saved to .stania/specs/
│   ├── build.md       ← /build: controlled generation with progress tracking
│   ├── check.md       ← /check: validate + harden
│   ├── ship.md        ← /ship: pre-deploy audit
│   ├── retro.md       ← /retro: session close
│   ├── mutate.md      ← /mutate: mutation testing
│   ├── model.md       ← /model: DDD domain model → .stania/domain-model.json
│   └── status.md      ← /status: progress from .stania/progress.json
├── skills/stania/     ← Skill definition (auto-loaded by Claude Code)
│   └── SKILL.md       ← Core behavior rules, state schemas, pipeline spec
├── hooks/             ← Claude Code hooks (optional)
├── docs/              ← Workflow documentation
│   └── workflow.md    ← Full engineering workflow reference
├── install.sh         ← One-line installer
├── README.md          ← Public README
├── LICENSE            ← MIT
└── CLAUDE.md          ← This file
```

## Source of Truth

- `skills/stania/SKILL.md` — Core behavior: pipeline stages, state schemas, AI code smells, review tiers
- `commands/*.md` — Individual command implementations
- `docs/workflow.md` — Detailed workflow reference with examples

## Key Design Principles

1. **State is advisory, not blocking**: Commands work without `.stania/`. State enhances cross-session continuity but never gates functionality.
2. **No external runtime**: Claude Code reads/writes JSON directly. No Node.js, no dependencies, no build step.
3. **Stack-agnostic**: Detect and adapt, don't assume. Works with TypeScript, Python, Go, Rust.
4. **Graceful degradation**: If a tool isn't installed (stryker, semgrep), skip and report — don't fail.
5. **Idempotent**: install.sh and /bootstrap are safe to re-run.

## Development Rules

- Commands must be stack-agnostic (detect and adapt, don't assume)
- Never hardcode file paths — use relative paths or environment variables
- Every command must work in an empty project and in an existing one
- Every command must work with AND without `.stania/` directory
- install.sh must be idempotent (safe to re-run)
- Test changes by running install.sh then using commands in a real project
