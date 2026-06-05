#!/bin/bash
# claudeception-activator.sh
# UserPromptSubmit hook — two detection layers:
#   1. Academic/planning tasks  → mandatory skill invocation gate
#   2. Debugging/reflection     → claudeception extraction reminder

INPUT=$(cat 2>/dev/null || true)

# Auto-detect Python (python3 on Unix, python on Windows)
PY=""
for cmd in python3 python py; do
    command -v "$cmd" &>/dev/null && PY="$cmd" && break
done
[ -z "$PY" ] && exit 0

PROMPT=$(echo "$INPUT" | "$PY" -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('prompt', ''))
except Exception:
    pass
" 2>/dev/null || true)

# Skip system-injected prompts. In this harness UserPromptSubmit ALSO fires for
# task-notifications (background task / workflow / agent completion); their prompt
# field is the FULL notification text — including workflow <result> JSON that often
# contains academic words — which is NOT a genuine user request. Gating those is a
# false positive, so bail out before the keyword checks. (Verified 2026-06-05 via a
# stdin trace: prompt = "<task-notification>...</task-notification>".)
case "$PROMPT" in
    *"<task-notification>"*) exit 0 ;;
esac

# Layer 1: Academic task detection (narrow — low false-positive risk)
# Only fires on unambiguous academic indicators; avoids generic words like plan/build/implement
# NOTE (2026-06-03): removed bare course codes (32011 etc.) from this regex — they
# matched the project PATH (which contains "32011"), causing false academic skill-gate
# fires on non-academic tasks. A course code now signals academic work only alongside a
# real task word (assignment/作业/exam/...), per CLAUDE.md Learned Rules.
if echo "$PROMPT" | grep -qiE \
    "(assignment|rubric|marking|lab report|实验报告|实验$|作业|整理成|exam|考试|期末|期中|quiz)"; then
    printf '{"type":"system","content":"[skill-gate] Academic task detected. MANDATORY FIRST ACTION: invoke brainstorming (vague spec) OR EnterPlanMode (clear spec/rubric) — before any text response or file creation. See CLAUDE.md Academic routing."}\n'
fi

# Layer 2: Debugging / reflection detection
# Fires after resolving — reminds to extract reusable patterns via claudeception
if echo "$PROMPT" | grep -qiE \
    "(debug|traceback|exception|stack trace|why is|broken|not working|reflect on|what did|reusable|learn from|extract|pattern|mistake|root cause)"; then
    printf '{"type":"system","content":"[claudeception] Non-trivial debugging or reflection detected. After resolving, consider invoking the claudeception skill to extract and save reusable patterns."}\n'
fi

exit 0
