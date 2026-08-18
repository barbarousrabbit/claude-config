#!/bin/bash
# =============================================================
# install-third-party-skills.sh — Clone/refresh per-device skill repos
# Reads the mode=clone rows of scripts/skill-sources.tsv
# (skill<TAB>clone<TAB>url<TAB>.<TAB>-<TAB>policy<TAB>note); the whole repo is cloned
# to skills/<skill>/. Vendored skills (mode=vendor) are handled by update-skills.sh.
# Called by bootstrap.sh and by update-skills.sh --apply when a clone is missing;
# safe to re-run manually at any time. (Read scripts/third-party-skills.tsv until
# 2026-08-18, when that manifest was folded into skill-sources.tsv.)
# =============================================================
# Deliberately NOT `set -e`: one unreachable repo must not abort the rest,
# and this runs inside bootstrap where a hard exit would skip later steps.

# Overridable so a fresh clone can be verified without touching the live
# ~/.claude (that is how this script was tested on 2026-07-27).
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
MANIFEST="${SKILL_SOURCES:-$CLAUDE_DIR/scripts/skill-sources.tsv}"

# Never let a credential prompt hang this (bootstrap may run unattended).
export GIT_TERMINAL_PROMPT=0

if [ ! -f "$MANIFEST" ]; then
    echo "[!] Manifest not found: $MANIFEST"
    exit 0
fi

TIMEOUT_CMD=""
command -v timeout &>/dev/null && TIMEOUT_CMD="timeout 60"

installed=0; refreshed=0; failed=0

# IFS=$'\t' splits on tab only, so paths with spaces survive.
# The `[ -n "$skill" ]` guard handles a final line without a trailing newline.
# Columns: skill, mode, repo, path, pinned, policy, note -- only mode=clone rows matter here.
while IFS=$'\t' read -r skill mode url _path _pinned _policy _note || [ -n "$skill" ]; do
    # Strip comments, blank lines, and any stray CR from CRLF checkouts.
    skill="${skill%%$'\r'}"; mode="${mode%%$'\r'}"; url="${url%%$'\r'}"
    case "$skill" in ''|\#*) continue ;; esac
    [ "$mode" = "clone" ] || continue          # vendored rows belong to update-skills.sh
    [ -n "$url" ] || { echo "[!] No URL for '$skill', skipping"; continue; }

    dest="skills/$skill"
    target="$CLAUDE_DIR/$dest"

    if [ -d "$target/.git" ]; then
        if $TIMEOUT_CMD git -C "$target" pull --ff-only --quiet 2>/dev/null; then
            echo "[OK] refreshed  $dest"
            refreshed=$((refreshed+1))
        else
            # Local edits or diverged history — leave it alone rather than
            # clobbering work that only exists on this device.
            echo "[!]  $dest exists but could not fast-forward (left untouched)"
        fi
    elif [ -d "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
        echo "[!]  $dest exists, not a git repo — left untouched"
    else
        rmdir "$target" 2>/dev/null
        if $TIMEOUT_CMD git clone --depth 1 --quiet "$url" "$target" 2>/dev/null; then
            echo "[OK] installed  $dest"
            installed=$((installed+1))
        else
            echo "[!]  FAILED to clone $dest from $url"
            failed=$((failed+1))
        fi
    fi
done < "$MANIFEST"

echo "    third-party skills: $installed installed, $refreshed refreshed, $failed failed"
[ "$failed" -eq 0 ]
