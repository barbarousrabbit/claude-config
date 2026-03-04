#!/bin/bash
# UserPromptSubmit hook wrapper — 跨设备兼容
CLAUDE_DIR="$HOME/.claude"

bash "$CLAUDE_DIR/scripts/run-python.sh" \
    "$CLAUDE_DIR/skills/claude-reflect/scripts/capture_learning.py" \
    2>/dev/null || true
