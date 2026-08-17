#!/bin/bash
# mirror-skills-to-codex.sh -- one-way mirror of selected ~/.claude/skills into ~/.codex/skills
#
# Codex loads skills from ~/.codex/skills/ only and never reads ~/.claude/. The
# skills named in scripts/codex-mirror-skills.txt already ship in Codex format
# (agents/openai.yaml beside SKILL.md), so a byte-identical copy is all Codex needs.
#
# Contract (see the manifest header for the reasoning):
#   * ~/.claude/skills/<name>/ is the source of truth; edits flow source -> Codex only.
#   * A copy is (re)written only when its content differs from the source.
#   * Every copy gets a `.claude-mirror` marker. Only marker-bearing directories
#     are ever deleted, and only when their name is no longer in the manifest.
#     ~/.codex/skills/.system/ (Codex vendor skills) and unmarked directories
#     (installed by other tools, e.g. a repo's install-skills.ps1) are never touched.
#   * No ~/.codex/skills/ on this machine -> Codex is not installed -> exit 0, no-op.
#
# Usage:
#   bash ~/.claude/scripts/mirror-skills-to-codex.sh             # apply
#   bash ~/.claude/scripts/mirror-skills-to-codex.sh --dry-run   # report only, write nothing
#
# Exit status: 0 on success (including the no-Codex no-op); 1 if any manifest
# entry could not be mirrored (missing source, bad name). Called from
# hook-session-start.sh (after sync-pull) and bootstrap.sh; both tolerate 1.

set -u

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"
SOURCE_ROOT="$CLAUDE_DIR/skills"
TARGET_ROOT="$CODEX_DIR/skills"
MANIFEST="$CLAUDE_DIR/scripts/codex-mirror-skills.txt"
MARKER=".claude-mirror"

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
        *) echo "codex-mirror: unknown argument: $arg" >&2; exit 2 ;;
    esac
done

if [ ! -d "$TARGET_ROOT" ]; then
    echo "codex-mirror: $TARGET_ROOT not found -- Codex is not installed here, nothing to do"
    exit 0
fi
if [ ! -f "$MANIFEST" ]; then
    echo "codex-mirror: manifest missing: $MANIFEST" >&2
    exit 1
fi

# --- read the manifest: strip comments, blanks, surrounding whitespace, CR ---
wanted=()
while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    wanted+=("$line")
done < "$MANIFEST"

is_wanted() {
    local n
    for n in "${wanted[@]}"; do [ "$n" = "$1" ] && return 0; done
    return 1
}

installed=0 updated=0 current=0 pruned=0 failed=0

# --- install / refresh ---
for name in "${wanted[@]}"; do
    case "$name" in
        .*|*/*|*\\*|*..*)
            echo "codex-mirror: refusing unsafe skill name '$name'" >&2
            failed=$((failed + 1)); continue ;;
    esac
    src="$SOURCE_ROOT/$name"
    dst="$TARGET_ROOT/$name"
    if [ ! -f "$src/SKILL.md" ]; then
        echo "codex-mirror: source missing or has no SKILL.md: $src (Codex copy left untouched)" >&2
        failed=$((failed + 1)); continue
    fi

    if [ -d "$dst" ] && diff -rq -x "$MARKER" "$src" "$dst" >/dev/null 2>&1; then
        current=$((current + 1)); continue
    fi

    if [ -d "$dst" ]; then verb="updated"; else verb="installed"; fi
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "codex-mirror: would be $verb: $name -> $dst"
    else
        rm -rf "$dst" && cp -R "$src" "$dst" || {
            echo "codex-mirror: copy failed for $name" >&2
            failed=$((failed + 1)); continue
        }
        cat > "$dst/$MARKER" <<EOF
Mirrored from ~/.claude/skills/$name by ~/.claude/scripts/mirror-skills-to-codex.sh
ONE-WAY MIRROR -- do not edit this copy. Edit ~/.claude/skills/$name instead.
This directory is replaced whenever the source differs (Claude Code SessionStart
hook, bootstrap.sh, or a manual run) and deleted when '$name' leaves
~/.claude/scripts/codex-mirror-skills.txt.
EOF
        echo "codex-mirror: $verb: $name -> $dst"
    fi
    if [ "$verb" = "updated" ]; then updated=$((updated + 1)); else installed=$((installed + 1)); fi
done

# --- prune: only our own marker-bearing copies that left the manifest ---
for dir in "$TARGET_ROOT"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    [ -f "$dir/$MARKER" ] || continue          # not ours -> never touch
    is_wanted "$name" && continue
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "codex-mirror: would prune: $name (marker present, not in manifest)"
    else
        rm -rf "$dir" && echo "codex-mirror: pruned: $name (no longer in manifest)"
    fi
    pruned=$((pruned + 1))
done

label=""; [ "$DRY_RUN" -eq 1 ] && label=" (dry-run)"
echo "codex-mirror$label: $current current, $installed installed, $updated updated, $pruned pruned, $failed failed"
[ "$failed" -eq 0 ]
