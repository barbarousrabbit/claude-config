# Global Rules

## Config Sync — MANDATORY
- Global config is synced via Git repo: `https://github.com/barbarousrabbit/claude-config.git`
- **Session start**: Auto `git pull` via SessionStart hook (no manual action needed)
- **Session end**: If ANY file under `~/.claude/` was modified during this session (CLAUDE.md, skills, settings, etc.), ALWAYS run before finishing:
  ```bash
  cd ~/.claude && git add -A && git commit -m "update: <brief description>" && git push
  ```
- NEVER skip the push step — other machines depend on staying in sync

## Skill Usage — MANDATORY

ALWAYS check for applicable skills BEFORE responding. If a skill matches the task even 1%, invoke it first.

### Skill Routing Table

Match user intent to the correct skill. Multiple skills can chain together.

**Workflow & Planning:**
| Trigger | Skill |
|---------|-------|
| New feature, design discussion | `/brainstorming` → then `/writing-plans` |
| Multi-step implementation | `/writing-plans` → `/executing-plans` |
| Bug, error, test failure | `/systematic-debugging` |
| Code complete, ready to merge | `/verification-before-completion` → `/requesting-code-review` |
| Git commit, commit message | `conventional-commits` |
| Release notes, changelog | `changelog-generator` |
| Parallel independent tasks | `/dispatching-parallel-agents` |

**Programming Languages:**
| Trigger | Skill |
|---------|-------|
| Python code | `python-pro` |
| TypeScript code | `typescript-pro` |
| JavaScript code | `javascript-pro` |
| Go code | `golang-pro` |
| Rust code | `rust-engineer` |
| SQL queries, schema design | `sql-pro` + `database-optimizer` |

**Frontend & UI:**
| Trigger | Skill |
|---------|-------|
| Build web UI, components, pages | `frontend-design` + `ui-ux-pro-max` |
| Tailwind setup, theming | `tailwind-theme-builder` → `shadcn-ui` |
| Color scheme, brand palette | `color-palette` |
| Next.js App Router, SSR/SSG | `nextjs-pro` |
| Complex React artifacts | `web-artifacts-builder` |
| Accessibility (a11y) audit | `claude-a11y` |
| Responsive layout testing | `responsiveness-check` |
| UX quality review | `ux-audit` |
| Poster, visual art | `canvas-design` |
| Favicon generation | `favicon-gen` |
| SVG icon set | `icon-set-generator` |
| Image resize, crop, convert | `image-processing` |

**Data & Visualization:**
| Trigger | Skill |
|---------|-------|
| CSV/data file analysis | `csv-data-summarizer` + `exploratory-data-analysis` |
| Interactive charts, dashboard | `plotly` or `claude-d3js` |
| Static publication figures | `matplotlib` or `seaborn` |
| Statistical modeling, time series | `statsmodels` |
| ML classification/regression | `scikit-learn` |
| Deep learning | `pytorch-lightning` |
| Graph/network analysis | `networkx` |

**Documents & Presentations:**
| Trigger | Skill |
|---------|-------|
| .pdf file (read/create/merge) | `pdf` |
| .docx file (Word document) | `docx` |
| .xlsx/.csv spreadsheet | `xlsx` |
| .pptx (PowerPoint) | `pptx` |
| HTML slides, presentation | `revealjs` |
| Markdown → EPUB ebook | `markdown-to-epub` |

**Code Quality & Testing:**
| Trigger | Skill |
|---------|-------|
| Code review, PR review | `code-reviewer` |
| Security audit, vulnerabilities | `security-reviewer` |
| Write tests, test strategy | `test-master` + `/test-driven-development` |
| Browser automation testing | `webapp-testing` |
| Add docstrings, API docs | `code-documenter` |

**DevOps & Architecture:**
| Trigger | Skill |
|---------|-------|
| CI/CD, Docker, K8s | `devops-engineer` |
| System architecture design | `architecture-designer` |
| API design (REST/GraphQL) | `api-designer` |
| Build MCP server | `mcp-builder` |

**Research & Learning:**
| Trigger | Skill |
|---------|-------|
| Recent trends, community discussions | `last30days` |
| Create new custom skill | `skill-creator` |
| Internationalization, i18n | `i18n-expert` |
| Prompt design, AI workflows | `prompt-engineering` |
| Extract session learnings | `/claudeception` |

### Skill Chaining Patterns

Common multi-skill workflows:
- **New feature**: `/brainstorming` → `/writing-plans` → `/test-driven-development` → `/executing-plans` → `/requesting-code-review`
- **Web UI project**: `ui-ux-pro-max` → `tailwind-theme-builder` → `shadcn-ui` → `frontend-design` → `responsiveness-check` → `ux-audit`
- **Data report**: `csv-data-summarizer` → `exploratory-data-analysis` → `plotly`/`matplotlib` → `pdf` or `docx`
- **Debug flow**: `/systematic-debugging` → `debugging-wizard` → fix → `/verification-before-completion`
- **Next.js project**: `nextjs-pro` → `tailwind-theme-builder` → `shadcn-ui` → `claude-a11y` → `responsiveness-check`
- **Release flow**: `conventional-commits` → `/verification-before-completion` → `changelog-generator`

## New Project Onboarding

When starting work on a new project for the first time:
1. Search for all available skills relevant to the project's tech stack
2. Add a section to the project's `.claude/CLAUDE.md` documenting:
   - Which skills apply and when to invoke each one
   - Project-specific skill usage guidelines
3. If the project has no `.claude/CLAUDE.md`, create one

## Self-Improvement Meta-Rules (Claude-Meta)

### The Magic Prompt
When Claude makes a mistake and the user corrects it, if the user says:
> "Reflect on this mistake. Abstract and generalize the learning. Write it to CLAUDE.md."

Then Claude MUST:
1. **Reflect** — Analyze what went wrong and why
2. **Abstract** — Extract the general pattern (not just the specific case)
3. **Generalize** — Create a reusable rule for similar future situations
4. **Write** — Add the new rule to the project's CLAUDE.md following the guidelines below

### Writing Effective Rules
When adding new rules to any CLAUDE.md, follow these principles:

**Core Principles:**
1. Use absolute directives — Start with "NEVER" or "ALWAYS"
2. Lead with why — Explain the problem before the solution (1-3 bullets max)
3. Be concrete — Include actual commands/code when helpful
4. Minimize examples — One clear point per code block
5. Bullets over paragraphs — Keep explanations concise

**Anti-Bloat Rules:**
- Do NOT add verbose explanations for obvious rules
- Do NOT show bad examples for trivial mistakes
- Do NOT write paragraphs when bullets will do
- Every mistake becomes a permanent rule — the project gets smarter over time
