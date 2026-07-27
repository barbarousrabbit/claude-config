#!/bin/bash
# Auto-sync: pull latest Claude Code config at session start
# MUST NOT block — all operations have timeouts and fallbacks
CLAUDE_DIR="$HOME/.claude"

# Prevent git from prompting for credentials (would hang in hook context)
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=""
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=no"

# Only run if it's a git repo with a remote
if [ -d "$CLAUDE_DIR/.git" ] && git -C "$CLAUDE_DIR" remote get-url origin &>/dev/null; then
    # If a previous rebase was interrupted, abort it first
    if [ -d "$CLAUDE_DIR/.git/rebase-merge" ] || [ -d "$CLAUDE_DIR/.git/rebase-apply" ]; then
        git -C "$CLAUDE_DIR" rebase --abort 2>/dev/null
    fi

    # Abort if there are unmerged (conflicted) files — pull would fail anyway
    if git -C "$CLAUDE_DIR" ls-files --unmerged | grep -q .; then
        git -C "$CLAUDE_DIR" reset --hard HEAD 2>/dev/null
    fi

    # Stash any uncommitted changes (e.g. plugins cache)
    STASH_OUT=$(git -C "$CLAUDE_DIR" stash 2>/dev/null)

    # Pull latest with 15-second timeout (prevents hanging on slow network)
    # Fall back to no-timeout if `timeout` command unavailable
    TIMEOUT_CMD=""
    command -v timeout &>/dev/null && TIMEOUT_CMD="timeout 15"
    $TIMEOUT_CMD git -C "$CLAUDE_DIR" pull --rebase --quiet origin main 2>/dev/null \
      || $TIMEOUT_CMD git -C "$CLAUDE_DIR" pull --rebase --quiet 2>/dev/null \
      || true

    # If rebase failed mid-way, abort to keep repo clean
    if [ -d "$CLAUDE_DIR/.git/rebase-merge" ] || [ -d "$CLAUDE_DIR/.git/rebase-apply" ]; then
        git -C "$CLAUDE_DIR" rebase --abort 2>/dev/null
    fi

    # Re-apply stashed changes only if something was stashed
    if echo "$STASH_OUT" | grep -q "Saved working directory"; then
        if ! git -C "$CLAUDE_DIR" stash pop --quiet 2>/dev/null; then
            # A conflicted pop used to be swallowed by `|| true`. That left raw
            # <<<<<<< markers inside settings.json, so the whole config failed to
            # parse for the rest of the session and every permission rule silently
            # stopped applying. Instead: keep the freshly pulled version of each
            # conflicted file, and leave the stash intact so nothing is lost.
            CONFLICTED=$(git -C "$CLAUDE_DIR" diff --name-only --diff-filter=U 2>/dev/null)
            if [ -n "$CONFLICTED" ]; then
                printf '%s\n' "$CONFLICTED" | while IFS= read -r f; do
                    [ -n "$f" ] || continue
                    git -C "$CLAUDE_DIR" checkout --ours -- "$f" 2>/dev/null || true
                    git -C "$CLAUDE_DIR" reset -q HEAD -- "$f" 2>/dev/null || true
                done
                {
                    echo "[sync-pull] stash pop conflicted — kept the pulled version of:"
                    printf '%s\n' "$CONFLICTED" | sed 's/^/  /'
                    echo "[sync-pull] your local copy is preserved; recover it with: git -C ~/.claude stash list"
                } >&2
            fi
        fi
    fi

    # Refresh nested skill repos that carry their own .git (currently just
    # apple-hig-designer). They are gitignored rather than tracked, so their
    # clone URLs live in scripts/third-party-skills.tsv and are installed by
    # install-third-party-skills.sh; this loop only keeps existing ones current.
    #
    # This used to say "e.g. gstack, humanizer". Those were gitlinks with no
    # .gitmodules entry, which `git submodule update` cannot drive — they ended
    # up as empty directories with their .git gone and their origins lost, and
    # were removed 2026-07-27. The manifest exists so that cannot recur.
    #
    # --autostash tolerates line-ending churn; --rebase preserves any local
    # commits; abort cleanly on conflict so a session start never hangs or
    # leaves a repo mid-rebase.
    for sub in "$CLAUDE_DIR"/skills/*/.git; do
        [ -e "$sub" ] || continue
        subdir=$(dirname "$sub")
        git -C "$subdir" remote get-url origin &>/dev/null || continue
        $TIMEOUT_CMD git -C "$subdir" pull --rebase --autostash --quiet 2>/dev/null || true
        if [ -d "$subdir/.git/rebase-merge" ] || [ -d "$subdir/.git/rebase-apply" ]; then
            git -C "$subdir" rebase --abort 2>/dev/null || true
        fi
    done
fi
