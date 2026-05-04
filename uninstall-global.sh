#!/bin/bash

# Remove Stania from global Claude Code installation
# This saves ~1,800 tokens per conversation in projects that don't use Stania

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
DIM='\033[2m'
NC='\033[0m'

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

echo ""
echo "  Removing global Stania installation..."
echo ""

REMOVED=0

for cmd in st-bootstrap st-spec st-build st-check st-ship st-retro st-mutate st-model st-status; do
    target="$CLAUDE_DIR/commands/${cmd}.md"
    if [ -f "$target" ]; then
        rm "$target"
        echo -e "  ${RED}-${NC} $cmd"
        REMOVED=$((REMOVED + 1))
    fi
done

if [ -d "$CLAUDE_DIR/skills/st" ]; then
    rm -rf "$CLAUDE_DIR/skills/st"
    echo -e "  ${RED}-${NC} skill: st"
    REMOVED=$((REMOVED + 1))
fi

echo ""
if [ $REMOVED -gt 0 ]; then
    echo -e "  ${GREEN}Done.${NC} Removed $REMOVED items."
    echo -e "  ${DIM}Stania will only load in projects with .claude/skills/st/${NC}"
else
    echo -e "  ${DIM}Nothing to remove (not installed globally).${NC}"
fi
echo ""
