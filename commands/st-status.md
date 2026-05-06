Project implementation status. Reads `.stania/progress.json` with filesystem fallback.

## Modes

- `/st-status` — Aggregate status table (default)
- `/st-status --prod` — Production readiness checklist

If `--prod`, jump to "Modo --prod" section.

## Default mode

1. Read `.stania/progress.json`. If missing: "Run /st-model first."
2. Report table per bounded context:

```
=== PROJECT STATUS ===
Last session: [date] — [summary]

Context: Training
| Aggregate      | Status | D | A | I | T |
|----------------|--------|---|---|---|---|
| Routine        | done   | Y | Y | Y | Y |
| WorkoutSession | done   | Y | Y | Y | Y |

Overall: X/Y complete (N%)
```

3. Suggest next action based on first incomplete aggregate.

---

## Modo --prod

**Run ALL scanning as a subagent** (Agent tool) to keep output out of main context.

The subagent should check these 6 categories and return a structured report:

1. **Persistence**: InMemory repos vs Pg repos, migrations, DATABASE_URL
2. **Auth**: middleware, provider, route protection
3. **Deploy**: Dockerfile, CI/CD, Vercel, Cloud Run, health check
4. **Security**: CORS, rate limiting, secrets, headers, Zod validation
5. **Observability**: structured logging, error tracking (Sentry), health endpoint
6. **Tests**: unit count, E2E files, integration tests, coverage

Subagent prompt should include: "Run all checks via grep/find, report as `[x]`/`[ ]` checklist per category. End with count of passing vs total. Max 40 lines output."

### After subagent returns

Display the report as-is, then generate action plan:
- Each step: `[S/M/L] What to do → why → command/skill`
- Order: persistence → auth → security → deploy → observability → tests
- Max 9 steps
- End with: `RESUMEN: X/Y passing. NEXT: [first step]`

## Rules
- Default mode: read progress.json only, no filesystem scanning
- --prod: always delegate scanning to subagent
- Never invent state — scan real project
- Max 9 steps in plan
