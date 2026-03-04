#!/bin/bash
# SessionStart hook wrapper — 跨设备兼容
CLAUDE_DIR="$HOME/.claude"

# 1. 同步配置
bash "$CLAUDE_DIR/scripts/sync-pull.sh" 2>/dev/null || true

# 2. 健康检查
bash "$CLAUDE_DIR/scripts/run-python.sh" \
    "$CLAUDE_DIR/skills/claude-reflect/scripts/session_start_reminder.py" \
    2>/dev/null || true
