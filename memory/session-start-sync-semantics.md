---
name: session-start-sync-semantics
description: When another device pushed to ~/.claude, this session's CLAUDE.md in context is the pre-pull version and the new hook steps do not run until next start — re-read the rules from disk
metadata:
  type: project
---

Claude Code assembles the system prompt (global + project CLAUDE.md, skill list) BEFORE
the SessionStart hooks run. `hook-session-start.sh` step 2 (`sync-pull.sh`) then
fast-forwards `~/.claude` silently (`--quiet 2>/dev/null`; success prints nothing).
Two consequences whenever another device pushed since this device's last session:

- **The rules in context are stale for the whole session.** On 2026-08-18 the context
  still named `scripts/third-party-skills.tsv` and lacked the `normalize-eol.sh` /
  `update-skills.sh` hook steps, while `~/.claude/CLAUDE.md` on disk (pulled at 21:21,
  `ecc4f52..670a510`, 30 commits from the other device) already had them.
- **The hook that runs is the OLD one.** bash reads a script incrementally from the
  open inode; `git pull` unlinks and rewrites `hook-session-start.sh`, so the running
  process finishes the old step list. New steps (2b `normalize-eol.sh`, 5
  `update-skills.sh --auto`) first run at the NEXT session start. Symptom that day: no
  `[skill-update]` line and no `~/.claude/.skill-update/` dir although the hook on disk
  called for both.

**Why:** the sync is deliberately silent and non-blocking, so nothing in the transcript
says "rules changed". A session can spend an hour following an outdated rule.

**How to apply:** at the start of a `~/.claude` maintenance task -- or when the hook
output shows a merge/rebase message, or the reply feels out of step with the rules --
run `git -C ~/.claude reflog --date=iso -3`; a `pull --rebase --quiet origin main:
Fast-forward` stamped at session start means: re-read `~/.claude/CLAUDE.md` (and any
rule file the task touches) from disk before relying on the context copy, and run the
new hook steps by hand if the task needs them (`bash ~/.claude/scripts/normalize-eol.sh`,
`bash ~/.claude/scripts/update-skills.sh --check`). Related: [[skill-update-mechanism]],
[[config-portability-audit]].
