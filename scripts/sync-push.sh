#!/bin/bash
# sync-push.sh — Auto-commit and push uncommitted ~/.claude changes
# Runs on SessionEnd (primary: auto-commit & push at shutdown) and at SessionStart
# via hook-session-start.sh (catch-up push for leftover changes from the previous session).
# Fast no-op when working tree is clean.

CLAUDE_DIR="$HOME/.claude"

# Prevent git from prompting for credentials
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=""
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no"

# Only run if it's a git repo with a remote
if [ ! -d "$CLAUDE_DIR/.git" ] || ! git -C "$CLAUDE_DIR" remote get-url origin &>/dev/null; then
    exit 0
fi

# Quick check: any uncommitted changes? (skip if clean)
if git -C "$CLAUDE_DIR" diff --quiet HEAD 2>/dev/null && \
   [ -z "$(git -C "$CLAUDE_DIR" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    exit 0
fi

# Stage tracked changes only (skip untracked to avoid accidentally adding secrets)
git -C "$CLAUDE_DIR" add -u 2>/dev/null

# Stage known safe untracked directories
for dir in skills scripts agents references memory; do
    if [ -d "$CLAUDE_DIR/$dir" ]; then
        git -C "$CLAUDE_DIR" add "$CLAUDE_DIR/$dir/" 2>/dev/null || true
    fi
done

# Check if there's anything staged
if git -C "$CLAUDE_DIR" diff --cached --quiet 2>/dev/null; then
    exit 0
fi

# Commit with auto-generated message
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
git -C "$CLAUDE_DIR" commit -m "auto-sync: uncommitted changes from previous session ($TIMESTAMP)" --quiet 2>/dev/null || exit 0

# Push with timeout
TIMEOUT_CMD=""
command -v timeout &>/dev/null && TIMEOUT_CMD="timeout 15"
$TIMEOUT_CMD git -C "$CLAUDE_DIR" push origin HEAD:main --quiet 2>/dev/null || true

exit 0
