Capture project state snapshot for tracking development velocity and history.

## Usage

- `/st-snapshot` — Save current state snapshot
- `/st-snapshot --history` — Show snapshot timeline

## Step 1: Gather state

Read `.stania/progress.json` and compute:
- Total aggregates, done count, in-progress count
- Per bounded context: done/total
- Test count (from last check)
- Coverage (if available from last check)

```bash
git log --oneline -1 2>/dev/null
git rev-list --count HEAD 2>/dev/null
```

## Step 2: Save snapshot

Append to `.stania/snapshots.json` (create if missing):

```json
{
  "snapshots": [
    {
      "date": "<ISO8601>",
      "commit": "<short-hash>",
      "commitCount": 42,
      "aggregates": { "total": 6, "done": 4, "inProgress": 1 },
      "contexts": {
        "Training": { "done": 2, "total": 2 },
        "Nutrition": { "done": 2, "total": 3 }
      },
      "tests": 545,
      "coverage": 78
    }
  ]
}
```

## Step 3: Report

```
=== SNAPSHOT SAVED ===
Date: 2026-05-07  Commit: abc1234 (#42)
Aggregates: 4/6 (67%)  Tests: 545  Coverage: 78%

VELOCITY (last 3 snapshots):
  May 05: 2/6 → May 06: 3/6 → May 07: 4/6
  +1 aggregate/day avg
```

## --history mode

Display last 10 snapshots as timeline:
```
=== SNAPSHOT HISTORY ===
May 01 | ## ........  | 2/10 (20%) | 120 tests
May 03 | #### ......  | 4/10 (40%) | 280 tests
May 05 | ###### ....  | 6/10 (60%) | 410 tests
May 07 | ######## ..  | 8/10 (80%) | 545 tests

Velocity: 2 aggregates/day avg
```

## Rules

- Read-merge-write on snapshots.json (never overwrite)
- Max 50 snapshots stored (remove oldest when exceeding)
- .stania/snapshots.json should be gitignored
- If no progress.json: "Run /st-build first to have state to snapshot."
- One snapshot per day max (skip if already exists for today)
