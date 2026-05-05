---
name: st
description: "Engineering workflow with state tracking. Contract-first parallel development. Role-aware guidance. 5-stage pipeline: SPEC → BUILD → CHECK → SHIP → RETRO. Team mode: agents + interns work in parallel."
---

# Stania — Engineering Workflow

You are operating under Stania engineering discipline.

## Role Detection (ALWAYS check first)

On session start, read `.stania/me.json`. If missing, ask:
"¿Cuál es tu rol? (lead / frontend / pm / solo)" → create file.

Also read `.stania/config.json` for the `mode` field. If `mode` is `"solo"`:
- Skip role distinction — user is everything (lead + frontend + backend)
- me.json role should default to `"solo"`
- All commands available, no role filtering

```json
{ "role": "lead|frontend|pm|solo", "name": "Name" }
```

### Role-based behavior:

**lead** — Full access. Proactively suggest: pending PR reviews, contracts without agents, integrations ready.
**frontend** — Only suggest: /st-ui, /st-ui --refine, /st-ui --new, /st-next. Hide backend complexity.
**pm** — Only suggest: /st-board, /st-next, /st-status. Focus on progress and blockers.
**solo** — Full access. No approval gates, no PRs, no issues. Direct commit to main. Autonomous execution.

When user asks a vague question ("qué hago?" / "what's next?"), run /st-next logic internally.

## Two Modes

### Solo mode (one engineer + Claude):
PLAN → DO → CHECK → SHIP (no approval gates, no PRs, no issues)

**Solo mode flow**:
- `/st-build` in solo: builds all layers at once (domain → app → infra → tests), NO approval gates between layers, spawns parallel agents for independent aggregates
- `/st-contract` in solo: just generates types in contracts package, skip mocks/client/ports generation, skip issue creation
- `/st-ship` in solo: commit directly to main, no PR creation, just audit + commit
- `/st-agent` in solo: works inline on main branch (no feature branches), runs check internally, only surfaces when DONE or BLOCKED
- `/st-next` in solo: suggests "Build next aggregate" or "Fix mutation gap", never "Review PR" or "Approve stub"
- `/st-need-contract` in solo: skip — you define and build directly
- `/st-spec` in solo: quick inline plan, no spec file creation

### Team mode (contract-first, parallel):
CONTRACT → agents implement backend + frontend implements UI → INTEGRATE → SHIP

## State (.stania/)

State is **advisory, not blocking**. If missing, commands fall back to filesystem scanning.

```
.stania/
├── me.json              ← Current user role (gitignored)
├── config.json          ← Stack, architecture, deploy, team settings
├── domain-model.json    ← Bounded contexts, aggregates, VOs, events
├── progress.json        ← Per-aggregate implementation status
├── specs/{slug}.md      ← Approved specs
└── ui-specs/{name}.md   ← UI component specs (for /st-ui)
```

## Solo Mode Autonomy Rules

When mode = "solo", agents operate autonomously:
1. Build all layers (domain → app → infra → tests) without pausing
2. Run typecheck + tests internally (skip lint — orchestrator handles lint once at end)
3. Only surface to user when:
   - DONE: all layers built + check passed → "Ready to test at [URL]"
   - BLOCKED: needs a design decision the code can't answer
   - NEVER: "here's what I did, what do you think?"
4. Multiple aggregates → group by bounded context, spawn one agent per context (not per aggregate)
5. Agent prompts include inline code patterns — agents do NOT read external pattern files
6. No GitHub issues, no PRs, no branches — commit directly to main
7. After all agents complete, orchestrator runs single lint pass: `biome check --write` (or equivalent)
8. Reports should be <100 words

## Pipeline Commands

| Command | Who | Purpose | Solo |
|---------|-----|---------|------|
| /st-next | Anyone | **What should I do now?** (role-aware guidance) | No "Review PR"/"Approve stub" suggestions |
| /st-quick | Anyone | T1/T2: validate → commit (no ceremony) | Same |
| /st-contract | Lead | Define API contract → generates mocks + ports + client | Types only, skip mocks/client/ports/issues |
| /st-contract --from-stub | Lead | Promote frontend stub to official contract | Skip — build directly |
| /st-need-contract | Frontend | Create stub + mock + issue when endpoint missing | Skip — define and build directly |
| /st-agent | Lead | Launch autonomous backend implementation | Inline on main, no branches, auto-check |
| /st-ui | Frontend | Generate component from UI spec | Same |
| /st-ui --refine | Frontend | Adjust styles in natural language | Same |
| /st-board | PM/Lead | Show GitHub Issues/PRs status board | Same (reads local state) |
| /st-integrate | Lead | Replace mocks with real backend + e2e | Skip — no mocks to replace |
| /st-e2e | Lead | Generate Playwright E2E tests from contracts | Same |
| /st-migrate | Lead | Handle contract evolution (breaking changes) | Same |
| /st-seed | Anyone | Generate realistic test fixtures | Same |
| /st-deps | Lead | Dependency health audit + auto-fix | Same |
| /st-spec | Lead | Formal spec (when contract isn't enough) | Quick inline plan, no spec file |
| /st-build | Lead | Layer-by-layer generation with approval | All layers at once, no gates, parallel aggregates |
| /st-check | Anyone | Validation pipeline (parallel) | Same |
| /st-ship | Lead | Incremental audit + PR | Audit + commit to main, no PR |
| /st-retro | Anyone | Session close | Same |
| /st-bootstrap | Lead | Project setup (repo, deploy, CI/CD) | Skip branch protection, skip labels |
| /st-model | Lead | DDD domain model extraction | Same |
| /st-mutate | Anyone | Mutation testing (on demand) | Same |
| /st-status | Anyone | Progress from .stania/progress.json | Same |
| /st-cost | Anyone | Token estimation for current session | Same |

## Proactive Guidance

After any command completes, suggest the logical next step:

- After /st-bootstrap → "Run /st-model to define your domain"
- After /st-model → "Run /st-contract <first-feature> to define first API"
- After /st-contract → "Run /st-agent <name> to start backend. Frontend: write spec in ui-specs/"
- After /st-need-contract → "Stub created. Continue building UI against mock. Lead will review."
- After /st-contract --from-stub → "Contract promoted. Run /st-agent <name> for backend."
- After /st-agent completes → "PR ready. Review then /st-integrate"
- After /st-ui → "Review in Storybook. Adjust with /st-ui --refine"
- After /st-integrate → "Run /st-e2e <name> for end-to-end tests"
- After /st-check fails → Suggest specific fix, then "re-run /st-check"
- After /st-ship → "/st-retro to close session"

## Core Principles

1. Right-size ceremony — /st-quick for simple, full pipeline for complex
2. Contract-first — define API surface before implementation
3. Parallel by default — frontend and backend work simultaneously via mocks
4. Agents do execution — humans make decisions
5. Validate once — /st-check owns validation, /st-build does NOT re-run it
6. Truncate output — `| tail -N` always, read full only on failure
7. Merge = deploy — no manual deploys
8. Role-aware — show only what's relevant to the user's role

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

- **T1 Auto**: UI, config, cosmetic → /st-quick
- **T2 Light**: New features → pipeline + PR review
- **T3 Deep**: Domain, security, billing → full pipeline + mutations

## Clean Architecture (when applicable)

- Domain: ZERO external imports, private constructors + factory, Result pattern
- Value Objects over primitives (Email not string, Money not number)
- Ports in domain, implementations in infrastructure

## Token Efficiency Rules

1. **Truncate all tool output**: Always `| tail -N`. Read full only on failure.
2. **No duplicate validation**: /st-build does typecheck only.
3. **Incremental /st-ship**: Skip re-validation if lastCheck < 10 min.
4. **Parallel validation**: In /st-check, typecheck + lint + tests as 3 simultaneous calls.
5. **Lazy loading**: Only read the specific aggregate/spec needed.
6. **testFlags config**: Read `config.json` → `testFlags.fast` for flags.
7. **Session split**: After heavy iterations, suggest new session.
8. **Context7 MCP**: If available, use for API hallucination checks.
9. **Inline patterns**: In solo mode, agent prompts include code pattern snippets directly — agents do NOT read pattern files. Saves ~8K tokens per agent.
10. **Bounded context grouping**: When spawning multiple agents, group aggregates by bounded context — 1 agent per context, not 1 per aggregate. Saves ~4K tokens per merged agent and eliminates shared-file conflicts.
11. **Orchestrator lint**: In solo mode, agents skip lint (only typecheck + tests). Orchestrator runs single `biome check --write` (or equivalent) AFTER all agents complete. Saves ~2K tokens per agent and avoids redundant lint passes.
12. **Frontend inline patterns**: Agent prompts include dark-theme design tokens, Next.js page skeleton, query hook template, and nav structure — frontend agents do NOT read existing pages for reference.
13. **Audit before frontend**: After backend agents complete, run a quick audit agent to catch naming inconsistencies, missing files, or port mismatches BEFORE spawning frontend agents. Catches issues early, prevents cascading errors.

## Token Efficiency — Estimation

After each command completes, show estimated token usage:

Estimation heuristics:
- File read: chars / 3.5 tokens (code averages ~3.5 chars/token)
- Bash output: chars / 4 tokens
- Edit/Write: new content chars / 3.5 tokens
- System prompt + CLAUDE.md: ~3000 tokens (loaded once per agent)
- Agent spawn overhead: ~4000 tokens (system + context)

Format:
⚡ ~X tokens (Y reads, Z bash, W edits) | session: ~total

Track cumulative across the session. Show after each / command.

## Stack Detection

1. `.stania/config.json` → 2. package.json/pyproject.toml/go.mod → 3. Ask user

| Stack | Typecheck | Lint | Test | Mutate |
|-------|-----------|------|------|--------|
| TS | tsc | Biome | Vitest | Stryker |
| Python | mypy | ruff | pytest | mutmut |
| Go | go vet | golangci-lint | go test | go-mutesting |
