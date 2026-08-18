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
# Never hard-code the branch name: a device whose git defaults to `master`
# would silently skip this step (that is exactly what happened before
# 2026-07-27). Resolve the remote's real default branch, then make the local
# branch match it so every device converges on one name.
echo "-> Configuring git tracking..."
cd "$CLAUDE_DIR"
REMOTE_HEAD=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
if [ -z "$REMOTE_HEAD" ]; then
    git remote set-head origin --auto &>/dev/null
    REMOTE_HEAD=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
fi
REMOTE_HEAD="${REMOTE_HEAD:-main}"
LOCAL_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -n "$LOCAL_BRANCH" ] && [ "$LOCAL_BRANCH" != "$REMOTE_HEAD" ]; then
    if git show-ref --verify --quiet "refs/heads/$REMOTE_HEAD"; then
        warn "Local branch '$LOCAL_BRANCH' differs from remote default '$REMOTE_HEAD' and both exist — resolve manually"
    else
        git branch -m "$LOCAL_BRANCH" "$REMOTE_HEAD" 2>/dev/null \
            && info "Renamed local branch '$LOCAL_BRANCH' -> '$REMOTE_HEAD'"
        LOCAL_BRANCH="$REMOTE_HEAD"
    fi
fi
git branch --set-upstream-to="origin/$REMOTE_HEAD" "$LOCAL_BRANCH" &>/dev/null || true
ok "Git tracking configured (branch '$LOCAL_BRANCH' -> origin/$REMOTE_HEAD)"

# -- 1a2. Working-copy line endings per .gitattributes (content untouched; skips modified files) --
echo "-> Normalising working-copy line endings..."
bash "$CLAUDE_DIR/scripts/normalize-eol.sh" || warn "normalize-eol.sh reported a problem"

# -- 1b. Third-party skill repos (mode=clone rows of scripts/skill-sources.tsv) --
echo "-> Installing third-party skill repos..."
bash "$CLAUDE_DIR/scripts/install-third-party-skills.sh" || warn "Some third-party skills failed to install (see above)"

# -- 1c. Codex-format skills -> ~/.codex/skills (one-way mirror; no-op without Codex) --
echo "-> Mirroring Codex-format skills into ~/.codex/skills..."
bash "$CLAUDE_DIR/scripts/mirror-skills-to-codex.sh" || warn "Codex skill mirror reported a problem (see above)"

# -- 1d. Upstream check for vendored skills (report only; the SessionStart hook applies weekly) --
echo "-> Checking vendored skills against upstream (scripts/skill-sources.tsv)..."
bash "$CLAUDE_DIR/scripts/update-skills.sh" --check || warn "Some upstreams were unreachable or misconfigured (see .skill-update/report.txt)"

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
