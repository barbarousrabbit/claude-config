#!/bin/bash
# update-skills.sh -- keep third-party skills in ~/.claude/skills current with upstream.
#
# The manifest scripts/skill-sources.tsv says, per skill: upstream repo, path inside
# it, the commit the local copy was verified against, and a policy. This script
# fetches each upstream (blobless clone cached under .skill-update/repos/, so a weekly
# check is a `git fetch` plus tree walks -- no blobs), compares three tree
# fingerprints (upstream@pinned, upstream@HEAD, local) and:
#
#   policy track   upstream changed -> apply. A file you never touched is replaced by
#                  the new one; a file you edited gets `git merge-file` (3-way:
#                  upstream@pinned -> upstream@HEAD applied onto your copy). Any
#                  conflict aborts THAT skill (nothing written) and reports it as
#                  review. Each applied skill = one commit in ~/.claude
#                  ("chore(skills): update <name> <old>..<new>") so `git revert` undoes
#                  it. PROVENANCE.md in the skill dir and the manifest pin are updated.
#   policy review  never write; report that an update exists and which files differ.
#   policy pin     never write, never nag.
#   pinned = -     local copy matches no upstream commit -> treated as review.
#   mode clone     whole-repo git clones: report behind/ahead; --apply fast-forwards
#                  and install-third-party-skills.sh installs missing ones.
#
# Usage:
#   bash update-skills.sh --check [--skill NAME]   fetch + report, write nothing
#   bash update-skills.sh --apply [--skill NAME]   check, then apply track updates
#   bash update-skills.sh --apply --dry-run        show what --apply would write
#   bash update-skills.sh --auto [--force]         SessionStart entry: if the last
#                  successful check is >= SKILL_UPDATE_INTERVAL_DAYS (7) old, run
#                  --apply detached in the background; always print one summary line
#   bash update-skills.sh --report                 print the last full report
#
# State lives in ~/.claude/.skill-update/ (git-ignored): last-check, summary.txt,
# report.txt, run.log, lock, repos/. Nothing under skills/ is touched by --check.
# Exit: 0 normally; 1 if a repo was unreachable or an apply/commit failed
# (the hook tolerates 1). Never `set -e`: one bad upstream must not stop the rest.

set -u
export GIT_TERMINAL_PROMPT=0 LC_ALL=C

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
MANIFEST="${SKILL_SOURCES:-$CLAUDE_DIR/scripts/skill-sources.tsv}"
STATE="${SKILL_UPDATE_STATE:-$CLAUDE_DIR/.skill-update}"
REPOS="$STATE/repos"
INTERVAL_DAYS="${SKILL_UPDATE_INTERVAL_DAYS:-7}"
NET_TIMEOUT="${SKILL_UPDATE_NET_TIMEOUT:-120}"
MIRROR="$CLAUDE_DIR/scripts/mirror-skills-to-codex.sh"
INSTALLER="$CLAUDE_DIR/scripts/install-third-party-skills.sh"
IGNORE_RE='(^|[ /])(PROVENANCE.md|__pycache__/.*|.*.pyc)$'   # matches bare relpaths and "sha relpath" lines

MODE=""; ONLY=""; DRY=0; FORCE=0; FROM_AUTO=0
while [ $# -gt 0 ]; do
    case "$1" in
        --check|--apply|--auto|--report) MODE="${1#--}" ;;
        --skill) shift; ONLY="${1:-}" ;;
        --dry-run) DRY=1 ;;
        --force) FORCE=1 ;;
        --from-auto) FROM_AUTO=1; MODE="apply" ;;
        -h|--help) sed -n '2,38p' "$0"; exit 0 ;;
        *) echo "update-skills: unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done
[ -n "$MODE" ] || { echo "update-skills: need --check | --apply | --auto | --report" >&2; exit 2; }

mkdir -p "$STATE" "$REPOS"
TMO=""; command -v timeout >/dev/null 2>&1 && TMO="timeout $NET_TIMEOUT"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/skill-update.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- report mode
if [ "$MODE" = "report" ]; then
    if [ -f "$STATE/report.txt" ]; then cat "$STATE/report.txt"; else echo "update-skills: no report yet -- run --check"; fi
    exit 0
fi

# ------------------------------------------------------------------ auto mode
if [ "$MODE" = "auto" ]; then
    now=$(date +%s); last=0; [ -f "$STATE/last-check" ] && last=$(cat "$STATE/last-check" 2>/dev/null || echo 0)
    age_days=$(( (now - ${last:-0}) / 86400 ))
    summary=""; [ -f "$STATE/summary.txt" ] && summary="$(cat "$STATE/summary.txt")"
    due=0; [ "$FORCE" -eq 1 ] && due=1; [ "$age_days" -ge "$INTERVAL_DAYS" ] && due=1
    if [ -f "$STATE/lock" ]; then
        lock_age=$(( now - $(stat -c %Y "$STATE/lock" 2>/dev/null || echo 0) ))
        if [ "$lock_age" -lt 7200 ]; then due=0; summary="${summary:+$summary }(a refresh is still running)"; else rm -f "$STATE/lock"; fi
    fi
    if [ "${last:-0}" -gt 0 ]; then last_str="last check $age_days d ago"; else last_str="never checked"; fi
    if [ "$due" -eq 1 ]; then
        touch "$STATE/lock"
        # Detach fully: no inherited stdio, so the hook returns at once and the child
        # outlives it. Output goes to run.log; the result lands in summary.txt for the
        # next session start.
        nohup bash "$0" --from-auto > "$STATE/run.log" 2>&1 < /dev/null &
        disown 2>/dev/null || true
        echo "[skill-update] upstream check started in background ($last_str); results at next session start${summary:+ -- last: $summary}"
    else
        [ -n "$summary" ] && echo "[skill-update] $summary (next check in $(( INTERVAL_DAYS - age_days )) d)"
    fi
    exit 0
fi

# ------------------------------------------------------- shared helpers
say()  { echo "$*"; }
note() { echo "$*" >> "$WORK/report"; }

# sorted "blob-sha relpath" lines for a local dir or file -> $1 (out file)
fp_local() { # $1 out, $2 local path (dir or file)
    : > "$1"
    # --no-filters: hash the bytes on disk, so a CRLF file counts as an edit exactly
    # like it would in the byte-level merge below
    if [ -f "$2" ]; then printf '%s %s\n' "$(git hash-object --no-filters "$2")" "$(basename "$2")" > "$1"; return; fi
    [ -d "$2" ] || return
    (cd "$2" && find . -type f -print0 | sort -z | while IFS= read -r -d '' f; do
        rel="${f#./}"; case "$rel" in .git/*) continue;; esac
        printf '%s %s\n' "$(git hash-object --no-filters "$f")" "$rel"; done) | grep -Ev "$IGNORE_RE" | sort > "$1"
}
# sorted "blob-sha relpath" lines for upstream $3 at commit $4 in repo $2 -> $1
fp_up() { # $1 out, $2 repo dir, $3 path, $4 commit
    local pre; if [ "$3" = "." ]; then pre=""; else pre="$3/"; fi
    git -C "$2" ls-tree -r -z "$4" -- "$3" 2>/dev/null | while IFS= read -r -d '' e; do
        meta=${e%%$'\t'*}; p=${e#*$'\t'}; sha=${meta##* }; typ=${meta% *}; typ=${typ##* }
        [ "$typ" = "blob" ] || continue
        if [ -n "$pre" ] && [ "${p#$pre}" = "$p" ]; then p=$(basename "$p"); else p=${p#$pre}; fi
        printf '%s %s\n' "$sha" "$p"; done | grep -Ev "$IGNORE_RE" | sort > "$1"
}
repo_dir() { # short, unique, Windows-safe: <repo basename>-<sha1(url) prefix>
    local base h; base=$(basename "${1%/}"); base="${base%.git}"; base=$(printf '%s' "$base" | tr -c 'A-Za-z0-9._-' '_' | cut -c1-40)
    h=$(printf '%s' "$1" | sha1sum | cut -c1-10); echo "$REPOS/${base:-repo}-$h"; }
head_of() { git -C "$1" rev-parse --verify --quiet refs/remotes/origin/HEAD 2>/dev/null || git -C "$1" rev-parse --verify --quiet FETCH_HEAD 2>/dev/null; }

declare -A REPO_OK=()
ensure_repo() { # $1 url -> sets RD; returns 0 if usable
    RD=$(repo_dir "$1")
    if [ -n "${REPO_OK[$1]:-}" ]; then [ "${REPO_OK[$1]}" = 1 ]; return; fi
    if [ -d "$RD/.git" ]; then
        if $TMO git -C "$RD" fetch --quiet origin 2>>"$WORK/neterr" </dev/null; then
            git -C "$RD" rev-parse --verify --quiet refs/remotes/origin/HEAD >/dev/null 2>&1 || git -C "$RD" remote set-head origin -a >/dev/null 2>&1 || true
            REPO_OK[$1]=1
        else REPO_OK[$1]=0; fi
    else
        rm -rf "$RD"
        if $TMO git clone --filter=blob:none --no-checkout --quiet "$1" "$RD" 2>>"$WORK/neterr" </dev/null; then git -C "$RD" config core.autocrlf false; git -C "$RD" config core.eol lf; REPO_OK[$1]=1; else REPO_OK[$1]=0; rm -rf "$RD"; fi
    fi
    [ "${REPO_OK[$1]}" = 1 ]
}
# extract upstream $3 at commit $4 from repo $2 into dir $1 (path prefix stripped)
extract() { # $1 dest dir, $2 repo dir, $3 path, $4 commit
    mkdir -p "$1"
    # -c core.autocrlf=false: git archive honours autocrlf and on this machine (autocrlf=true)
    # emitted CRLF for every LF blob, so every file looked locally edited (sandbox, 2026-08-18)
    if [ "$3" = "." ]; then git -c core.autocrlf=false -c core.eol=lf -C "$2" archive --format=tar "$4" | tar -x -C "$1"; return $?; fi
    local typ; typ=$(git -C "$2" cat-file -t "$4:$3" 2>/dev/null)
    if [ "$typ" = "blob" ]; then git -C "$2" show "$4:$3" > "$1/$(basename "$3")"; return $?; fi
    git -c core.autocrlf=false -c core.eol=lf -C "$2" archive --format=tar "$4" -- "$3" | tar -x -C "$1" --strip-components=$(( $(printf '%s' "$3" | tr -cd '/' | wc -c) + 1 ))
}
list_files() { (cd "$1" 2>/dev/null && find . -type f -print0 | sort -z | while IFS= read -r -d '' f; do rel="${f#./}"; case "$rel" in .git/*) continue;; esac; echo "$rel"; done) | grep -Ev "$IGNORE_RE"; }
same_file() { cmp -s "$1" "$2"; }

set_pin() { # $1 skill, $2 new commit -> rewrite the manifest row
    awk -v s="$1" -v c="$2" 'BEGIN{FS=OFS="\t"} !/^#/ && $1==s && $2=="vendor" {$5=c} {print}' "$MANIFEST" > "$WORK/manifest.new" && cat "$WORK/manifest.new" > "$MANIFEST"
}
write_provenance() { # $1 dir, $2 skill, $3 repo, $4 path, $5 commit, $6 date
    cat > "$1/PROVENANCE.md" <<EOF
# Provenance -- $2

**Vendored from upstream by \`~/.claude/scripts/update-skills.sh\`; do not hand-edit
files you want to survive an update without checking \`scripts/skill-sources.tsv\`.**
Local edits are kept (3-way merged) while the row's policy is \`track\`; a conflict
turns that skill into \`review\` until a human resolves it.

| | |
|---|---|
| Upstream | $3 |
| Source path | \`$4\` |
| Pinned commit | \`$5\` ($6) |
| Last updated | $(date +%Y-%m-%d) |

Row in the manifest: \`$2\` -- edit the policy there, not this file.
EOF
}
git_commit_skill() { # $1 skill, $2 message; commits ONLY skills/<skill> + the manifest; retries on index.lock
    # `git commit -- <paths>` is a partial commit: anything the user has staged elsewhere
    # stays staged and out of this commit (an unattended background run must never sweep
    # unrelated work into "chore(skills)"). `add -A` first so upstream-added/-deleted files
    # under the skill are part of the pathspec commit.
    local i
    for i in 1 2 3 4 5; do
        if [ ! -f "$CLAUDE_DIR/.git/index.lock" ] && git -C "$CLAUDE_DIR" add -A -- "skills/$1" "scripts/skill-sources.tsv" 2>/dev/null; then
            local stat; stat=$(git -C "$CLAUDE_DIR" diff --cached --stat -- "skills/$1" | tail -1)
            if git -C "$CLAUDE_DIR" commit --quiet -m "$2" -m "$stat" -m "Applied by scripts/update-skills.sh from scripts/skill-sources.tsv." -- "skills/$1" "scripts/skill-sources.tsv" 2>/dev/null; then return 0; fi
        fi
        sleep 2
    done
    return 1
}

# ------------------------------------------------------------ main loop
: > "$WORK/report"; : > "$WORK/neterr"
n_current=0 n_applied=0 n_avail=0 n_review=0 n_unpinned=0 n_pin=0 n_unreach=0 n_conflict=0 n_failed=0 n_clone_missing=0
applied_names="" avail_names="" review_names="" conflict_names="" unpinned_names="" unreach_names="" missing_names=""
today=$(date +%Y-%m-%d)

while IFS=$'\t' read -r skill mode repo path pinned policy note_ || [ -n "$skill" ]; do
    skill="${skill%%$'\r'}"; case "$skill" in ''|\#*) continue ;; esac
    [ -n "$ONLY" ] && [ "$ONLY" != "$skill" ] && continue
    mode="${mode%%$'\r'}"; repo="${repo%%$'\r'}"; path="${path%%$'\r'}"; pinned="${pinned%%$'\r'}"; policy="${policy%%$'\r'}"
    local_path="$SKILLS_DIR/$skill"

    if [ "$mode" = "clone" ]; then
        if [ ! -d "$local_path/.git" ]; then
            n_clone_missing=$((n_clone_missing+1)); missing_names="$missing_names $skill"; note "$skill: clone not installed (install-third-party-skills.sh installs it)"; continue
        fi
        rhead=$($TMO git -C "$local_path" ls-remote --quiet origin HEAD 2>>"$WORK/neterr" </dev/null | awk 'NR==1{print $1}')
        lhead=$(git -C "$local_path" rev-parse HEAD 2>/dev/null)
        if [ -z "$rhead" ]; then n_unreach=$((n_unreach+1)); unreach_names="$unreach_names $skill"; note "$skill: unreachable ($repo)"; continue; fi
        if [ "$rhead" = "$lhead" ]; then n_current=$((n_current+1)); note "$skill: current (clone @ ${lhead:0:7})"; continue; fi
        if [ -n "$(git -C "$local_path" status --porcelain 2>/dev/null)" ]; then n_review=$((n_review+1)); review_names="$review_names $skill"; note "$skill: upstream moved to ${rhead:0:7} but the clone has local changes -- review"; continue; fi
        if [ "$MODE" = "apply" ] && [ "$DRY" -eq 0 ] && [ "$policy" = "track" ]; then
            if $TMO git -C "$local_path" pull --ff-only --quiet 2>>"$WORK/neterr" </dev/null; then n_applied=$((n_applied+1)); applied_names="$applied_names $skill"; note "$skill: clone fast-forwarded ${lhead:0:7}..${rhead:0:7}"; else n_failed=$((n_failed+1)); note "$skill: fast-forward failed"; fi
        else n_avail=$((n_avail+1)); avail_names="$avail_names $skill"; note "$skill: clone behind upstream ${lhead:0:7}..${rhead:0:7} (--apply fast-forwards)"; fi
        continue
    fi

    # ---- vendor rows
    [ "$policy" = "pin" ] && { n_pin=$((n_pin+1)); continue; }
    if [ ! -e "$local_path" ]; then n_failed=$((n_failed+1)); note "$skill: MISSING locally ($local_path)"; continue; fi
    if ! ensure_repo "$repo"; then n_unreach=$((n_unreach+1)); unreach_names="$unreach_names $skill"; note "$skill: unreachable ($repo)"; continue; fi
    head=$(head_of "$RD"); if [ -z "$head" ]; then n_unreach=$((n_unreach+1)); unreach_names="$unreach_names $skill"; note "$skill: cannot resolve upstream HEAD"; continue; fi
    if ! git -C "$RD" cat-file -e "$head:$path" 2>/dev/null; then n_failed=$((n_failed+1)); note "$skill: path '$path' no longer exists upstream @ ${head:0:7} -- fix the manifest"; continue; fi

    # local target: the dir, or the single vendored file
    if [ "$(git -C "$RD" cat-file -t "$head:$path" 2>/dev/null)" = "blob" ]; then local_target="$local_path/$(basename "$path")"; single=1; else local_target="$local_path"; single=0; fi
    fp_local "$WORK/l" "$local_target"; fp_up "$WORK/h" "$RD" "$path" "$head"

    if [ "$pinned" = "-" ]; then
        n_unpinned=$((n_unpinned+1)); unpinned_names="$unpinned_names $skill"
        d=$(comm -3 "$WORK/l" "$WORK/h" | wc -l)
        note "$skill: unpinned (no upstream commit matches the local copy); $d file(s) differ from upstream @ ${head:0:7} -- pin it or keep policy review"; continue
    fi
    if ! git -C "$RD" cat-file -e "$pinned" 2>/dev/null; then n_failed=$((n_failed+1)); note "$skill: pinned commit $pinned not found upstream -- fix the manifest"; continue; fi
    fp_up "$WORK/p" "$RD" "$path" "$pinned"
    if cmp -s "$WORK/p" "$WORK/h"; then
        n_current=$((n_current+1))
        loc=$(comm -3 "$WORK/l" "$WORK/p" | awk '{print $2}' | sort -u | tr '\n' ' ')
        note "$skill: current @ ${pinned:0:7}${loc:+ (local edits: $loc)}"; continue
    fi
    changed=$(comm -3 "$WORK/p" "$WORK/h" | awk '{print $2}' | sort -u | tr '\n' ' ')
    if [ "$policy" != "track" ] || [ "$MODE" = "check" ]; then
        if [ "$policy" = "track" ]; then n_avail=$((n_avail+1)); avail_names="$avail_names $skill"; else n_review=$((n_review+1)); review_names="$review_names $skill"; fi
        note "$skill: update available ${pinned:0:7}..${head:0:7} ($(git -C "$RD" log -1 --format=%ad --date=short "$head")) [policy=$policy] files: $changed"; continue
    fi

    # ---- apply (track): 3-way merge into a scratch copy, then swap in
    O="$WORK/$skill.old"; N="$WORK/$skill.new"; S="$WORK/$skill.stage"; rm -rf "$O" "$N" "$S"
    if ! extract "$O" "$RD" "$path" "$pinned" || ! extract "$N" "$RD" "$path" "$head"; then n_failed=$((n_failed+1)); note "$skill: could not extract upstream trees"; continue; fi
    if [ "$single" -eq 1 ]; then mkdir -p "$S"; cp "$local_target" "$S/"; else cp -R "$local_target" "$S"; fi
    conflict=0; merged=""; replaced=0; added=0; deleted=0
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        lf="$S/$f"; of="$O/$f"; nf="$N/$f"
        L=0; Oe=0; Ne=0; [ -f "$lf" ] && L=1; [ -f "$of" ] && Oe=1; [ -f "$nf" ] && Ne=1
        # upstream did not change this file -> local wins, whatever it is
        if [ $Oe -eq 1 ] && [ $Ne -eq 1 ] && same_file "$of" "$nf"; then continue; fi
        if [ $Oe -eq 0 ] && [ $Ne -eq 0 ]; then continue; fi
        if [ $L -eq 0 ]; then
            if [ $Oe -eq 0 ] && [ $Ne -eq 1 ]; then mkdir -p "$(dirname "$lf")"; cp "$nf" "$lf"; added=$((added+1)); fi
            # (Oe=1, L=0): dropped locally on purpose -> stay dropped
            continue
        fi
        if [ $Ne -eq 0 ]; then                       # deleted upstream
            if [ $Oe -eq 1 ] && same_file "$lf" "$of"; then rm -f "$lf"; deleted=$((deleted+1)); fi
            continue                                  # locally edited -> keep
        fi
        if [ $Oe -eq 1 ] && same_file "$lf" "$of"; then cp "$nf" "$lf"; replaced=$((replaced+1)); continue; fi
        if same_file "$lf" "$nf"; then continue; fi
        base="$of"; [ $Oe -eq 0 ] && base=/dev/null
        if git merge-file -p "$lf" "$base" "$nf" > "$WORK/merged" 2>/dev/null; then cp "$WORK/merged" "$lf"; merged="$merged $f"; else conflict=1; note "$skill: CONFLICT in $f"; fi
    done < <( { list_files "$O"; list_files "$N"; list_files "$S"; } | sort -u )
    if [ "$conflict" -eq 1 ]; then n_conflict=$((n_conflict+1)); conflict_names="$conflict_names $skill"; note "$skill: update ${pinned:0:7}..${head:0:7} NOT applied (merge conflict) -- review"; continue; fi
    if [ "$DRY" -eq 1 ]; then n_avail=$((n_avail+1)); avail_names="$avail_names $skill"; note "$skill: would apply ${pinned:0:7}..${head:0:7} (replace $replaced, add $added, delete $deleted, merge${merged:-: none})"; continue; fi
    # swap in
    if [ "$single" -eq 1 ]; then cp "$S/$(basename "$path")" "$local_target"; else
        find "$local_path" -mindepth 1 -maxdepth 1 ! -name PROVENANCE.md -exec rm -rf {} +; cp -R "$S"/. "$local_path"/; fi
    write_provenance "$local_path" "$skill" "$repo" "$path" "$head" "$(git -C "$RD" log -1 --format=%ad --date=short "$head")"
    set_pin "$skill" "$head"
    if git_commit_skill "$skill" "chore(skills): update $skill ${pinned:0:7}..${head:0:7} from ${repo#https://github.com/}"; then
        n_applied=$((n_applied+1)); applied_names="$applied_names $skill"
        note "$skill: applied ${pinned:0:7}..${head:0:7} (replace $replaced, add $added, delete $deleted, merged${merged:-: none}) -- committed"
    else
        n_applied=$((n_applied+1)); applied_names="$applied_names $skill"; n_failed=$((n_failed+1))
        note "$skill: applied ${pinned:0:7}..${head:0:7} but git commit failed -- changes left in the working tree for sync-push"
    fi
done < "$MANIFEST"

# ------------------------------------------------------------- wrap up
if [ "$MODE" = "apply" ] && [ "$DRY" -eq 0 ] && [ "$n_applied" -gt 0 ] && [ -f "$MIRROR" ]; then bash "$MIRROR" >> "$WORK/report" 2>&1 || true; fi
if [ "$MODE" = "apply" ] && [ "$DRY" -eq 0 ] && [ "$n_clone_missing" -gt 0 ] && [ -f "$INSTALLER" ]; then bash "$INSTALLER" >> "$WORK/report" 2>&1 || true; fi

label="checked"; [ "$MODE" = "apply" ] && [ "$DRY" -eq 0 ] && label="applied"
summary="$today: $n_current current, $n_applied $label${applied_names:+ (${applied_names# })}, $n_avail available${avail_names:+ (${avail_names# })}, $n_review need review${review_names:+ (${review_names# })}, $n_conflict conflict${conflict_names:+ (${conflict_names# })}, $n_unpinned unpinned, $n_pin pinned, $n_unreach unreachable${unreach_names:+ (${unreach_names# })}, $n_clone_missing clone missing${missing_names:+ (${missing_names# })}, $n_failed failed"
{ echo "# skill-update report -- $(date '+%Y-%m-%d %H:%M') -- mode=$MODE${DRY:+ dry-run=$DRY}${ONLY:+ skill=$ONLY}"; echo "# $summary"; echo; cat "$WORK/report"; if [ -s "$WORK/neterr" ]; then echo; echo "# network errors:"; sed 's/^/#   /' "$WORK/neterr"; fi; } > "$STATE/report.txt"
if [ -z "$ONLY" ]; then echo "$summary" > "$STATE/summary.txt"; fi
# advance the clock only when every upstream answered, so an offline run retries next session
if [ -z "$ONLY" ] && [ "$n_unreach" -eq 0 ]; then date +%s > "$STATE/last-check"; fi
rm -f "$STATE/lock" 2>/dev/null
[ "$FROM_AUTO" -eq 1 ] || { echo "[skill-update] $summary"; echo "[skill-update] details: $STATE/report.txt"; }
[ "$n_unreach" -eq 0 ] && [ "$n_failed" -eq 0 ]
