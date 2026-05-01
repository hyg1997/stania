# Forja — Repository Guide

This repo contains Forja, a set of Claude Code commands and skills for disciplined
AI-assisted engineering. It replaces vibe coding with a structured pipeline.

## Repo Structure

```
forja/
├── commands/          ← Slash commands (copied to ~/.claude/commands/)
│   ├── bootstrap.md   ← /bootstrap: project setup from idea
│   ├── spec.md        ← /spec: formal spec before coding
│   ├── build.md       ← /build: controlled generation
│   ├── check.md       ← /check: validate + harden
│   ├── ship.md        ← /ship: pre-deploy audit
│   ├── retro.md       ← /retro: session close
│   ├── mutate.md      ← /mutate: mutation testing
│   ├── model.md       ← /model: DDD domain model extraction
│   └── status.md      ← /status: implementation progress
├── skills/forja/      ← Skill definition (auto-loaded by Claude Code)
│   └── SKILL.md       ← Core behavior rules and pipeline spec
├── hooks/             ← Claude Code hooks (optional)
├── docs/              ← Workflow documentation
│   └── workflow.md    ← Full engineering workflow reference
├── install.sh         ← One-line installer
├── README.md          ← Public README
├── LICENSE            ← MIT
└── CLAUDE.md          ← This file
```

## Source of Truth

- `skills/forja/SKILL.md` — Core behavior: pipeline stages, AI code smells, review tiers
- `commands/*.md` — Individual command implementations
- `docs/workflow.md` — Detailed workflow reference with examples

## Development Rules

- Commands must be stack-agnostic (detect and adapt, don't assume)
- Never hardcode file paths — use relative paths or environment variables
- Every command must work in an empty project and in an existing one
- install.sh must be idempotent (safe to re-run)
- Test changes by running install.sh then using commands in a real project
