#!/bin/bash

# Stania — From vibe coding to production-ready engineering
# Install per-project (default): bash install.sh
# Install globally:              bash install.sh --global
# Uninstall:                     bash install.sh --uninstall [--global]
# Remote:                        curl -fsSL https://raw.githubusercontent.com/cloudpetals/stania/main/install.sh | bash

set -e

VERSION="2.3.1"
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
GLOBAL=false
UNINSTALL=false
STANIA_DIR=""

for arg in "$@"; do
    case $arg in
        --dry-run)   DRY_RUN=true ;;
        --global)    GLOBAL=true ;;
        --uninstall) UNINSTALL=true ;;
    esac
done

echo ""
echo -e "${BOLD}  Stania v${VERSION}${NC}"
echo -e "  ${DIM}From vibe coding to production-ready engineering${NC}"
echo ""

# Detect source: piped from curl or run from local clone
if [ -t 0 ] && [ -f "$(dirname "$0")/commands/st-bootstrap.md" ]; then
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

# --- Determine target directories ---

if [ "$GLOBAL" = true ]; then
    CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    TARGET_CMD_DIR="$CLAUDE_CONFIG_DIR/commands"
    TARGET_SKILLS_DIR="$CLAUDE_CONFIG_DIR/skills"
    INSTALL_LABEL="global (~/.claude/)"
else
    # Per-project: install to .claude/ in current working directory
    PROJECT_DIR="$(pwd)"
    TARGET_CMD_DIR="$PROJECT_DIR/.claude/commands"
    TARGET_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
    INSTALL_LABEL="project ($PROJECT_DIR/.claude/)"
fi

echo -e "  ${DIM}Target: ${INSTALL_LABEL}${NC}"
echo ""

# --- Claude Code detection ---

detect_claude_code() {
    command -v claude &>/dev/null && return 0
    [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] && return 0
    return 1
}

if detect_claude_code; then
    echo -e "  ${GREEN}✓${NC} Claude Code detected"
else
    echo -e "  ${YELLOW}!${NC} Claude Code not detected (installing anyway)"
fi

# --- Uninstall ---

if [ "$UNINSTALL" = true ]; then
    echo ""
    REMOVED=0
    for cmd in st-bootstrap st-spec st-build st-check st-ship st-retro st-mutate st-model st-status; do
        target="$TARGET_CMD_DIR/${cmd}.md"
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
    if [ -d "$TARGET_SKILLS_DIR/st" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[dry-run]${NC} Would remove skill: st"
        else
            rm -rf "$TARGET_SKILLS_DIR/st"
            echo -e "  ${RED}-${NC}  Removed: skill st"
        fi
    fi

    # Remove project settings if per-project
    if [ "$GLOBAL" = false ] && [ -f "$PROJECT_DIR/.claude/settings.json" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[dry-run]${NC} Would remove .claude/settings.json"
        else
            rm "$PROJECT_DIR/.claude/settings.json"
            echo -e "  ${RED}-${NC}  Removed: .claude/settings.json"
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
    mkdir -p "$TARGET_CMD_DIR"
fi

NEW=0
UPDATED=0
UNCHANGED=0

for cmd in "$STANIA_DIR/commands/"*.md; do
    [ -f "$cmd" ] || continue
    filename=$(basename "$cmd")
    name=$(basename "$filename" .md)
    target="$TARGET_CMD_DIR/$filename"

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

if [ -d "$STANIA_DIR/skills/st" ]; then
    echo ""
    echo -e "  ${BOLD}Installing skill...${NC}"

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[dry-run]${NC} Would install skill: st"
    else
        mkdir -p "$TARGET_SKILLS_DIR/st"
        cp "$STANIA_DIR/skills/st/SKILL.md" "$TARGET_SKILLS_DIR/st/SKILL.md"
        echo -e "  ${GREEN}+${NC}  Installed: skill st"
    fi
fi

# --- Install project settings (per-project only) ---

if [ "$GLOBAL" = false ]; then
    SETTINGS_FILE="$PROJECT_DIR/.claude/settings.json"
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo ""
        echo -e "  ${BOLD}Creating project settings...${NC}"

        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[dry-run]${NC} Would create .claude/settings.json"
        else
            mkdir -p "$PROJECT_DIR/.claude"
            cp "$STANIA_DIR/templates/settings.json" "$SETTINGS_FILE" 2>/dev/null || \
            cat > "$SETTINGS_FILE" << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(pnpm:*)",
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(yarn:*)",
      "Bash(uv:*)",
      "Bash(pip:*)",
      "Bash(python -m pytest:*)",
      "Bash(python -m mypy:*)",
      "Bash(go:*)",
      "Bash(cargo:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(wc:*)",
      "Bash(ls:*)"
    ]
  }
}
SETTINGS
            echo -e "  ${GREEN}+${NC}  Created: .claude/settings.json (lean permissions)"
        fi
    else
        echo ""
        echo -e "  ${DIM}  Skipped: .claude/settings.json (already exists)${NC}"
    fi
fi

# --- Remove global installation if installing per-project ---

if [ "$GLOBAL" = false ]; then
    GLOBAL_CMD_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/commands"
    GLOBAL_SKILLS_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
    FOUND_GLOBAL=false

    for cmd in st-bootstrap st-spec st-build st-check st-ship st-retro st-mutate st-model st-status; do
        if [ -f "$GLOBAL_CMD_DIR/${cmd}.md" ]; then
            FOUND_GLOBAL=true
            break
        fi
    done

    if [ "$FOUND_GLOBAL" = true ]; then
        echo ""
        echo -e "  ${YELLOW}!${NC} Found global Stania installation (~/.claude/)"
        echo -e "  ${DIM}  Global install loads skill into ALL conversations (~1,800 tokens wasted)${NC}"
        echo ""
        read -p "    Remove global installation? [Y/n] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            for cmd in st-bootstrap st-spec st-build st-check st-ship st-retro st-mutate st-model st-status; do
                [ -f "$GLOBAL_CMD_DIR/${cmd}.md" ] && rm "$GLOBAL_CMD_DIR/${cmd}.md"
            done
            [ -d "$GLOBAL_SKILLS_DIR/st" ] && rm -rf "$GLOBAL_SKILLS_DIR/st"
            echo -e "  ${GREEN}✓${NC} Global installation removed"
        fi
    fi
fi

# --- Summary ---

echo ""
echo -e "  ${BOLD}${GREEN}Done.${NC} ${NEW} new, ${UPDATED} updated, ${UNCHANGED} unchanged"
echo ""
echo -e "  ${BOLD}Start here:${NC}"
echo -e "    ${GREEN}/st-next${NC}       What should I do now? (role-aware guidance)"
echo ""
echo -e "  ${BOLD}Team workflow:${NC}"
echo -e "    ${GREEN}/st-bootstrap${NC}  Project setup (repo, CI/CD, deploy)"
echo -e "    ${GREEN}/st-contract${NC}   Define API contract → mocks + types + client"
echo -e "    ${GREEN}/st-agent${NC}      Launch autonomous backend agent"
echo -e "    ${GREEN}/st-ui${NC}         Generate frontend from spec"
echo -e "    ${GREEN}/st-integrate${NC}  Connect frontend to real backend"
echo -e "    ${GREEN}/st-board${NC}      GitHub status board"
echo ""
echo -e "  ${BOLD}Quality & maintenance:${NC}"
echo -e "    ${BLUE}/st-e2e${NC}        Generate Playwright E2E tests"
echo -e "    ${BLUE}/st-migrate${NC}    Handle contract evolution"
echo -e "    ${BLUE}/st-seed${NC}       Generate test fixtures"
echo -e "    ${BLUE}/st-deps${NC}       Dependency health audit"
echo -e "    ${BLUE}/st-check${NC}      Validation pipeline"
echo -e "    ${BLUE}/st-mutate${NC}     Mutation testing"
echo ""
echo -e "  ${BOLD}Engineering pipeline:${NC}"
echo -e "    ${DIM}/st-quick${NC}       Fast path (validate + commit)"
echo -e "    ${DIM}/st-spec${NC}        Formal spec"
echo -e "    ${DIM}/st-build${NC}       Layer-by-layer generation"
echo -e "    ${DIM}/st-ship${NC}        Pre-deploy audit + PR"
echo -e "    ${DIM}/st-retro${NC}       Session close"
echo ""

if [ "$GLOBAL" = false ]; then
    echo -e "  ${BOLD}Token savings vs global install:${NC}"
    echo -e "    ${GREEN}~52,000 tokens/turn${NC} saved (skill not loaded in other projects)"
    echo ""
    echo -e "  ${DIM}Installed per-project. Only active in this directory.${NC}"
    echo -e "  ${DIM}To install globally: bash install.sh --global${NC}"
else
    echo -e "  ${YELLOW}⚠${NC}  Global install: skill loads in ALL conversations (~1,800 tokens/turn)"
    echo -e "  ${DIM}Consider per-project install for token efficiency.${NC}"
fi
echo ""
