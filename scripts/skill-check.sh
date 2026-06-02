#!/bin/bash
# skill-check.sh — SessionStart hook
# Scans installed skills for version drift and reports a summary.
# Runs in <2s by checking file modification dates, not content.

SKILLS_DIR="$HOME/.claude/skills"
[ -d "$SKILLS_DIR" ] || exit 0

# Count skills
TOTAL=$(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l)

# Find skills not updated in 90+ days (likely stale)
STALE_DAYS=90
STALE_LIST=""
STALE_COUNT=0

while IFS= read -r skill_file; do
    skill_name=$(basename "$(dirname "$skill_file")")

    # Check file age (cross-platform: stat works differently on macOS vs Linux)
    if command -v stat &>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            mod_epoch=$(stat -f %m "$skill_file" 2>/dev/null)
        else
            mod_epoch=$(stat -c %Y "$skill_file" 2>/dev/null)
        fi

        if [ -n "$mod_epoch" ]; then
            now_epoch=$(date +%s)
            age_days=$(( (now_epoch - mod_epoch) / 86400 ))
            if [ "$age_days" -ge "$STALE_DAYS" ]; then
                STALE_LIST="${STALE_LIST}  - ${skill_name} (${age_days}d ago)\n"
                STALE_COUNT=$((STALE_COUNT + 1))
            fi
        fi
    fi
done < <(find "$SKILLS_DIR" -maxdepth 2 -name "SKILL.md" 2>/dev/null)

# Output summary as system message
if [ "$STALE_COUNT" -gt 0 ]; then
    MSG="[skill-check] ${TOTAL} skills installed, ${STALE_COUNT} not updated in ${STALE_DAYS}+ days. Consider auditing stale skills."
    printf '{"type":"system","content":"%s"}\n' "$MSG"
fi

exit 0
