#!/bin/bash
# UserPromptSubmit hook wrapper
CLAUDE_DIR="$HOME/.claude"

bash "$CLAUDE_DIR/scripts/run-python.sh" \
    "$CLAUDE_DIR/skills/claude-reflect/scripts/capture_learning.py" \
    2>/dev/null || true
