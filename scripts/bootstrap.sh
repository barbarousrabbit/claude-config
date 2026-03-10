#!/bin/bash
# =============================================================
# Claude Config Bootstrap — One-time setup for new Windows device
# Usage: bash ~/.claude/scripts/bootstrap.sh
# =============================================================
# NOTE: do NOT use set -e here — each step should run independently
# so a failure in one step (e.g., Python not found) doesn't abort the rest

CLAUDE_DIR="$HOME/.claude"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "    $1"; }

echo ""
echo "============================================"
echo "   Claude Config — New Device Bootstrap"
echo "============================================"
echo ""

# -- 0. Detect device environment --
echo "-> Detecting environment..."
bash "$CLAUDE_DIR/scripts/detect-env.sh" 2>/dev/null || warn "Environment detection had issues"
source "$CLAUDE_DIR/local-env.sh" 2>/dev/null || true
ok "Environment detected (Python=${CLAUDE_PYTHON:-NOT FOUND}, OS=${CLAUDE_OS:-unknown})"

# -- 1. Git branch tracking --
echo "-> Configuring git tracking..."
cd "$CLAUDE_DIR"
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null 2>&1; then
    git branch --set-upstream-to=origin/main master 2>/dev/null || \
    git branch --set-upstream-to=origin/main main 2>/dev/null || true
fi
ok "Git tracking configured"

# -- 2. Python dependencies --
echo "-> Installing Python skill dependencies..."
if [ -n "$CLAUDE_PIP" ] && command -v "$CLAUDE_PIP" &>/dev/null; then
    "$CLAUDE_PIP" install -q -r "$CLAUDE_DIR/skills/requirements.txt" 2>/dev/null && ok "Python dependencies installed" || warn "Some Python deps failed. Run manually: ${CLAUDE_PIP} install -r ~/.claude/skills/requirements.txt"
else
    warn "pip not found, skipping Python dependency install"
fi

# -- 3. Node.js / npx check --
echo "-> Checking Node.js..."
if command -v node &>/dev/null; then
    ok "Node.js $(node --version) installed"
else
    warn "Node.js not found — some MCP servers need npx. Install from https://nodejs.org"
fi

# -- 4. GitHub CLI check --
echo "-> Checking GitHub CLI..."
if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null 2>&1; then
        ok "gh CLI authenticated"
    else
        warn "gh CLI installed but not logged in. Run: gh auth login"
    fi
else
    warn "gh CLI not found — install from https://cli.github.com"
fi

# -- 5. MCP config --
echo "-> Checking MCP config..."
MCP_TARGET="$HOME/.claude/.mcp.json"
MCP_EXAMPLE="$CLAUDE_DIR/.mcp.json.example"

if [ -f "$MCP_TARGET" ]; then
    ok "MCP config exists: $MCP_TARGET"
else
    if [ -f "$MCP_EXAMPLE" ]; then
        cp "$MCP_EXAMPLE" "$MCP_TARGET"
        warn "MCP config created from template: $MCP_TARGET"
        info "Edit the file and fill in your API tokens:"
        info "  GitHub Token: https://github.com/settings/tokens"
    else
        warn "MCP template file not found"
    fi
fi

# -- 6. uv (optional faster pip) --
if ! command -v uv &>/dev/null; then
    warn "uv not found (faster pip alternative). Optional: pip install uv"
fi

# -- Done --
echo ""
echo "============================================"
ok "Bootstrap complete!"
echo ""
echo "Next steps (if any items above show [!]):"
echo "  1. Edit ~/.claude/.mcp.json and fill in API tokens"
echo "  2. Run 'gh auth login' to authenticate GitHub CLI"
echo "  3. Restart Claude Code for changes to take effect"
echo "============================================"
echo ""
