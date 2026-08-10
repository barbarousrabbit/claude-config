# Provenance — ponytail

**Vendored, not authored here. Do not hand-edit `SKILL.md`** — local edits are
silently lost on the next re-vendor, and they break diffing against upstream.

| | |
|---|---|
| Upstream | https://github.com/DietrichGebert/ponytail |
| Source path | `skills/ponytail/SKILL.md` |
| Pinned commit | `b6c04480c03e8db2f035751d7c46289779ec3362` (2026-07-10) |
| Vendored on | 2026-08-10 |
| License | MIT © 2026 DietrichGebert (see `LICENSE`) |

## Why vendored instead of `third-party-skills.tsv`

That manifest clones a whole repo to `skills/<dest>/`, which only works when the
repo has `SKILL.md` at its root (as `apple-hig-designer` does). Ponytail keeps
six skills under a `skills/` subdirectory, so a whole-repo clone would land the
file at `skills/ponytail/skills/ponytail/SKILL.md` — one level too deep to be
discovered. The upstream repo also ships `hooks/`, `scripts/`, and an MCP server;
vendoring the single markdown file keeps that executable surface out of
`~/.claude` entirely.

Vendoring also means the skill is a tracked file, so it cannot silently vanish
on a fresh clone the way an unmanifested third-party skill can.

## Updating

```bash
curl -fsSL https://raw.githubusercontent.com/DietrichGebert/ponytail/main/skills/ponytail/SKILL.md \
  -o ~/.claude/skills/ponytail/SKILL.md
git -C ~/.claude diff -- skills/ponytail/SKILL.md   # review before committing
```

Then update the pinned commit in the table above. Re-read the diff before
committing — this file is injected into every response, so an upstream change is
a change to how the agent behaves.

## Not installed

The other five upstream skills (`ponytail-audit`, `ponytail-debt`,
`ponytail-gain`, `ponytail-help`, `ponytail-review`) were deliberately left out:
every installed skill's `description` is loaded into context each session, and
the point of this skill is to spend fewer tokens. Add one the same way if a
concrete need shows up.
