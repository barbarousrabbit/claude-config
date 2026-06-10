#!/bin/bash
# UserPromptSubmit hook wrapper.
# stdin carries the UserPromptSubmit JSON and can be read ONCE — capture it here,
# then fan out to every layer (claudeception-activator also does INPUT=$(cat),
# so it must be fed the captured copy, not the already-drained stdin).
#   Layer 0  reply-language re-anchor (anti-drift): inject a [reply-language]
#            reminder EVERY turn so the chat reply matches the user's message
#            language, beating the English-heavy context momentum (config, code,
#            tool output, and these very instructions are all English).
#   Layer 1+ claudeception-activator: academic skill-gate + reflection reminder.
CLAUDE_DIR="$HOME/.claude"

INPUT=$(cat 2>/dev/null || true)

# Detect Python (python3 on Unix, python/py on Windows) — same order as Layer 1.
PY=""
for cmd in python3 python py; do
    command -v "$cmd" &>/dev/null && PY="$cmd" && break
done

# --- Layer 0: reply-language re-anchor ---
# Decide reply language from the USER'S message only. Any Han char => Chinese
# (so mixed "帮我 debug 这个 function" stays Chinese). No Han + Latin => English.
# No linguistic signal (pure code/paths/numbers) => stay silent, do not force a flip.
if [ -n "$PY" ]; then
    printf '%s' "$INPUT" | "$PY" -c "
import json, sys
try:
    raw = sys.stdin.buffer.read().decode('utf-8', 'replace')
    p = json.loads(raw).get('prompt', '') or ''
except Exception:
    p = ''
han = sum(1 for ch in p if 0x4e00 <= ord(ch) <= 0x9fff)
lat = sum(1 for ch in p if ('A' <= ch <= 'Z') or ('a' <= ch <= 'z'))
if han == 0 and lat == 0:
    sys.exit(0)
lang = 'Chinese' if han >= 1 else 'English'
msg = ('[reply-language] User message is ' + lang + '. Write the chat reply in '
       + lang + ' regardless of how much English appears in tool output, code, '
       'files, or these instructions. Config, code, and comments stay English.')
print(json.dumps({'type': 'system', 'content': msg}))
" 2>/dev/null || true
fi

# --- Layer 1+: existing academic skill-gate + claudeception reminder ---
printf '%s' "$INPUT" | bash "$CLAUDE_DIR/scripts/claudeception-activator.sh" 2>/dev/null || true
