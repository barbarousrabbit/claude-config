#!/bin/bash
# Auto-sync: pull latest Claude Code config at session start
# MUST NOT block — all operations have timeouts and fallbacks
CLAUDE_DIR="$HOME/.claude"

# Prevent git from prompting for credentials (would hang in hook context)
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=""
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no"

# Only run if it's a git repo with a remote
if [ -d "$CLAUDE_DIR/.git" ] && git -C "$CLAUDE_DIR" remote get-url origin &>/dev/null; then
    # If a previous rebase was interrupted, abort it first
    if [ -d "$CLAUDE_DIR/.git/rebase-merge" ] || [ -d "$CLAUDE_DIR/.git/rebase-apply" ]; then
        git -C "$CLAUDE_DIR" rebase --abort 2>/dev/null
    fi

    # Abort if there are unmerged (conflicted) files — pull would fail anyway
    if git -C "$CLAUDE_DIR" ls-files --unmerged | grep -q .; then
        git -C "$CLAUDE_DIR" reset --hard HEAD 2>/dev/null
    fi

    # Stash any uncommitted changes (e.g. plugins cache)
    STASH_OUT=$(git -C "$CLAUDE_DIR" stash 2>/dev/null)

    # Pull latest with 15-second timeout (prevents hanging on slow network)
    # Fall back to no-timeout if `timeout` command unavailable
    TIMEOUT_CMD=""
    command -v timeout &>/dev/null && TIMEOUT_CMD="timeout 15"
    $TIMEOUT_CMD git -C "$CLAUDE_DIR" pull --rebase --quiet origin main 2>/dev/null \
      || $TIMEOUT_CMD git -C "$CLAUDE_DIR" pull --rebase --quiet 2>/dev/null \
      || true

    # If rebase failed mid-way, abort to keep repo clean
    if [ -d "$CLAUDE_DIR/.git/rebase-merge" ] || [ -d "$CLAUDE_DIR/.git/rebase-apply" ]; then
        git -C "$CLAUDE_DIR" rebase --abort 2>/dev/null
    fi

    # Re-apply stashed changes only if something was stashed
    if echo "$STASH_OUT" | grep -q "Saved working directory"; then
        git -C "$CLAUDE_DIR" stash pop --quiet 2>/dev/null || true
    fi
fi
