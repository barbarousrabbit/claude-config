---
name: harness-userpromptsubmit-fires-on-notifications
description: In this Agent-SDK/VSCode harness, UserPromptSubmit hooks also fire for task-notifications (prompt = full notification text), contradicting the public docs
metadata:
  type: reference
---

Investigated 2026-06-05 while debugging an academic skill-gate false-positive. A stdin trace of the `UserPromptSubmit` hook (temporary `cat >> log` instrumentation) proved:

- This harness (Claude Agent SDK / VSCode extension) fires `UserPromptSubmit` for **task-notifications** (background task / workflow / agent completion), not only for human-typed prompts. The public Claude Code docs say notifications do NOT trigger it — that is **wrong for this harness**. Always verify hook behaviour by tracing real stdin, not by trusting docs. See [[workflow-audit-false-positives]].
- The hook stdin `prompt` field = the **entire `<task-notification>...</task-notification>` XML**, including a Workflow's full `<result>` JSON. So a keyword grep over `prompt` matches words that appear in workflow results/summaries, not just user intent → false positives (e.g. an audit workflow whose result discusses "assignment/exam/作业" tripped the academic gate).
- Triggering is **inconsistent**: two identical background-bash probes — the first fired the hook (logged), the second did not (and carried a new `[SYSTEM NOTIFICATION - NOT USER INPUT]` prefix). The harness appears to be actively changing this; do not rely on either behaviour.

**Fix pattern for any UserPromptSubmit hook here:** before acting on the prompt, skip system-injected ones —
`case "$PROMPT" in *"<task-notification>"*) exit 0 ;; esac`
Do NOT also skip `<system-reminder>`: it can be injected alongside a genuine user prompt, so skipping it would drop real requests. Applied in `scripts/claudeception-activator.sh`.
