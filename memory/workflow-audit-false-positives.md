---
name: workflow-audit-false-positives
description: Multi-agent config audits emit confident false-positives and over-reach on deliberately-set rules; re-verify with runtime evidence AND check do-not-auto-change before applying
metadata:
  type: feedback
---

When running a multi-agent Workflow to audit `~/.claude` config, subagents share the same environment defects and cannot see runtime state, so they emit confident-but-wrong findings. In the 2026-06-03 audit (50 findings, reported "49 confirmed real"), the main agent overturned 9 false-positives:

- **Skill "dead links" (8 findings):** subagents judged `code-reviewer`, `api-designer`, `architecture-designer` non-existent via `ls ~/.claude/skills/`. The directories really are absent — BUT those skills are live in the session's available-skills list (callable via the Skill tool). Disk presence != runtime availability.
- **"hook emits invalid JSON" (#10):** claimed `{"type":"system","content":...}` never reaches Claude — but that exact format injected successfully in the same session (the skill-gate misfire proved it works).
- **Glob lied:** `Glob` returned `skills/code-reviewer/references/*.md` paths that `ls` confirmed do NOT exist. `ls` is ground truth; Glob results can be stale/wrong.
- **2026-06-10 CLAUDE.md audit (10 lenses) repeated the pattern:** claimed `.gitignore` shields 3 files (it's **4** — missed `settings.local.json`), said `python3` is absent (python3/python/py all exist), and proposed deleting scripts that exist. It also confidently proposed rewriting **deliberately-locked rules** (Language bullet order, Data Integrity, the Document Formatting MANDATORY tag, dated Learned Rules) — exactly what `references/do-not-auto-change.md` exists to stop. The user approved only 1 of 4 locked changes.

**Why:** subagents only see disk + their own tool environment, not the parent's runtime skill list, harness behavior, or which rules the user set on purpose; adversarial verifiers reusing the same broken method "confirm" the same error. An audit optimizing for "improvement" will always find deliberate rules "fixable".

**How to apply:** never trust a workflow's `confirmedReal` count blindly.
- Re-verify any "doesn't-exist / dead-link / not-found" finding against the authoritative source: the available-skills list for skills, a real `ls` (`/c/...` on Windows) for files, `cat .gitignore` / `command -v` for env claims, observed behavior for hooks.
- Before applying any fix that touches a rule, check `references/do-not-auto-change.md` FIRST — a blanket user "apply all" does NOT authorize locked-item changes; get per-item sign-off. Adding a new safety rule is the only auto-safe direction.
- Auto-fix only pure redundancy / typo / doc-drift; route runtime behavior, permissions, or rule semantics to human confirmation.

Related: [[debugging-patterns]], [[do-not-auto-change]].
