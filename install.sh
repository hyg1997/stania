#!/bin/bash

# Stania — From vibe coding to production-ready engineering
# Install: curl -fsSL https://raw.githubusercontent.com/cloudpetals/stania/main/install.sh | bash
# Usage:   bash install.sh [--minimal] [--dry-run] [--uninstall]

set -e

VERSION="2.0.0"
REPO_URL="https://github.com/cloudpetals/stania"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Flags
DRY_RUN=false
MINIMAL=false
UNINSTALL=false
STANIA_DIR=""

for arg in "$@"; do
    case $arg in
        --dry-run)   DRY_RUN=true ;;
        --minimal)   MINIMAL=true ;;
        --uninstall) UNINSTALL=true ;;
    esac
done

echo ""
echo -e "${BOLD}  Stania v${VERSION}${NC}"
echo -e "  ${DIM}From vibe coding to production-ready engineering${NC}"
echo ""

# Detect source: piped from curl or run from local clone
if [ -t 0 ] && [ -f "$(dirname "$0")/commands/bootstrap.md" ]; then
    STANIA_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo -e "  ${DIM}Source: local (${STANIA_DIR})${NC}"
else
    STANIA_DIR="$HOME/.stania-cli"
    echo -e "  ${DIM}Source: remote (cloning to ${STANIA_DIR})${NC}"

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[dry-run]${NC} Would clone ${REPO_URL} to ${STANIA_DIR}"
    else
        if [ -d "$STANIA_DIR/.git" ]; then
            echo -e "  ${DIM}Updating existing clone...${NC}"
            git -C "$STANIA_DIR" pull --quiet 2>/dev/null || true
        else
            git clone --quiet "$REPO_URL" "$STANIA_DIR" 2>/dev/null || {
                echo -e "  ${RED}Failed to clone. Check your internet connection.${NC}"
                exit 1
            }
        fi
    fi
fi

echo ""

# --- Claude Code ---

CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_CMD_DIR="$CLAUDE_CONFIG_DIR/commands"
CLAUDE_SKILLS_DIR="$CLAUDE_CONFIG_DIR/skills"

detect_claude_code() {
    command -v claude &>/dev/null && return 0
    [ -d "$CLAUDE_CONFIG_DIR" ] && return 0
    return 1
}

if detect_claude_code; then
    echo -e "  ${GREEN}✓${NC} Claude Code detected"
else
    echo -e "  ${YELLOW}!${NC} Claude Code not detected (installing anyway to ${CLAUDE_CMD_DIR})"
fi

# --- Uninstall ---

if [ "$UNINSTALL" = true ]; then
    echo ""
    REMOVED=0
    for cmd in bootstrap spec build check ship retro mutate model status; do
        target="$CLAUDE_CMD_DIR/${cmd}.md"
        if [ -f "$target" ]; then
            if [ "$DRY_RUN" = true ]; then
                echo -e "  ${YELLOW}[dry-run]${NC} Would remove /${cmd}"
            else
                rm "$target"
                echo -e "  ${RED}-${NC}  Removed: /${cmd}"
            fi
            REMOVED=$((REMOVED + 1))
        fi
    done

    # Remove skill
    if [ -d "$CLAUDE_SKILLS_DIR/stania" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[dry-run]${NC} Would remove skill: stania"
        else
            rm -rf "$CLAUDE_SKILLS_DIR/stania"
            echo -e "  ${RED}-${NC}  Removed: skill stania"
        fi
    fi

    echo ""
    echo -e "  ${GREEN}Stania uninstalled.${NC} ($REMOVED commands removed)"
    echo ""
    exit 0
fi

# --- Install Commands ---

echo ""
echo -e "  ${BOLD}Installing commands...${NC}"

if [ "$DRY_RUN" = false ]; then
    mkdir -p "$CLAUDE_CMD_DIR"
fi

NEW=0
UPDATED=0
UNCHANGED=0

for cmd in "$STANIA_DIR/commands/"*.md; do
    [ -f "$cmd" ] || continue
    filename=$(basename "$cmd")
    name=$(basename "$filename" .md)
    target="$CLAUDE_CMD_DIR/$filename"

    if [ "$DRY_RUN" = true ]; then
        if [ -f "$target" ]; then
            echo -e "  ${YELLOW}[dry-run]${NC} Would update: /${name}"
        else
            echo -e "  ${YELLOW}[dry-run]${NC} Would install: /${name}"
        fi
        NEW=$((NEW + 1))
    elif [ -f "$target" ]; then
        if ! diff -q "$cmd" "$target" > /dev/null 2>&1; then
            cp "$cmd" "$target"
            UPDATED=$((UPDATED + 1))
            echo -e "  ${BLUE}↻${NC}  Updated:   /${name}"
        else
            UNCHANGED=$((UNCHANGED + 1))
        fi
    else
        cp "$cmd" "$target"
        NEW=$((NEW + 1))
        echo -e "  ${GREEN}+${NC}  Installed: /${name}"
    fi
done

# --- Install Skill ---

if [ "$MINIMAL" = false ] && [ -d "$STANIA_DIR/skills/stania" ]; then
    echo ""
    echo -e "  ${BOLD}Installing skill...${NC}"

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[dry-run]${NC} Would install skill: stania"
    else
        mkdir -p "$CLAUDE_SKILLS_DIR/stania"
        cp "$STANIA_DIR/skills/stania/SKILL.md" "$CLAUDE_SKILLS_DIR/stania/SKILL.md"
        echo -e "  ${GREEN}+${NC}  Installed: skill stania"
    fi
fi

# --- Summary ---

echo ""
echo -e "  ${BOLD}${GREEN}Done.${NC} ${NEW} new, ${UPDATED} updated, ${UNCHANGED} unchanged"
echo ""
echo -e "  ${BOLD}Pipeline commands:${NC}"
echo -e "    ${GREEN}/bootstrap${NC}  From idea to configured project + .stania/ init"
echo -e "    ${GREEN}/spec${NC}       Write spec before coding (saved to .stania/specs/)"
echo -e "    ${GREEN}/build${NC}      Controlled generation (domain first, progress tracked)"
echo -e "    ${GREEN}/check${NC}      Validate + harden + AI code smells"
echo -e "    ${GREEN}/ship${NC}       Pre-deploy audit + PR"
echo -e "    ${GREEN}/retro${NC}      Session close + capture decisions"
echo ""
echo -e "  ${BOLD}Extra:${NC}"
echo -e "    ${BLUE}/mutate${NC}     Mutation testing (on demand)"
echo -e "    ${BLUE}/model${NC}      Extract DDD domain model → .stania/domain-model.json"
echo -e "    ${BLUE}/status${NC}     Implementation progress (reads .stania/progress.json)"
echo ""
echo -e "  ${DIM}State: .stania/ in each project (cross-session continuity)${NC}"
echo -e "  ${DIM}Docs: ${REPO_URL}${NC}"
echo ""
