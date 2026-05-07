#!/bin/bash
# Stania PreToolUse hook: auto-truncate verbose command output
# Reduces token consumption by 80-95% on test/build commands
# Install: copy to .claude/hooks/ and reference in settings.json

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

[ -z "$cmd" ] && echo '{}' && exit 0

# Pattern: test runners → show only failures + summary
if echo "$cmd" | grep -qE '^(pnpm test|pnpm vitest|npx vitest|pytest|go test|npm test|npx jest|npx playwright test)' && ! echo "$cmd" | grep -qE 'tail|head|grep'; then
  NEW_CMD="$cmd 2>&1 | tail -20"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":\"$NEW_CMD\"}}}"
  exit 0
fi

# Pattern: build commands → show only errors + summary
if echo "$cmd" | grep -qE '^(pnpm build|npm run build|npx next build|npx tsc|pnpm typecheck)' && ! echo "$cmd" | grep -qE 'tail|head|grep'; then
  NEW_CMD="$cmd 2>&1 | tail -10"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":\"$NEW_CMD\"}}}"
  exit 0
fi

# Pattern: git log/diff → limit output
if echo "$cmd" | grep -qE '^git (log|diff|show)' && ! echo "$cmd" | grep -qE 'tail|head|--stat|--oneline|--name-only'; then
  NEW_CMD="$cmd | head -50"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":\"$NEW_CMD\"}}}"
  exit 0
fi

# Pattern: install commands → show only summary
if echo "$cmd" | grep -qE '^(pnpm install|pnpm add|npm install|pip install)' && ! echo "$cmd" | grep -qE 'tail|head'; then
  NEW_CMD="$cmd 2>&1 | tail -5"
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\",\"updatedInput\":{\"command\":\"$NEW_CMD\"}}}"
  exit 0
fi

echo '{}'
