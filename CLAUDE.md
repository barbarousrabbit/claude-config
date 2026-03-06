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

### Routing Table

| Category | Trigger | Skill(s) |
|----------|---------|----------|
| **Workflow** | New feature | `brainstorming` → `writing-plans` |
| | Multi-step impl | `writing-plans` → `executing-plans` |
| | Bug / error | `systematic-debugging` |
| | Code review | `code-reviewer` |
| | Git commit | `conventional-commits` |
| | Release notes | `changelog-generator` |
| **Writing** | Blog / docs / reports | `copywriting` |
| | Content planning & scheduling | `content-strategy` |
| | Draft polishing | `copy-editing` |
| **Languages** | Python | `python-pro` |
| | TypeScript | `typescript-pro` |
| | JavaScript | `javascript-pro` |
| | Go | `golang-pro` |
| | Rust | `rust-engineer` |
| | SQL | `sql-pro` + `database-optimizer` |
| **Frontend** | Web UI / pages | `web-design-guidelines` → `frontend-design` + `ui-ux-pro-max` |
| | Tailwind + theming | `tailwind-design-system` → `tailwind-theme-builder` → `shadcn-ui` |
| | Color palette | `color-palette` |
| | Next.js | `nextjs-pro` + `next-best-practices` |
| | WeChat mini-program | `taro-miniprogram` + `taro-miniprogram-ui` |
| | Responsive / UX audit | `responsiveness-check` + `ux-audit` |
| | Poster / favicon / icons | `canvas-design` + `favicon-gen` + `icon-set-generator` |
| | Image processing | `image-processing` |
| **Vibe Coding** | React best practices | `vercel-react-best-practices` + `vercel-composition-patterns` |
| | Next.js architecture | `next-best-practices` + `better-auth-best-practices` |
| | Supabase + PostgreSQL | `supabase-postgres-best-practices` |
| | React Native / Expo | `vercel-react-native-skills` + `building-native-ui` |
| | Video / animation code | `remotion-best-practices` |
| | Web design quality | `web-design-guidelines` + `tailwind-design-system` |
| **Data** | CSV / data analysis | `csv-data-summarizer` + `exploratory-data-analysis` |
| | Charts | `plotly` / `claude-d3js` (interactive) · `matplotlib` / `seaborn` (static) |
| | ML / stats | `scikit-learn` + `statsmodels` + `pytorch-lightning` |
| | Graph / network | `networkx` |
| **Documents** | PDF / Word / Excel / PPT | `pdf` · `docx` · `xlsx` · `pptx` |
| | Slides / EPUB | `revealjs` · `markdown-to-epub` |
| **Quality** | Code / security review | `code-reviewer` + `security-reviewer` |
| | Tests | `test-master` + `test-driven-development` |
| | Browser automation | `webapp-testing` |
| | API docs | `code-documenter` |
| **DevOps** | CI/CD / Docker / K8s | `devops-engineer` |
| | Architecture / API design | `architecture-designer` + `api-designer` |
| | MCP server | `mcp-builder` |
| **Research** | Trends (last 30 days) | `last30days` |
| | i18n / localization | `i18n-expert` |
| | Prompt design | `prompt-architect` → `prompt-templates` → `prompt-engineering` |
| | New skill | `skill-creator` |

### Chaining Patterns
- **New feature**: `brainstorming` → `writing-plans` → `test-driven-development` → `executing-plans` → `code-reviewer`
- **Content**: `content-strategy` → `writing-plans` → `copywriting` → `copy-editing`
- **Web UI**: `web-design-guidelines` → `ui-ux-pro-max` → `tailwind-design-system` → `frontend-design` → `responsiveness-check` → `ux-audit`
- **React app**: `vercel-react-best-practices` + `vercel-composition-patterns` → `web-design-guidelines` → `frontend-design` → `webapp-testing`
- **Next.js**: `next-best-practices` → `better-auth-best-practices` → `supabase-postgres-best-practices` → `webapp-testing`
- **React Native**: `vercel-react-native-skills` → `building-native-ui` → `webapp-testing`
- **Debug**: `systematic-debugging` → `debugging-wizard` → fix → `code-reviewer`
- **Release**: `conventional-commits` → `changelog-generator`
- **Video**: `remotion-best-practices` → `vercel-react-best-practices`

## Project Onboarding
New project: scan stack → match routing table → write `.claude/CLAUDE.md` (applicable skills + conventions).

## Self-Improvement
On "Reflect on this mistake": Reflect → Abstract → Generalize → Write NEVER/ALWAYS rule to CLAUDE.md.
Rule format: start with NEVER/ALWAYS · explain why (≤3 bullets) · include code/commands where helpful.

## Skill Creation (Meta-Rules)
- Skill value = **safety override** (force-correct bad input) + **consistency** (shared patterns) + **explanation-driven** output
- Good evals: `without_skill` must NOT pass by common sense alone; verifiable from output files
- ALWAYS include explicit override: *"If user provides [bad input], change to [correct] and explain why"*

## New Device Setup
Run once in **Git Bash** (not WSL — `~` must resolve to Windows home `C:\Users\<you>`):
```bash
bash ~/.claude/scripts/bootstrap.sh
```
MCP: edit `~/.claude/.mcp.json` → replace `ghp_YOUR_TOKEN_HERE` with real PAT → restart Claude Code.
