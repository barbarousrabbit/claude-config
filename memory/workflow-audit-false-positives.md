---
name: workflow-audit-false-positives
description: Multi-agent config audits emit confident false-positives; the main agent must re-verify with runtime evidence before applying fixes
metadata:
  type: feedback
---

When running a multi-agent Workflow to audit `~/.claude` config, subagents share the same environment defects and cannot see runtime state, so they emit confident-but-wrong findings. In the 2026-06-03 audit (50 findings, reported "49 confirmed real"), the main agent overturned 9 false-positives:

- **Skill "dead links" (8 findings):** subagents judged `code-reviewer`, `api-designer`, `architecture-designer` non-existent via `ls ~/.claude/skills/`. The directories really are absent — BUT those skills are live in the session's available-skills list (callable via the Skill tool). Disk presence != runtime availability.
- **"hook emits invalid JSON" (#10):** claimed `{"type":"system","content":...}` never reaches Claude — but that exact format injected successfully in the same session (the skill-gate misfire proved it works).
- **Glob lied:** `Glob` returned `skills/code-reviewer/references/*.md` paths that `ls` confirmed do NOT exist. `ls` is ground truth; Glob results can be stale/wrong.

**Why:** subagents only see disk + their own tool environment, not the parent's runtime skill list or harness behavior; adversarial verifiers that reuse the same broken `ls`/path method "confirm" the same error, so a false-positive survives verification.

**How to apply:** never trust a workflow's `confirmedReal` count blindly. Before applying any "dead link / not-found" fix, re-verify against the authoritative source — the available-skills list for skills, a real `ls` (POSIX mount `/c/...` on Windows, not `C:\`) for files, observed runtime behavior for hooks. Auto-fix only pure redundancy / typo / doc-drift; route anything touching runtime behavior, permissions, or rule semantics to human confirmation. Related: [[debugging-patterns]].
