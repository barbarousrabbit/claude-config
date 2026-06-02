#!/bin/bash
# SessionStart hook wrapper
CLAUDE_DIR="$HOME/.claude"

# 1. Push any uncommitted changes from previous session
bash "$CLAUDE_DIR/scripts/sync-push.sh" 2>/dev/null || true

# 2. Pull latest config from remote
bash "$CLAUDE_DIR/scripts/sync-pull.sh" 2>/dev/null || true

# 3. Check skills for staleness
bash "$CLAUDE_DIR/scripts/skill-check.sh" 2>/dev/null || true
