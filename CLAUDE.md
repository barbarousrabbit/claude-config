# Global Rules

## Config Sync — MANDATORY
- Repo: `https://github.com/barbarousrabbit/claude-config.git`
- **Start**: Auto `git pull` via SessionStart hook — no action needed
- **End**: If ANY file under `~/.claude/` changed during this session, MUST run:
  ```bash
  cd ~/.claude && git add -A && git commit -m "update: <description>" && git push
  ```
- NEVER skip the push — other machines depend on sync

## Scope Priority
- Project `.claude/CLAUDE.md` overrides global rules when they conflict
- Global rules apply everywhere unless a project explicitly overrides them

## Available Tools — Use Proactively

### MCP Servers (auto-started)
| Server | Capability | When to use |
|--------|-----------|-------------|
| `fetch` | Fetch any URL → Markdown | Read web pages, docs, API references |
| `memory` | Persistent knowledge graph | Store/recall facts across sessions |
| `sequential-thinking` | Step-by-step reasoning | Complex multi-step analysis |
| `github` | GitHub API (PRs, issues, code) | Create/review PRs, search repos, manage issues |

### Custom Commands (suggest to user when relevant)
| Command | Purpose |
|---------|---------|
| `/user:explain <topic>` | Explain code/concept in Chinese, beginner-friendly |
| `/user:check-assignment <path>` | Check assignment against rubric, score each criterion |
| `/user:summarize <file>` | Summarize file in Chinese with key points |
| `/user:debug <error>` | Step-by-step debugging with root cause analysis |

### Agent Teams
- Enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
- Use for large tasks with 3+ independent workstreams
- Each agent gets its own context window — use for parallel heavy work
- For simpler parallel tasks (2 quick searches), use subagents instead

### Hooks (auto-running, no action needed)
- **SessionStart**: git pull config sync + claude-reflect reminder
- **UserPromptSubmit**: claude-reflect learning capture

## Skill Usage — MANDATORY

ALWAYS check for applicable skills BEFORE responding. Even 1% match → invoke first.

### Skill Routing Table

| Category | Trigger | Skill(s) |
|----------|---------|----------|
| **Workflow** | New feature / design discussion | `/brainstorming` → `/writing-plans` |
| | Multi-step implementation | `/writing-plans` → `/executing-plans` |
| | Bug / error / test failure | `/systematic-debugging` |
| | Code complete, ready to merge | `/verification-before-completion` → `/requesting-code-review` |
| | Git commit | `conventional-commits` |
| | Release notes | `changelog-generator` |
| | 2+ independent tasks | `/dispatching-parallel-agents` |
| **Languages** | Python (.py) | `python-pro` |
| | TypeScript (.ts/.tsx) | `typescript-pro` |
| | JavaScript (.js/.jsx) | `javascript-pro` |
| | Go (.go) | `golang-pro` |
| | Rust (.rs) | `rust-engineer` |
| | SQL / schema design | `sql-pro` + `database-optimizer` |
| **Frontend** | Web UI / components / pages | `frontend-design` + `ui-ux-pro-max` |
| | Tailwind + theming | `tailwind-theme-builder` → `shadcn-ui` |
| | Color / brand palette | `color-palette` |
| | Next.js (App Router, SSR/SSG) | `nextjs-pro` |
| | Complex React artifacts | `web-artifacts-builder` |
| | Accessibility audit | `claude-a11y` |
| | Responsive layout test | `responsiveness-check` |
| | UX quality review | `ux-audit` |
| | Poster / visual art | `canvas-design` |
| | Favicon | `favicon-gen` |
| | SVG icon set | `icon-set-generator` |
| | Image resize/crop/convert | `image-processing` |
| **Data** | CSV / data file analysis | `csv-data-summarizer` + `exploratory-data-analysis` |
| | Interactive charts | `plotly` or `claude-d3js` |
| | Static publication figures | `matplotlib` or `seaborn` |
| | Statistical modeling | `statsmodels` |
| | ML (classification/regression) | `scikit-learn` |
| | Deep learning | `pytorch-lightning` |
| | Graph / network analysis | `networkx` |
| **Documents** | PDF | `pdf` |
| | Word (.docx) | `docx` |
| | Excel (.xlsx/.csv) | `xlsx` |
| | PowerPoint (.pptx) | `pptx` |
| | HTML slides | `revealjs` |
| | Markdown → EPUB | `markdown-to-epub` |
| **Quality** | Code review / PR | `code-reviewer` |
| | Security audit | `security-reviewer` |
| | Write tests | `test-master` + `/test-driven-development` |
| | Browser automation test | `webapp-testing` |
| | Docstrings / API docs | `code-documenter` |
| **DevOps** | CI/CD / Docker / K8s | `devops-engineer` |
| | System architecture | `architecture-designer` |
| | API design (REST/GraphQL) | `api-designer` |
| | MCP server | `mcp-builder` |
| **Research** | Recent trends (last 30 days) | `last30days` |
| | Create new skill | `skill-creator` |
| | i18n / localization | `i18n-expert` |
| | Design system/agent prompts | `prompt-engineering` |
| | "帮我优化这段提示词" | `prompt-architect` |
| | "用模板帮我写提示词" | `prompt-templates` |
| | Extract session learnings | `/claudeception` |

### Skill Chaining Patterns

- **New feature**: `/brainstorming` → `/writing-plans` → `/test-driven-development` → `/executing-plans` → `/requesting-code-review`
- **Web UI**: `ui-ux-pro-max` → `tailwind-theme-builder` → `shadcn-ui` → `frontend-design` → `responsiveness-check` → `ux-audit`
- **Next.js**: `nextjs-pro` → `tailwind-theme-builder` → `shadcn-ui` → `claude-a11y` → `responsiveness-check`
- **Data report**: `csv-data-summarizer` → `exploratory-data-analysis` → `plotly`/`matplotlib` → `pdf` or `docx`
- **Debug**: `/systematic-debugging` → `debugging-wizard` → fix → `/verification-before-completion`
- **Release**: `conventional-commits` → `/verification-before-completion` → `changelog-generator`
- **Prompt crafting**: `prompt-architect` → `prompt-templates` → `prompt-engineering`

## New Project Onboarding

First time working on a new project:
1. Scan the project's tech stack (language, framework, tools)
2. Match applicable skills from the Routing Table above
3. Write a `.claude/CLAUDE.md` in the project with:
   - Which skills apply and when to invoke each
   - Project-specific conventions
4. If the project already has one, review and update it

## Self-Improvement (Claude-Meta)

When the user says: *"Reflect on this mistake. Abstract and generalize the learning. Write it to CLAUDE.md."*

Claude MUST:
1. **Reflect** — What went wrong and why
2. **Abstract** — Extract the general pattern, not just this specific case
3. **Generalize** — Write a reusable rule (NEVER/ALWAYS directive)
4. **Write** — Add to the appropriate CLAUDE.md (global or project)

### Rule Writing Standards
- Start with "NEVER" or "ALWAYS"
- Lead with why (1-3 bullets max), then the rule
- Be concrete — include commands/code when helpful
- Bullets over paragraphs; one point per code block
- No verbose explanations for obvious rules
- Every correction becomes a permanent rule — projects get smarter over time

## New Device Setup — MANDATORY on First Run

After cloning `~/.claude` to a new device, run **once**:
```bash
bash ~/.claude/scripts/bootstrap.sh
```
This auto-installs Python skill dependencies, checks CLI tools, and creates `.mcp.json` from template.

### MCP Servers (fetch / memory / sequential-thinking / github)
1. Edit `~/.claude/.mcp.json` (created by bootstrap)
2. Replace `ghp_YOUR_TOKEN_HERE` with a real GitHub PAT
3. Restart Claude Code

### If bootstrap detects missing items
SessionStart hook prints warnings to stderr — follow the listed fixes. When user asks Claude to fix setup issues, run `bash ~/.claude/scripts/bootstrap.sh` directly.
