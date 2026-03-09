#!/bin/bash
# SessionStart hook wrapper
CLAUDE_DIR="$HOME/.claude"

# 1. Sync config from remote
bash "$CLAUDE_DIR/scripts/sync-pull.sh" 2>/dev/null || true
