#!/bin/bash
# Install Salesforce Skills for AI Coding Agents
#
# Supports: Claude Code, Cursor, Codex, Gemini CLI, and 50+ AI tools
#
# Usage:
#   npx skills add Clientell-Ai/salesforce-skills    # Recommended
#   ./install.sh [target-project-dir]             # Manual install
#   ./install.sh --help                           # Show help
#
# Exit codes:
#   0 — Installation successful
#   1 — Installation failed
#   2 — Invalid arguments

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            echo "Salesforce Skills for AI Coding Agents — Installer"
            echo ""
            echo "Usage:"
            echo "  ./install.sh [target-project-dir]"
            echo "  ./install.sh --help"
            echo ""
            echo "Installs Salesforce development skills for Claude Code, Cursor,"
            echo "Codex, and 50+ other AI coding agents."
            echo ""
            echo "Recommended: npx skills add Clientell-Ai/salesforce-skills"
            echo ""
            echo "Skills installed:"
            echo "  sf-apex      Apex code generation & review"
            echo "  sf-test      Test class generation"
            echo "  sf-flow      Flow generation & PB migration"
            echo "  sf-lwc       LWC scaffolding"
            echo "  sf-soql      SOQL query building"
            echo "  sf-security  Security audit"
            echo "  sf-deploy    Deployment orchestration"
            echo "  sf-data      Data migration & management"
            echo "  sf-schema    Schema & permission management"
            echo "  sf-find      Skill discovery"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
        *)
            TARGET="$1"
            shift
            ;;
    esac
done

TARGET="${TARGET:-.}"

if [ ! -d "$TARGET" ]; then
    echo "Error: Target directory not found: $TARGET" >&2
    exit 2
fi

echo "Salesforce Skills — Installing to: $TARGET"
echo "================================================"

SKILLS=(sf-apex sf-test sf-flow sf-lwc sf-soql sf-security sf-deploy sf-data sf-schema sf-find)

# Create directory structure
mkdir -p "$TARGET/.claude/skills"
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.agents/skills"

# Install skills to canonical location
echo ""
echo "Installing skills..."
mkdir -p "$TARGET/skills"
for skill in "${SKILLS[@]}"; do
    if [ -d "$SCRIPT_DIR/skills/$skill" ]; then
        cp -r "$SCRIPT_DIR/skills/$skill" "$TARGET/skills/"
        echo "  + $skill"
    fi
done

# Create symlinks for Claude Code
echo ""
echo "Creating Claude Code symlinks (.claude/skills/)..."
for skill in "${SKILLS[@]}"; do
    target_link="$TARGET/.claude/skills/$skill"
    rm -rf "$target_link"
    if ln -s "../../skills/$skill" "$target_link" 2>/dev/null; then
        echo "  -> $skill"
    else
        # Fallback: copy if symlinks not supported (Windows)
        cp -r "$TARGET/skills/$skill" "$target_link" 2>/dev/null || true
        echo "  ~ $skill (copied, symlink not supported)"
    fi
done

# Create symlinks for cross-client (.agents/skills/)
echo ""
echo "Creating cross-client symlinks (.agents/skills/)..."
for skill in "${SKILLS[@]}"; do
    target_link="$TARGET/.agents/skills/$skill"
    rm -rf "$target_link"
    if ln -s "../../skills/$skill" "$target_link" 2>/dev/null; then
        echo "  -> $skill"
    else
        cp -r "$TARGET/skills/$skill" "$target_link" 2>/dev/null || true
        echo "  ~ $skill (copied)"
    fi
done

# Install agents (Claude Code only)
echo ""
echo "Installing agents (.claude/agents/)..."
for agent_file in "$SCRIPT_DIR/.claude/agents"/*.md; do
    if [ -f "$agent_file" ]; then
        agent_name=$(basename "$agent_file")
        cp "$agent_file" "$TARGET/.claude/agents/"
        echo "  + ${agent_name%.md}"
    fi
done

# Install shared references
echo ""
echo "Installing references..."
mkdir -p "$TARGET/references"
if [ -f "$SCRIPT_DIR/references/governor-limits.md" ]; then
    cp "$SCRIPT_DIR/references/governor-limits.md" "$TARGET/references/"
    echo "  + governor-limits.md"
fi

# Install scripts
echo ""
echo "Installing scripts..."
mkdir -p "$TARGET/scripts"
for script in "$SCRIPT_DIR/scripts"/*.sh; do
    if [ -f "$script" ]; then
        cp "$script" "$TARGET/scripts/"
        chmod +x "$TARGET/scripts/$(basename "$script")"
        echo "  + $(basename "$script")"
    fi
done

# Install config (only if not exists)
if [ ! -f "$TARGET/.claude/.mcp.json" ]; then
    cp "$SCRIPT_DIR/.claude/.mcp.json" "$TARGET/.claude/"
    echo ""
    echo "Installed MCP config (disabled by default)"
fi

if [ ! -f "$TARGET/.claude/settings.json" ]; then
    cp "$SCRIPT_DIR/.claude/settings.json" "$TARGET/.claude/"
    echo "Installed default settings"
fi

echo ""
echo "================================================"
echo "Installation complete!"
echo ""
echo "Available skills:"
for skill in "${SKILLS[@]}"; do
    echo "  /$skill"
done
echo ""
echo "Next steps:"
echo "  1. Install SF CLI: npm install @salesforce/cli -g"
echo "  2. Authenticate: sf org login web --alias myOrg"
echo "  3. Start using: claude (then type /sf-find for guidance)"
echo ""
echo "Alternative install: npx skills add Clientell-Ai/salesforce-skills"
