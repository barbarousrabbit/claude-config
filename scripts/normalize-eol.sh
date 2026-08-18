#!/bin/bash
# normalize-eol.sh -- make working-copy line endings agree with .gitattributes, content untouched.
#
# WHY: .gitattributes pins every text file to LF (and *.ps1/*.bat/*.cmd to CRLF), but a file
# checked out BEFORE that policy keeps whatever endings it had -- git treats such a file as
# unmodified, so nothing ever rewrites it. On 2026-08-18 this device had 1024 CRLF files under
# skills/ and 397 elsewhere while every blob was LF. Byte-level tools (update-skills.sh
# fingerprints and its 3-way merges, diff, cmp) then see every line as changed: every vendored
# skill looked locally edited and every upstream update "conflicted". Any device that cloned
# before 2026-07-27 has the same drift, so this runs from the SessionStart hook and bootstrap.
#
# WHAT: for each tracked file where `git ls-files --eol` reports a working-copy ending that
# disagrees with the file's eol attribute AND `git diff --quiet -- <file>` confirms the content
# equals the index (i.e. the only difference is line endings), delete it and re-check it out
# from the index (identical bytes, endings per attributes), then `git add -u` those paths so
# the stat cache stops flagging them (nothing new is staged: the blob is identical). Files with
# real uncommitted changes are never touched.
#
# Usage: bash normalize-eol.sh [--dry-run] [--verbose]      exit 0 always
# Prints one line only when it did (or would do) something; silent when everything is right.
set -u
export LC_ALL=C
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
DRY=0; VERBOSE=0
for a in "$@"; do case "$a" in --dry-run|-n) DRY=1;; --verbose|-v) VERBOSE=1;; esac; done
cd "$CLAUDE_DIR" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

fix=(); skipped=0
while IFS= read -r -d '' entry; do
    meta="${entry%%$'\t'*}"; path="${entry#*$'\t'}"
    case "$meta" in *"eol=crlf"*) want=crlf;; *"eol=lf"*) want=lf;; *) continue;; esac
    case "$meta" in *" w/crlf "*|*" w/crlf"*) have=crlf;; *" w/lf "*|*" w/lf"*) have=lf;; *" w/mixed"*) have=mixed;; *) continue;; esac
    [ "$have" = "$want" ] && continue
    if git diff --quiet -- "$path" 2>/dev/null; then fix+=("$path"); else skipped=$((skipped+1)); [ "$VERBOSE" -eq 1 ] && echo "eol-normalize: skipped (locally modified): $path"; fi
done < <(git ls-files --eol -z 2>/dev/null)

n=${#fix[@]}
if [ "$n" -eq 0 ]; then [ "$skipped" -gt 0 ] && echo "eol-normalize: nothing rewritten; $skipped file(s) have wrong endings but real local changes -- commit them and re-run"; exit 0; fi
if [ "$DRY" -eq 1 ]; then echo "eol-normalize (dry-run): $n file(s) would be rewritten with the endings .gitattributes prescribes, $skipped skipped (locally modified)"; [ "$VERBOSE" -eq 1 ] && printf '  %s\n' "${fix[@]}"; exit 0; fi
# `git checkout-index -f` does NOT rewrite an existing file whose content matches, so delete first.
printf '%s\0' "${fix[@]}" | xargs -0 rm -f --
printf '%s\0' "${fix[@]}" | xargs -0 git checkout-index -- 2>/dev/null
printf '%s\0' "${fix[@]}" | xargs -0 git add -u -- 2>/dev/null
echo "eol-normalize: rewrote $n file(s) to the endings .gitattributes prescribes (content unchanged), $skipped skipped (locally modified)"
[ "$VERBOSE" -eq 1 ] && printf '  %s\n' "${fix[@]}"
exit 0
