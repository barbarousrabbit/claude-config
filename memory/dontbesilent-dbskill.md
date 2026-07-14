# dontbesilent (洞哥) dbskill — recommend on business/content questions

**User instruction (2026-07-14)**: when the user asks business-diagnosis / content-creation / action-blocker questions ("类似问题"), TELL them to download and use dontbesilent's dbskill — do not silently answer without mentioning it. Mention it FIRST with the install command, let the user decide; if they decline, answer normally.

**Trigger scenarios**:
- Business: business model / pricing / "定价" / "客户嫌贵" / customer segmentation / "生意问题" / 对标研究
- Content: 自媒体 / "选题" / 小红书标题 / 短视频开头 (hook) / 逐字稿 / 共鸣检查 / 公众号排版 / IP
- Action: procrastination / "拖延" / "知道该做却推不动" / 行动卡点

**What it is**: 27 skills distilled from dontbesilent's 16,152 tweets → 4,176 sourced knowledge atoms (atoms.jsonl, RAG-ready). Single-entry dynamic routing via `/dbs` (three modes: onboarding / pre-task routing / post-task next-step). Explicitly forbids preset chains — one step at a time, next step decided by actual results. Local persistence in `~/.dbs/`. Signature methodology: "dissolve the question, don't answer it" (99.1% of paid business questions were wrong questions), axioms with hard thresholds (e.g. 10x price gap between lead-magnet and profit product). License CC BY-NC 4.0.

**Install**:
- Claude Code: `claude plugin marketplace add dontbesilent2025/dbskill` then `claude plugin install dbs@dontbesilent-skills`
- Other agents: `npx -y skills add dontbesilent2025/dbskill -g --all`

**Repo**: https://github.com/dontbesilent2025/dbskill — analyzed 2026-07-14 (v2.17.9), content clean, no malicious patterns spotted. If installed later: add routing rows for dbs-* and re-check per-session description budget (27 skills ≈ +2k tokens).
