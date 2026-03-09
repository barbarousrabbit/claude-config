#!/bin/bash
# Auto-sync: pull latest Claude Code config at session start
CLAUDE_DIR="$HOME/.claude"

# Only run if it's a git repo with a remote
if [ -d "$CLAUDE_DIR/.git" ] && git -C "$CLAUDE_DIR" remote get-url origin &>/dev/null; then
    # Restore settings.json from remote (source of truth) before pulling
    # to avoid stash conflicts on this critical file
    git -C "$CLAUDE_DIR" checkout -- settings.json 2>/dev/null

    # Abort if there are unmerged (conflicted) files — pull would fail anyway
    if git -C "$CLAUDE_DIR" ls-files --unmerged | grep -q .; then
        echo "[sync-pull] WARNING: unmerged files found, skipping pull" >&2
        exit 0
    fi

    # Stash any other uncommitted changes (e.g. plugins cache)
    STASH_OUT=$(git -C "$CLAUDE_DIR" stash 2>/dev/null)

    # Pull latest (local branch may be 'master' while remote is 'main')
    git -C "$CLAUDE_DIR" pull --rebase --quiet origin main 2>/dev/null \
      || git -C "$CLAUDE_DIR" pull --rebase --quiet 2>/dev/null

    # Re-apply stashed changes only if something was stashed
    if echo "$STASH_OUT" | grep -q "Saved working directory"; then
        git -C "$CLAUDE_DIR" stash pop --quiet 2>/dev/null
    fi
fi
