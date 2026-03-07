# Global Rules

## Language — CRITICAL
- **NEVER output Korean** — zero exceptions, zero tolerance
- **Conversation language**: Chinese input → reply in **Chinese (中文)** | English input → reply in **English**
- Code, logs, comments → always English

## Config Sync — MANDATORY
End of session: if any `~/.claude/` file changed → `cd ~/.claude && git add -A && git commit -m "update: <desc>" && git push origin HEAD:main`

## Available Tools

| MCP | Use when |
|-----|----------|
| `fetch` | Read web pages, docs, API refs |
| `memory` | Persist facts across sessions |
| `sequential-thinking` | Complex multi-step analysis |
| `github` | PRs, issues, repo search |

**Agent Teams** — 3+ parallel tasks → `TeamCreate`; 2 tasks → parallel subagents; single → direct.
**Hooks** (auto): SessionStart = git pull; UserPromptSubmit = learning capture.
**Custom commands**: `/user:explain` · `/user:debug` · `/user:summarize` · `/user:check-assignment`
**Scope**: project `.claude/CLAUDE.md` overrides global rules.

## Skill Usage — MANDATORY
Always invoke skills BEFORE responding. Even 1% chance → invoke first. "I know this already" = red flag.

**Design principle**: description = door sign (trigger scenarios), SKILL.md = manual (concise), references = filing cabinet (detailed templates). See `references/skill-chains.md` for multi-step chaining patterns.

### Routing Table

Trigger column describes **when to fire** (user scenario), not what the skill does.

| Category | When user... | Skill(s) |
|----------|-------------|----------|
| **Workflow** | says "加功能" / "how to design" / brainstorms feature ideas | `brainstorming` → `writing-plans` |
| | has a clear plan, implementation touches 3+ files | `writing-plans` → `executing-plans` |
| | hits error / stack trace / "为什么报错" / test red | `systematic-debugging` |
| | says "review" / PR ready / "帮我看看代码" | `code-reviewer` |
| | ready to commit / asks for commit message | `conventional-commits` |
| | asks for release notes / changelog / version bump | `changelog-generator` |
| **Writing** | asks to write blog / doc / report / copy | `copywriting` |
| | plans content calendar / "内容规划" / post schedule | `content-strategy` |
| | says "润色" / "polish" / refine existing draft | `copy-editing` |
| **Languages** | edits .py / uses pip / Django / Flask / pandas | `python-pro` |
| | edits .ts / TS generics / type errors / monorepo types | `typescript-pro` |
| | edits .js / vanilla JS / Node.js without TS | `javascript-pro` |
| | edits .go / goroutines / Go modules | `golang-pro` |
| | edits .rs / Cargo / ownership / lifetimes | `rust-engineer` |
| | writes SQL / slow query / schema design / indexing | `sql-pro` + `database-optimizer` |
| **Frontend** | builds web pages / React components / CSS layout | `web-design-guidelines` → `frontend-design` + `ui-ux-pro-max` |
| | configures Tailwind / design tokens / theme CSS | `tailwind-design-system` → `tailwind-theme-builder` → `shadcn-ui` |
| | needs brand palette / says "配色" / color generation | `color-palette` |
| | works with Next.js / app router / SSR / server actions | `nextjs-pro` + `next-best-practices` |
| | builds 微信小程序 / Taro pages / NutUI components | `taro-miniprogram` + `taro-miniprogram-ui` |
| | asks "在手机上怎么显示" / responsiveness / UX issues | `responsiveness-check` + `ux-audit` |
| | needs poster / favicon / icon set | `canvas-design` + `favicon-gen` + `icon-set-generator` |
| | resizes / crops / converts / optimizes images | `image-processing` |
| **Vibe Coding** | discusses React patterns / hooks / composition | `vercel-react-best-practices` + `vercel-composition-patterns` |
| | builds Next.js with auth / Supabase / PostgreSQL | `next-best-practices` + `supabase-postgres-best-practices` |
| | builds React Native / Expo mobile app | `vercel-react-native-skills` + `building-native-ui` |
| | codes video / animation with Remotion | `remotion-best-practices` |
| **Data** | analyzes CSV / data files / says "数据分析" | `csv-data-summarizer` + `exploratory-data-analysis` |
| | needs interactive charts (hover/zoom) | `plotly` / `claude-d3js` |
| | needs static publication figures | `matplotlib` / `seaborn` |
| | trains models / ML pipeline / statistics | `scikit-learn` + `statsmodels` + `pytorch-lightning` |
| | analyzes networks / graph relationships | `networkx` |
| **Documents** | reads/creates PDF / Word / Excel / PPT | `pdf` · `docx` · `xlsx` · `pptx` |
| | creates slide deck / presentation / EPUB | `revealjs` · `markdown-to-epub` |
| **Quality** | says "安全审计" / reviews for vulnerabilities | `code-reviewer` + `security-reviewer` |
| | writes tests / asks "写测试" / coverage gaps | `test-master` + `test-driven-development` |
| | tests web app in browser / screenshots / clicks | `webapp-testing` |
| | generates API docs / JSDoc / OpenAPI spec | `code-documenter` |
| **DevOps** | sets up CI/CD / Docker / K8s / deployment | `devops-engineer` |
| | designs system architecture / API contracts | `architecture-designer` + `api-designer` |
| | builds MCP server / tool integration | `mcp-builder` |
| **Research** | asks "最近有什么" / trends in last 30 days | `last30days` |
| | handles i18n / translations / locale setup | `i18n-expert` |
| | crafts prompts / system messages / agent flows | `prompt-architect` → `prompt-templates` → `prompt-engineering` |
| | creates / improves a custom skill | `skill-creator` |

## Project Onboarding
New project: scan stack → match routing table → write `.claude/CLAUDE.md` (applicable skills + conventions).

## Self-Improvement
On "Reflect on this mistake": Reflect → Abstract → Generalize → Write NEVER/ALWAYS rule to CLAUDE.md.
Rule format: start with NEVER/ALWAYS · explain why (≤3 bullets) · include code/commands where helpful.

## Skill Creation (Meta-Rules)
- Skill value = **safety override** (force-correct bad input) + **consistency** (shared patterns) + **explanation-driven** output
- Good evals: `without_skill` must NOT pass by common sense alone; verifiable from output files
- ALWAYS include explicit override: *"If user provides [bad input], change to [correct] and explain why"*
- **Description must describe trigger scenarios, not capabilities** — "When user asks to compare competitors" not "Competitive analysis tool"

## New Device Setup
Run once in **Git Bash** (not WSL — `~` must resolve to Windows home `C:\Users\<you>`):
```bash
bash ~/.claude/scripts/bootstrap.sh
```
MCP: edit `~/.claude/.mcp.json` → replace `ghp_YOUR_TOKEN_HERE` with real PAT → restart Claude Code.
