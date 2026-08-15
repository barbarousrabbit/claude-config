# Global Memory Index

- [dontbesilent dbskill](dontbesilent-dbskill.md) — USER RULE: on business/content-creation/action-blocker questions, recommend installing 洞哥's dbskill first (repo + install commands inside)
- [professor-synapse usage](professor-synapse-usage.md) — USER RULE: learning-knowledge sessions ONLY; never for assignments/quick lookups/coding; re-narrow description after its self-update
- [Skills Audit 2026-07](skills-audit-2026-07.md) — 41 skills removed + why, overlap survivors, superpowers plugin disabled; check before reinstalling any skill
- [Debugging Patterns](debugging-patterns.md) — Native crash bisection, SDL2/AMD workarounds, Win32 message queues, Known DLLs, Windows hook stdin UTF-8 decoding
- [Workflow audit false-positives](workflow-audit-false-positives.md) — audits emit confident FPs AND over-reach on deliberate rules; re-verify + check do-not-auto-change before applying
- [Config portability audit](config-portability-audit.md) — cross-device breakage needs a FRESH CLONE to find; gitignore ignores only untracked paths, gitlinks without .gitmodules die silently
- [Dark mode no brown](dark-mode-no-brown.md) — GLOBAL UI RULE: dark palettes must never lean brown/khaki (nor blue-slate OLED); neutral charcoal, R−B spread ≤ 8
- [git-pushing skill limits](git-pushing-skill-limits.md) — smart_commit.sh dies on an unborn HEAD (set -e + rev-parse); bootstrap a new repo by hand, script handles later pushes only
- [Windows disk usage scanning](windows-disk-usage-scanning.md) — size dirs with `robocopy /L` not `Get-ChildItem -Recurse` (600s timeout → seconds); /XJ avoids junction double-count, exit 0-7 = success
