#!/bin/bash
# =============================================================
# run-python.sh — Cross-device Python launcher
# Usage: bash run-python.sh <script.py> [args...]
# Prefers the Python detected in local-env.sh, falls back to auto-detect
# =============================================================
SCRIPT="$1"
shift

ENV_FILE="$HOME/.claude/local-env.sh"

# 1. Load detected Python from local-env.sh
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
fi

# 2. If not set, re-detect
if [ -z "$CLAUDE_PYTHON" ] || ! command -v "$CLAUDE_PYTHON" &>/dev/null 2>&1; then
    for candidate in python py python3; do
        if command -v "$candidate" &>/dev/null 2>&1; then
            if "$candidate" -c "import sys; assert sys.version_info >= (3,8)" &>/dev/null 2>&1; then
                CLAUDE_PYTHON="$candidate"
                break
            fi
        fi
    done
fi

# 3. If still not found, exit 0 (don't block Claude)
if [ -z "$CLAUDE_PYTHON" ]; then
    echo "[run-python] WARNING: No Python 3.8+ found, skipping ${SCRIPT}" >&2
    exit 0
fi

# 4. Execute
exec "$CLAUDE_PYTHON" "$SCRIPT" "$@"
