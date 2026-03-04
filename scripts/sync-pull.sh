#!/bin/bash
# Auto-sync: pull latest Claude Code config at session start
CLAUDE_DIR="$HOME/.claude"

# Only run if it's a git repo with a remote
if [ -d "$CLAUDE_DIR/.git" ] && git -C "$CLAUDE_DIR" remote get-url origin &>/dev/null; then
    # Stash any uncommitted changes to avoid conflicts
    git -C "$CLAUDE_DIR" stash --quiet 2>/dev/null

    # Pull latest
    git -C "$CLAUDE_DIR" pull --rebase --quiet 2>/dev/null

    # Re-apply stashed changes if any
    git -C "$CLAUDE_DIR" stash pop --quiet 2>/dev/null
fi
