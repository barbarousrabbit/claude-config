#!/bin/bash
# UserPromptSubmit hook wrapper
CLAUDE_DIR="$HOME/.claude"

bash "$CLAUDE_DIR/scripts/claudeception-activator.sh" \
    2>/dev/null || true
