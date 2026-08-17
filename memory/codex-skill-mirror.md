# Codex skill mirror: how Codex gets skills that live in ~/.claude/skills

## What

Codex (CLI and the Windows desktop app share `~/.codex/`) loads skills from
`~/.codex/skills/` **only** and never reads `~/.claude/`. Some skills in
`~/.claude/skills/` already ship in Codex format -- an `agents/openai.yaml`
beside `SKILL.md` (as of 2026-08-17: `diagnosing-bugs`, `grill-me`, `grilling`,
`handoff`, `tdd`, all from mattpocock/skills v1.1.0). A byte-identical copy of
such a folder is all Codex needs.

`scripts/mirror-skills-to-codex.sh` + `scripts/codex-mirror-skills.txt` (2026-08-17)
copy the listed skills one-way into `~/.codex/skills/<name>/`, replacing a copy
only when its content differs, stamping each copy with a `.claude-mirror` marker,
and pruning marker-bearing copies whose name left the manifest. It runs from the
SessionStart hook (after `sync-pull`, so an upstream skill update reaches Codex
at the next Claude session) and from `bootstrap.sh`; `--dry-run` reports only.

## Why

- Copying a folder by hand works once and then silently rots: the next
  mattpocock/skills upgrade updates `~/.claude/skills/grill-me` but not the Codex
  copy, and a fresh device never gets it. A manifest in the synced repo makes
  "Codex has grill-me" a property of the config, not of one machine.
- The marker is what makes pruning safe. `~/.codex/skills/` also holds
  `.system/` (Codex vendor skills: imagegen, openai-docs, plugin-creator,
  review-agent, skill-creator, skill-installer) and skills installed by other
  tools -- e.g. the GPT换肤 repo's `scripts/install-skills.ps1` mirrors its own
  `dream-skin-theme` / `dream-skin-experience` there. Unmarked directories are
  never touched, so the two installers coexist.

## Gotchas learned

- A skill with `disable-model-invocation: true` (grill-me, handoff) does NOT
  appear in Claude Code's model-invocable skill list -- it is slash-command only.
  "grill-me is not in the list" therefore does not mean "grill-me is not
  installed"; check `ls ~/.claude/skills/grill-me` first. `grill-me` is a
  one-line wrapper that runs `/grilling`; the pair always travels together.
- In Codex the same `policy.allow_implicit_invocation: false` in
  `agents/openai.yaml` makes grill-me/handoff user-invoked only (`$grill-me`).
- Upstream `grill-me/SKILL.md` says "Run a `/grilling` session" (Claude slash
  form). Codex invokes skills as `$grilling`; the mirror stays byte-identical
  and does not rewrite this -- Codex resolves it by name.
- Verifying that Codex *sees* a skill cannot be done from Claude Code without
  spending Codex quota (`codex exec ...`); the cheap check is a new Codex
  conversation and typing `$grill` in the composer to see the completion.

## How to apply

```bash
# add a skill for Codex: append its directory name to the manifest, then
bash ~/.claude/scripts/mirror-skills-to-codex.sh            # apply
bash ~/.claude/scripts/mirror-skills-to-codex.sh --dry-run  # must end "0 failed"
# remove: delete its line; the next run prunes only that marker-bearing copy
```

Only Codex-format skills belong in the manifest. A Claude-only skill (relies on
`AskUserQuestion`, the `Skill` tool, hooks) would load in Codex but not work.
