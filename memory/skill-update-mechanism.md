# Skill update mechanism: how third-party skills in ~/.claude/skills stay current

## What

`scripts/skill-sources.tsv` records, for every third-party skill, its upstream repo,
path inside the repo, the commit the local copy was verified against, and a policy
(`track` / `review` / `pin`). `scripts/update-skills.sh` fetches each upstream into a
blobless clone cache (`~/.claude/.skill-update/repos/`, git-ignored), compares
mode-agnostic tree fingerprints ("blob-sha relpath" lines) for upstream@pinned,
upstream@HEAD and local, and:

- `track`: applies upstream changes -- untouched files are replaced, locally edited
  files get `git merge-file` (3-way, pinned -> HEAD onto local); a conflict aborts that
  one skill (nothing written) and reports it as review. One commit per applied skill
  (`chore(skills): update <name> <old>..<new> from <repo>`), PROVENANCE.md regenerated
  in the skill dir, pin rewritten in the manifest, then `mirror-skills-to-codex.sh`.
- `review`: report only. `pin`: silent. `pinned = -`: local matches no upstream commit,
  treated as review until someone pins it.
- `mode=clone` rows (whole-repo clones, .gitignore'd) are installed by
  `install-third-party-skills.sh` (which now reads those rows) and fast-forwarded.

Cadence: `hook-session-start.sh` step 5 runs `update-skills.sh --auto` -- if the last
check is >= 7 days old (`SKILL_UPDATE_INTERVAL_DAYS`), it detaches `--from-auto`
(check+apply) with nohup and returns in ~250 ms; the hook prints one `[skill-update] …`
line from `.skill-update/summary.txt`. `--check` / `--apply [--dry-run] [--skill X]`
/ `--report` are the manual entry points. The clock advances only when every
upstream answered, so an offline run retries next session. Introduced 2026-08-18,
superseding `third-party-skills.tsv` (clone URLs only, bootstrap-time only).

## Why

- Before this, "is this skill current?" was unanswerable: only 1 of 114 skills had a
  recorded upstream; clone-mode skills refreshed only at bootstrap (gstack/humanizer
  were missing on this device for a week; apple-hig sat at a Feb commit).
- 3-way merge instead of "any local edit -> review": the 2026-07 audit rewrote the
  SKILL.md `description:` of most vendored skills to trigger-scenario style, so nearly
  every skill has a frontmatter-only local edit. Blind overwrite would lose it; blind
  review would make auto-apply pointless. `git merge-file` carries the local
  frontmatter over the new upstream body cleanly (verified in the sandbox: local
  description kept, upstream body changes taken).

## Gotchas learned (2026-08-18)

- **`git archive` honours `core.autocrlf`.** On this machine (global autocrlf=true) it
  emitted CRLF for every LF blob, so every extracted upstream file looked locally
  edited and every skill "conflicted". Fix: `git -c core.autocrlf=false -c core.eol=lf
  archive …` and `core.autocrlf=false` in each cached clone; local fingerprints use
  `git hash-object --no-filters` so verdicts match the byte-level merge.
- **Single-file skills cannot be pinned by "match ignoring SKILL.md"** -- that compares
  zero files and trivially matches the newest commit. Pin them by the SKILL.md *body*
  (front matter stripped) instead; multi-file skills pin on the other files and then
  check whether the body equals upstream at that commit ("frontmatter-only" vs "real
  content edit").
- **`git clone --filter=blob:none` from a local path silently ignores the filter** and
  needs `uploadpack.allowFilter=true` on the source; use `file://` in sandboxes.
- **`git ls-remote -h URL HEAD` says "no" for every repo** (`-h` = heads only, HEAD is
  not a head): that false negative briefly hid `duckdb/duckdb-skills`.
- Fingerprints must exclude `PROVENANCE.md`, `__pycache__/`, `*.pyc` (local artefacts).
  `~/.claude/skills/docx/unpacked_*` (1 MB, leaked 2026-07-27, tracked) is local-only
  junk that a merge keeps; it needs a human `git rm`.
- **`git commit -m …` without a pathspec commits the whole index.** The first real
  apply swept an unrelated staged deletion into "chore(skills): update grilling". Now
  `git_commit_skill` uses `git commit … -- skills/<name> scripts/skill-sources.tsv`
  (partial commit), verified in the sandbox: an unrelated staged file stays staged.
- **1024 skill files were CRLF in the working copy** (index LF, attr eol=lf) -- checkouts
  that predate the .gitattributes policy. `git checkout-index -f` does NOT rewrite an
  existing file; delete + `git checkout-index --` does, then `git add -u -- skills`
  clears the stat-only " M" (blob identical, nothing staged). 397 CRLF files remain
  outside skills/ (deliberately left; same recipe applies).
- Cache-dir names derive from `basename(url)-sha1(url)[0:10]`: a URL-escaped name hit
  Windows' path limit inside the sandbox.

## How to apply

```bash
bash ~/.claude/scripts/update-skills.sh --check            # what upstream has
bash ~/.claude/scripts/update-skills.sh --apply --dry-run  # what would be written
bash ~/.claude/scripts/update-skills.sh --apply            # do it (one commit per skill)
bash ~/.claude/scripts/update-skills.sh --report           # last full report
```
Adding a skill: vendor it, add a `track` row with the commit you copied from, run
`--check --skill <name>` -> must say "current". Never hand-copy an upstream update
over a vendored skill again -- that is exactly what breaks pinning.
Rows with `pinned = -` (frontend-design, last30days, ui-ux-pro-max, brainstorming,
dispatching-parallel-agents) are the open items for the provenance-archaeology task.
