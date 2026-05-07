Database migration management. Detect ORM, generate, validate, and apply migrations safely.

## Usage

- `/st-migrate-db` — Show migration status
- `/st-migrate-db generate <name>` — Generate new migration from schema changes
- `/st-migrate-db apply` — Apply pending migrations (with confirmation)
- `/st-migrate-db rollback` — Rollback last migration
- `/st-migrate-db validate` — Check migrations are consistent with schema

## Step 1: Detect ORM

```bash
grep -l "drizzle\|prisma\|typeorm\|knex\|sequelize" package.json 2>/dev/null
```

| ORM | Generate | Apply | Rollback | Status |
|-----|----------|-------|----------|--------|
| Drizzle | `pnpm drizzle-kit generate` | `pnpm drizzle-kit migrate` | `pnpm drizzle-kit drop` | `pnpm drizzle-kit status` |
| Prisma | `pnpm prisma migrate dev --name <name>` | `pnpm prisma migrate deploy` | manual | `pnpm prisma migrate status` |
| Knex | `pnpm knex migrate:make <name>` | `pnpm knex migrate:latest` | `pnpm knex migrate:rollback` | `pnpm knex migrate:status` |

If no ORM detected: "No ORM found. Install drizzle-kit or prisma first."

## Step 2: Status (default)

```bash
<orm-status-command> 2>&1 | tail -10
```

Report: pending migrations count, last applied, schema drift.

## Step 3: Generate

Before generating:
1. Read schema files to understand changes
2. Generate migration: `<orm-generate> 2>&1 | tail -5`
3. Read generated SQL: show to user for review
4. Check for destructive operations (DROP TABLE, DROP COLUMN, ALTER TYPE)
5. If destructive: WARNING + require explicit confirmation

```
=== MIGRATION GENERATED ===
Name: 0003_add_check_constraints
Operations: 2 ALTER TABLE (safe), 1 ADD COLUMN (safe)
Destructive: NONE
File: drizzle/0003_add_check_constraints.sql
```

## Step 4: Apply

```bash
<orm-apply-command> 2>&1 | tail -10
```

Pre-checks:
- [ ] DATABASE_URL is set
- [ ] No pending uncommitted schema changes
- [ ] Migration file committed to git

Post-apply: verify with status command.

## Step 5: Validate

Compare current schema definition with database state:
```bash
<orm-status-command> 2>&1 | tail -10
```

Check for:
- Schema drift (code says X, DB says Y)
- Orphan migrations (in DB but not in code)
- Missing migrations (in code but not applied)

## Step 6: Rollback

Show what will be rolled back → confirm → execute:
```bash
<orm-rollback-command> 2>&1 | tail -5
```

If ORM doesn't support rollback (Prisma): suggest manual approach.

## Safety rules

- NEVER apply migrations without user confirmation
- NEVER auto-generate migrations in production
- Always show SQL before applying
- Flag destructive operations explicitly
- Suggest backup before destructive migrations
- Truncate all output (tail -10 max)
