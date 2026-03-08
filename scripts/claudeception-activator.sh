#!/bin/bash
# claudeception-activator.sh
# UserPromptSubmit hook — evaluates prompt for debugging/reflection patterns
# Outputs a system reminder if the prompt suggests non-trivial debugging work

INPUT=$(cat 2>/dev/null || true)
PROMPT=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('prompt', ''))
except Exception:
    pass
" 2>/dev/null || true)

# Trigger keywords: debugging, errors, architectural reflection, learning extraction
if echo "$PROMPT" | grep -qiE \
    "(debug|traceback|exception|stack trace|why is|broken|not working|reflect on|what did|reusable|learn from|extract|pattern|mistake|root cause)"; then
    # Inject a brief reminder as system context
    printf '{"type":"system","content":"[claudeception] Non-trivial debugging or reflection detected. After resolving, consider invoking the claudeception skill to extract and save reusable patterns."}\n'
fi

exit 0
