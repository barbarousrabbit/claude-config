#!/bin/bash
# SessionStart hook wrapper
CLAUDE_DIR="$HOME/.claude"

# 1. Sync config from remote
bash "$CLAUDE_DIR/scripts/sync-pull.sh" 2>/dev/null || true

# 2. Check skills for staleness
bash "$CLAUDE_DIR/scripts/skill-check.sh" 2>/dev/null || true
