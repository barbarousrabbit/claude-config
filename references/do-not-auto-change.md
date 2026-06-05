# Do-Not-Auto-Change List (Guardrails)

Rules and config the user set deliberately. Treat these as LOCKED: do NOT change, move, condense, rename, translate, or "simplify" them in any automated optimization / cleanup / refactor pass without EXPLICIT user sign-off for that specific change. Adding a stricter safety rule (e.g. a new `deny` entry) is the only auto-safe direction.

Established 2026-06-03 during a config audit, after a multi-agent pass repeatedly proposed "fixing" intentional rules. See [[workflow-audit-false-positives]].

## CLAUDE.md (global — `C:\Users\Zhang\.claude\CLAUDE.md`)
- **`## Language — CRITICAL`** — must stay in position 1. Do not move, merge, rename, translate its Chinese example tokens, or delete the "NEVER output Korean" line.
- **Chinese trigger tokens** anywhere (routing tables, skill descriptions, the Fact-Check `没有` / `不存在` / `你是对的，抱歉`) — never romanise, translate, or strip. They exist to match Chinese user input.
- **`## Data Integrity — MANDATORY`** — may be reworded for brevity ONLY if every constraint stays verbatim in force.
- **`## Document Formatting — MANDATORY`** — black-font / no-colored-headings / aspect-ratio / orphan-prevention rules are intentional (reinforced in the project CLAUDE.md). Do not relax.
- **`## Fact-Check Before Denying — MANDATORY`** — intentional anti-false-denial policy backed by a real incident memory. Keep its Chinese triggers.
- **`### Learned Rules`** — dated post-incident scar-tissue rules. Do not delete or label "duplicative". Wording may be clarified only with sign-off (e.g. the clarification to the 2026-04-20 academic-routing rule).

## settings.json (`C:\Users\Zhang\.claude\settings.json`)
- **`permissions.allow` → `Bash(*)`** — deliberate convenience trade-off, counterbalanced by the deny list. A hardening pass must NOT narrow it to an allowlist or remove it.
- **`permissions.deny`** — the hard safety floor that makes `Bash(*)` acceptable. Do not remove, merge, reorder, or loosen entries. Adding a deny is the only safe direction.
- **`env` values** — `ANTHROPIC_MODEL` pin, `CLAUDE_CODE_EFFORT_LEVEL=max`, `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1`, top-level `effortLevel=max` are deliberate performance choices. Do not change values. (The env-vs-top-level `effortLevel` duplication is the one cleanup candidate — but only with sign-off, since which one the harness honours is unconfirmed.)

## Auto-managed / out of scope
- `plugins/blocklist.json`, `plugins/*.json` — auto-managed by the plugin system and git-ignored. Do not hand-edit.
- `settings.json` `additionalDirectories` — the harness may rewrite per session; the child entries may be intentional. Do not "dedupe" without confirming harness prefix-matching behaviour.
- **Project file** `e:\UTS\2026 Semester  1\CLAUDE.md` and **course CLAUDE.md files** — the "NEVER include AI usage declaration" rule, "AI Trap Detection" procedure, and document-formatting rules live there. A global-config pass must not touch them.

## How to use this file
Before any automated edit to the files above, check this list. If the edit touches a LOCKED item, stop and ask the user for explicit approval of that specific change.
