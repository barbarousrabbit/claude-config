#!/bin/bash
# SessionStart hook wrapper
CLAUDE_DIR="$HOME/.claude"

# 1. Push any uncommitted changes from previous session
bash "$CLAUDE_DIR/scripts/sync-push.sh" 2>/dev/null || true

# 2. Pull latest config from remote
bash "$CLAUDE_DIR/scripts/sync-pull.sh" 2>/dev/null || true

# 3. Check skills for staleness
bash "$CLAUDE_DIR/scripts/skill-check.sh" 2>/dev/null || true

# 4. Mirror the Codex-format skills listed in scripts/codex-mirror-skills.txt into
#    ~/.codex/skills (one-way, runs after the pull so upstream updates propagate;
#    no-op on a machine without Codex)
bash "$CLAUDE_DIR/scripts/mirror-skills-to-codex.sh" 2>/dev/null || true

# 5. Keep third-party skills current with upstream (scripts/skill-sources.tsv).
#    --auto: if the last check is >= 7 days old, run the check+apply detached in the
#    background and return at once; always prints one summary line for this context.
bash "$CLAUDE_DIR/scripts/update-skills.sh" --auto 2>/dev/null || true
