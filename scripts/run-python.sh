#!/bin/bash
# =============================================================
# run-python.sh — 跨设备 Python 启动器
# 用法: bash run-python.sh <script.py> [args...]
# 优先使用 local-env.sh 中探测到的 Python，否则自动回退
# =============================================================
SCRIPT="$1"
shift

ENV_FILE="$HOME/.claude/local-env.sh"

# 1. 优先从 local-env.sh 读取探测结果
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
fi

# 2. 如果没有，重新探测
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

# 3. 找不到就退出 0（不阻塞 Claude）
if [ -z "$CLAUDE_PYTHON" ]; then
    echo "[run-python] WARNING: No Python 3.8+ found, skipping ${SCRIPT}" >&2
    exit 0
fi

# 4. 执行
exec "$CLAUDE_PYTHON" "$SCRIPT" "$@"
