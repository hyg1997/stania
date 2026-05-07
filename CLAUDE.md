# Stania — Repository Guide

This repo contains Stania, a set of Claude Code commands and skills for disciplined
AI-assisted engineering. It replaces vibe coding with a structured pipeline and
cross-session state tracking.

## Repo Structure

```
stania/
├── commands/              ← Slash commands (per-project: .claude/commands/)
│   ├── st-bootstrap.md    ← /st-bootstrap: project setup + testing profiles
│   ├── st-spec.md         ← /st-spec: formal spec, saved to .stania/specs/
│   ├── st-build.md        ← /st-build: controlled generation + agent-browser verification
│   ├── st-check.md        ← /st-check: validate + harden + REVIEW.md
│   ├── st-ship.md         ← /st-ship: audit + schema validation
│   ├── st-retro.md        ← /st-retro: session close
│   ├── st-resume.md       ← /st-resume: session resumption + briefing
│   ├── st-monitor.md      ← /st-monitor: E2E against staging/production
│   ├── st-health.md       ← /st-health: post-deploy smoke test
│   ├── st-snapshot.md     ← /st-snapshot: state snapshots for velocity
│   ├── st-migrate-db.md   ← /st-migrate-db: database migrations
│   ├── st-rollback.md     ← /st-rollback: revert failed deployment
│   ├── st-observe.md      ← /st-observe: observability setup
│   ├── st-storybook.md    ← /st-storybook: auto-generate stories
│   ├── st-a11y.md         ← /st-a11y: accessibility audit
│   ├── st-refactor.md     ← /st-refactor: guided refactoring
│   ├── st-perf.md         ← /st-perf: Lighthouse + bundle + Web Vitals
│   ├── st-flag.md         ← /st-flag: feature flag lifecycle
│   ├── st-mutate.md       ← /st-mutate: mutation testing
│   ├── st-model.md        ← /st-model: DDD domain model → .stania/domain-model.json
│   └── st-status.md       ← /st-status: progress from .stania/progress.json
├── skills/st/             ← Skill definition (per-project: .claude/skills/st/)
│   └── SKILL.md           ← Core behavior rules, pipeline spec
├── templates/             ← Project templates
│   ├── settings.json      ← Permissions + hooks config + Context7 MCP
│   ├── agents/            ← Haiku subagent definitions
│   │   ├── test-runner.md ← Run tests at 3-10x lower cost
│   │   └── code-scanner.md← Audit/scan at 3-10x lower cost
│   └── hooks/             ← PreToolUse hooks for token optimization
│       └── truncate-output.sh ← Auto-truncate verbose output (80-95% savings)
├── docs/                  ← Workflow documentation
│   └── workflow.md        ← Full engineering workflow reference
├── install.sh             ← Per-project installer (default)
├── uninstall-global.sh    ← Remove global installation
├── README.md              ← Public README
├── LICENSE                ← MIT
└── CLAUDE.md              ← This file
```

## Installation Modes

### Per-project (default, recommended)
```bash
bash install.sh          # Installs to .claude/ in current project
```
- Skill only loads when working in this project
- Saves ~52K tokens/turn in other projects
- Creates .claude/settings.json with lean permissions

### Global (not recommended)
```bash
bash install.sh --global  # Installs to ~/.claude/
```
- Skill loads in EVERY conversation (~1,800 tokens overhead always)

### Uninstall
```bash
bash install.sh --uninstall          # Remove from current project
bash install.sh --uninstall --global # Remove from global
bash uninstall-global.sh             # Quick global removal
```

## Source of Truth

- `skills/st/SKILL.md` — Core behavior: pipeline stages, AI code smells, review tiers, token rules
- `commands/*.md` — Individual command implementations (including /st-quick for fast path)
- `docs/workflow.md` — Detailed workflow reference with examples

## Key Design Principles

1. **Per-project by default**: Install only where needed. Never pollute global context.
2. **State is advisory, not blocking**: Commands work without `.stania/`. State enhances cross-session continuity but never gates functionality.
3. **No external runtime**: Claude Code reads/writes JSON directly. No Node.js, no dependencies, no build step.
4. **Stack-agnostic**: Detect and adapt, don't assume. Works with TypeScript, Python, Go, Rust.
5. **Graceful degradation**: If a tool isn't installed (stryker, semgrep), skip and report — don't fail.
6. **Token-conscious**: SKILL.md is compressed (~3.5K chars). Schemas referenced, not inlined.
7. **Idempotent**: install.sh and /st-bootstrap are safe to re-run.

## Development Rules

- Commands must be stack-agnostic (detect and adapt, don't assume)
- Never hardcode file paths — use relative paths or environment variables
- Every command must work in an empty project and in an existing one
- Every command must work with AND without `.stania/` directory
- install.sh must be idempotent (safe to re-run)
- SKILL.md must stay under 4KB — reference schemas instead of inlining them
- Test changes by running install.sh then using commands in a real project
