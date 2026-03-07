#!/bin/bash
# SessionStart hook wrapper
CLAUDE_DIR="$HOME/.claude"

# 1. Sync config from remote
bash "$CLAUDE_DIR/scripts/sync-pull.sh" 2>/dev/null || true

# 2. Health check
bash "$CLAUDE_DIR/scripts/run-python.sh" \
    "$CLAUDE_DIR/skills/claude-reflect/scripts/session_start_reminder.py" \
    2>/dev/null || true
