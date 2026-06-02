#!/bin/bash
# Auto-sync push: commit & push ~/.claude config changes at session end.
# Pairs with sync-pull.sh (SessionStart). MUST NOT block or prompt — credential
# prompts are disabled, every network op is time-boxed, and the script always
# exits 0 so a failed push never holds up session shutdown.
CLAUDE_DIR="$HOME/.claude"

# Never let git prompt for credentials in a hook context (would hang forever)
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=""
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no"

# Only act on a real git repo that has an origin remote
git -C "$CLAUDE_DIR" rev-parse --is-inside-work-tree &>/dev/null || exit 0
git -C "$CLAUDE_DIR" remote get-url origin &>/dev/null || exit 0

TIMEOUT_CMD=""
command -v timeout &>/dev/null && TIMEOUT_CMD="timeout 30"

# Stage all tracked + new files (respects .gitignore, so runtime dirs like
# projects/, sessions/, plugins/cache/ are excluded automatically).
git -C "$CLAUDE_DIR" add -A 2>/dev/null

# Do NOT commit nested-repo (submodule) pointer moves. gstack/humanizer carry
# local-only commits (e.g. user-invocable edits) that are not on their upstreams;
# committing a gitlink SHA that origin can't resolve would break fresh clones.
# Their content is kept current by sync-pull.sh pulling each repo directly.
for sm in $(git -C "$CLAUDE_DIR" ls-files -s skills/ 2>/dev/null | awk '$1=="160000"{print $4}'); do
    git -C "$CLAUDE_DIR" reset -q HEAD "$sm" 2>/dev/null
done

# Nothing staged -> no empty commit, no push.
if git -C "$CLAUDE_DIR" diff --cached --quiet 2>/dev/null; then
    exit 0
fi

# Commit with a timestamp-free, host-tagged auto message (Date.now-free for
# reproducibility; git records the real timestamp itself).
HOST=$(hostname 2>/dev/null || echo unknown)
git -C "$CLAUDE_DIR" commit -q -m "chore: auto-sync ~/.claude config from ${HOST}" 2>/dev/null || exit 0

# Best-effort push, time-boxed. Prefer HEAD:main; fall back to default upstream.
$TIMEOUT_CMD git -C "$CLAUDE_DIR" push -q origin HEAD:main 2>/dev/null \
  || $TIMEOUT_CMD git -C "$CLAUDE_DIR" push -q 2>/dev/null \
  || true

exit 0
