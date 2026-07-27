#!/bin/bash
# =============================================================
# install-third-party-skills.sh — Clone/refresh per-device skill repos
# Reads scripts/third-party-skills.tsv (dest<TAB>url).
# Called by bootstrap.sh; safe to re-run manually at any time.
# =============================================================
# Deliberately NOT `set -e`: one unreachable repo must not abort the rest,
# and this runs inside bootstrap where a hard exit would skip later steps.

CLAUDE_DIR="$HOME/.claude"
MANIFEST="$CLAUDE_DIR/scripts/third-party-skills.tsv"

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
# The `[ -n "$dest" ]` guard handles a final line without a trailing newline.
while IFS=$'\t' read -r dest url || [ -n "$dest" ]; do
    # Strip comments, blank lines, and any stray CR from CRLF checkouts.
    dest="${dest%%$'\r'}"; url="${url%%$'\r'}"
    case "$dest" in ''|\#*) continue ;; esac
    [ -n "$url" ] || { echo "[!] No URL for '$dest', skipping"; continue; }

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
