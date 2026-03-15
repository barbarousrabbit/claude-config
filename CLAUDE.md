# Global Rules

## Language — CRITICAL
- **NEVER output Korean** — zero exceptions, zero tolerance
- **Conversation language**: Chinese input → reply in **Chinese** | English input → reply in **English**
- Code, logs, comments → always English

## Config Sync — MANDATORY
End of session: if any `~/.claude/` file changed → `cd ~/.claude && git add -A && git commit -m "update: <desc>" && git push origin HEAD:main`

## Available Tools (optional — may not be configured on all devices)

| MCP | Use when | Fallback if unavailable |
|-----|----------|------------------------|
| `fetch` | Read web pages, docs, API refs | Use `WebFetch` tool |
| `memory` | Persist facts across sessions | Use auto memory files |
| `sequential-thinking` | Complex multi-step analysis | Think step-by-step inline |
| `github` | PRs, issues, repo search | Use `gh` CLI via Bash |

**Agent Teams** — Default to `TeamCreate` for non-trivial tasks. Trigger on ANY of:
- Task touches 3+ files OR spans 2+ tech domains (frontend/backend/DB/infra/tests)
- Task has independent subtasks that can run in parallel (research + implement, frontend + backend, etc.)
- User says "implement", "build", "refactor", "review", "add feature" — if scope is unclear, assume team-worthy
- Single long task but benefits from a dedicated worker (e.g., writing tests while main agent codes)
Only go direct for: single-file edits, quick lookups, trivial one-liners.
**Hooks** (auto): SessionStart = git pull + session reminder; UserPromptSubmit = learning capture + claudeception evaluation.
**Custom commands**: `/user:explain` · `/user:debug` · `/user:summarize` · `/user:check-assignment`
**Scope**: project `.claude/CLAUDE.md` overrides global rules.

## Skill Usage
Invoke matching skills BEFORE responding when the task clearly fits the routing table. If a skill fails to load, fall back to direct handling — never retry a failed skill invocation.

**Design principle**: description = door sign (trigger scenarios), SKILL.md = manual (concise), references = filing cabinet (detailed templates). See `references/skill-chains.md` for multi-step chaining patterns.

### Routing Table

Trigger column describes **when to fire** (user scenario), not what the skill does.

| Category | When user... | Skill(s) |
|----------|-------------|----------|
| **Workflow** | says "I want to build...", "how should I design...", "what's the best approach", has a vague idea, asks "X or Y?", needs to think through requirements before coding | `brainstorming` → `writing-plans` |
| | has clear requirements, describes a specific feature / enhancement and wants task breakdown | `feature-planning` |
| | has a clear plan, implementation touches 3+ files | `writing-plans` → `executing-plans` |
| | 2+ independent subtasks / wants parallel execution | `dispatching-parallel-agents` |
| | hits error / stack trace / test failure / "why is this broken" | `systematic-debugging` |
| | says "review" / PR ready / wants code feedback | `requesting-code-review` → `code-reviewer` |
| | receives code review feedback / applying suggestions | `receiving-code-review` |
| | ready to commit / asks for commit message | `conventional-commits` |
| | says "commit and push" / "push this" / "save my work" | `git-pushing` |
| | asks for release notes / changelog / version bump | `changelog-generator` |
| | feature complete / ready to merge branch | `finishing-a-development-branch` |
| | about to say "done" / mark task complete | `verification-before-completion` |
| | needs isolated workspace for feature development | `using-git-worktrees` |
| **Writing** | asks to write blog / doc / report / copy | write directly (no dedicated skill installed) |
| | plans content calendar / post schedule | write directly (no dedicated skill installed) |
| | says "polish" / refine existing draft | write directly (no dedicated skill installed) |
| **Languages** | edits .py / uses pip / Django / Flask / pandas | `python-pro` |
| | edits .ts / TS generics / type errors / monorepo types | `typescript-pro` |
| | edits .js / vanilla JS / Node.js without TS | `javascript-pro` |
| | edits .go / goroutines / Go modules | `golang-pro` |
| | edits .rs / Cargo / ownership / lifetimes | `rust-engineer` |
| | writes SQL / slow query / schema design / indexing | `sql-pro` + `database-optimizer` |
| **Frontend** | builds web pages / React components / CSS layout | `web-design-guidelines` → `frontend-design` + `ui-ux-pro-max` + `interface-design` |
| | implements dashboard / admin panel / tool UI | `interface-design` + `frontend-patterns` + `senior-frontend` |
| | configures Tailwind / design tokens / theme CSS | `tailwind-theme-builder` → `shadcn-ui` |
| | needs brand palette / color generation | `color-palette` |
| | works with Next.js / app router / SSR / server actions | `nextjs-pro` |
| | builds WeChat mini-program / Taro pages / NutUI components | `taro-miniprogram` + `taro-miniprogram-ui` |
| | asks about mobile display / responsiveness / UX issues | `responsiveness-check` + `ux-audit` |
| | needs poster / favicon / icon set | `canvas-design` + `favicon-gen` + `icon-set-generator` |
| | resizes / crops / converts / optimizes images | `image-processing` |
| **UI Refinement** (impeccable) | checks UI quality / WCAG / "what's wrong" / responsiveness | `audit` |
| | reviewing design / visual hierarchy / UX feedback | `critique` |
| | final pass before shipping / spacing / alignment / consistency | `polish` |
| | design too safe / generic / boring / needs more impact | `bolder` |
| | design too loud / aggressive / cluttered | `quieter` |
| | UI too gray / colorless / monotone | `colorize` |
| | adding hover effects / transitions / micro-interactions | `animate` |
| | UI cluttered / over-designed / needs simplification | `distill` |
| | needs error states / i18n / loading states / edge cases | `harden` |
| | component inconsistent / doesn't match design system | `normalize` |
| | extracting reusable components / deduplicating UI patterns | `extract` |
| | UI copy unclear / button labels / error messages confusing | `clarify` |
| | UI functional but cold / needs personality / delight | `delight` |
| | empty states / first-run experience / onboarding flows | `onboard` |
| | UI loads slowly / animations stutter / bundle too large | `optimize` |
| | adapting UI for mobile / tablet / cross-platform | `adapt` |
| | first time using impeccable / establishing design context | `teach-impeccable` |
| **Vibe Coding** | discusses React patterns / hooks / composition | `vercel-react-best-practices` + `vercel-composition-patterns` |
| | builds Next.js with auth / Supabase / PostgreSQL | `nextjs-pro` |
| | builds React Native / Expo mobile app | not installed — handle directly |
| | codes video / animation with Remotion | not installed — handle directly |
| **Data** | analyzes CSV / data files / asks for data analysis | `csv-data-summarizer` + `exploratory-data-analysis` |
| | needs interactive charts (hover/zoom) | `plotly` / `claude-d3js` |
| | needs static publication figures | `matplotlib` / `seaborn` |
| | trains models / ML pipeline / statistics | `scikit-learn` + `statsmodels` + `pytorch-lightning` |
| | analyzes networks / graph relationships | `networkx` |
| **Documents** | reads/creates PDF / Word / Excel / PPT | `pdf` · `docx` · `xlsx` · `pptx` |
| | creates slide deck / presentation / EPUB | `revealjs` · `markdown-to-epub` |
| **Quality** | asks "how good is this code" / wants codebase health check / technical debt audit | `code-auditor` |
| | asks for security audit / reviews for vulnerabilities | `code-reviewer` + `security-reviewer` |
| | reviewing a PR/MR and wants more than style nits (blast radius, security, breaking changes) | `pr-review-expert` |
| | code is slow / page loads sluggishly / "why is this slow" | `performance-profiler` |
| | checking dependencies for vulnerabilities / license compliance / outdated packages | `dependency-auditor` |
| | writes tests / asks to write tests / coverage gaps | `test-master` + `test-driven-development` |
| | tests web app in browser / screenshots / clicks | `webapp-testing` |
| | generates API docs / JSDoc / OpenAPI spec | `code-documenter` |
| **DevOps** | joining unfamiliar codebase / onboarding new teammate / needs map of "what does what" | `codebase-onboarding` |
| | sets up CI/CD / Docker / K8s / deployment | `devops-engineer` |
| | designs system architecture / API contracts | `architecture-designer` + `api-designer` |
| | builds MCP server / tool integration | `mcp-builder` |
| **Research** | asks about recent trends / last 30 days | `last30days` |
| | handles i18n / translations / locale setup | `i18n-expert` |
| | crafts prompts / system messages / agent flows | `prompt-architect` → `prompt-templates` → `prompt-engineering` |
| | creates / improves a custom skill | `skill-creator` + `writing-skills` |
| | completes non-trivial debugging / wants to extract reusable knowledge | `claudeception` |

## Project Onboarding
New project: scan stack → match routing table → write `.claude/CLAUDE.md` (applicable skills + conventions).

## Experience Recording — MANDATORY
ALWAYS record reusable knowledge to memory files at these trigger points:
1. **Task completion** — after solving any non-trivial bug, building a feature, or finishing a multi-step task
2. **Discovery** — when finding a root cause, a useful pattern, a gotcha, or a workaround
3. **User says "记录/记住/remember"** — immediately write to memory

**How to record:**
- Check existing memory files FIRST to avoid duplicates → update if related entry exists
- **Project memory** (`<project>/memory/`) — project-specific findings, architecture notes, fix details
- **Global memory** (`~/.claude/memory/`) — reusable patterns, debugging techniques, tool gotchas applicable across projects
- Structure: **What** (problem) → **Why** (root cause) → **How** (solution) → **Code** (reproducible snippets)
- Keep entries actionable — future-you should be able to apply the knowledge without re-investigating

**NEVER skip recording because the task "seems too small".** A 5-line fix that took 2 hours to find is the MOST valuable thing to record.

## Self-Improvement
On "Reflect on this mistake": Reflect → Abstract → Generalize → Write NEVER/ALWAYS rule to CLAUDE.md.
Rule format: start with NEVER/ALWAYS · explain why (≤3 bullets) · include code/commands where helpful.

## Skill Creation (Meta-Rules)
- Skill value = **safety override** (force-correct bad input) + **consistency** (shared patterns) + **explanation-driven** output
- Good evals: `without_skill` must NOT pass by common sense alone; verifiable from output files
- ALWAYS include explicit override: *"If user provides [bad input], change to [correct] and explain why"*
- **Description must describe trigger scenarios, not capabilities** — "When user asks to compare competitors" not "Competitive analysis tool"
- **Description length ~80 chars, SKILL.md body ≤200 lines** — expand description (more trigger keywords = higher hit rate), compress SKILL.md body (shorter = more context window for actual task = better output). Move detailed templates to `references/`. One up, one down.

## New Device Setup (Windows)
Run once in **Git Bash** (`~` must resolve to Windows home `C:\Users\<you>`):
```bash
bash ~/.claude/scripts/bootstrap.sh
```
Then edit `~/.claude/.mcp.json` → replace `ghp_YOUR_TOKEN_HERE` with real GitHub PAT → restart Claude Code.
