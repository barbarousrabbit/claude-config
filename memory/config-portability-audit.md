---
name: config-portability-audit
description: Auditing a config repo for cross-device breakage requires a fresh clone — static scanning misses the worst defects
metadata:
  type: feedback
---

When auditing whether a synced config repo (`~/.claude`, dotfiles, any
clone-and-go setup) actually works on a new machine, a static scan of the
working tree is not sufficient. Clone it fresh into a SHORT path and run the
setup end-to-end. On 2026-07-27 the two most severe defects were invisible to
grep/`git ls-files` inspection and only surfaced from an actual clone.

**Why:** the live working tree hides exactly the class of bug that breaks new
devices, because on the origin machine the missing pieces are already present.

- **`.gitignore` only applies to UNTRACKED paths.** Six `apple-hig-designer`
  files were both ignored and tracked, so a clone materialized a stale, partial
  copy (no README, no screenshots). The installer then saw "directory exists"
  and skipped it, meaning a new device could never obtain the real skill. On the
  origin machine everything looked fine. Detect with:
  `git ls-files -i -c --exclude-standard` (should be empty).
- **Missing setup steps never fail locally.** `CLAUDE.md`'s New Device Setup had
  no `git clone` line at all — it assumed `~/.claude` already existed. Nobody on
  an existing machine would ever notice.
- **gitlinks without `.gitmodules` are unrecoverable.** `skills/gstack` and
  `skills/humanizer` were mode 160000 with no `.gitmodules`, empty on disk, and
  their `.git` gone — the origin URLs were lost. Detect with:
  `git ls-files -s | grep ^160000`. Any third-party repo that is gitignored
  needs a checked-in manifest of clone URLs, or it silently disappears.
  (Epilogue 2026-08-11: the desktop still had intact clones of both; origins
  recovered and re-registered in `third-party-skills.tsv` — gstack =
  github.com/garrytan/gstack, humanizer = github.com/blader/humanizer.
  2026-08-18: that manifest was folded into `scripts/skill-sources.tsv` as its
  `mode=clone` rows; see [[skill-update-mechanism]].)
- **Silent-abort sync means devices drift without any error.** `sync-pull.sh`
  deliberately aborts on rebase conflict so session start never blocks. Cost:
  a device with a local customization commit on a nested skill repo (e.g.
  `user-invocable: true` in SKILL.md frontmatter) re-conflicts every time
  upstream touches that frontmatter, and the abort is silent — the desktop
  fell 41 commits behind on gstack over ~4 weeks with zero visible errors.
  Fix pattern: manually `git pull --rebase`, resolve by taking upstream's
  frontmatter + re-adding the one customization line, keep the local commit
  on top (steady state is "ahead 1"). Check for drift with:
  `git -C <skill> rev-list --count HEAD..@{u}` after a fetch.

**How to apply:** clone to a short path (`C:\Users\<u>\clonetest`, NOT a deep
temp dir — Windows' 260-char MAX_PATH truncates the checkout and reports only a
warning, which reads as a repo defect but is a test-environment artifact). Then
make the installer's root overridable (`CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"`)
so it can be exercised against the clone without touching the live config.
Verify file count matches, then re-clone once more after fixing to close the loop.

Also worth knowing: `git add --renormalize .` touching 0 files proves a
`.gitattributes` line-ending policy pins the status quo rather than changing it
— run it before assuming CRLF/LF is the cause of a conflict. It was not here;
see the `.last-cleanup` note in `.gitignore`. Related: [[debugging-patterns]].
