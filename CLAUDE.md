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
| | WeChat mini-program / Taro / 小程序 / rpx / wx.* API | `taro-miniprogram` |
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
- **WeChat mini-program**: `taro-miniprogram` + `typescript-pro` → `test-master` → `/verification-before-completion`
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

## Skill Creation Lessons (Meta-Rules)

从 `taro-miniprogram` 三轮迭代中提炼的通用规则，适用于所有 skill 的创建与评估：

### Skill 的真实价值定位

ALWAYS 明确 skill 的价值来源，而非假设"模型不知道才需要 skill"：

- **安全覆盖**：当用户提供不安全输入时（如 `ws://`），skill 通过显式规则强制纠正，模型先验知识不可靠
- **项目一致性**：确保团队所有输出遵循同一模式（如 `taroStorage` 适配器的写法），而不是每人各自发明
- **解释驱动**：skill 推动模型不仅"改了"，还要"解释为什么"，提升代码可维护性

### Eval 断言设计规则

NEVER 写出 "两组配置（with_skill / without_skill）都能 100% 通过" 的断言——这样的断言毫无区分度。

好的断言需满足：
- **模型先验不能轻易答对**：涉及特定平台陷阱（协议限制、API 差异、包名问题）
- **skill 包含明确指引**：SKILL.md 中有对应规则，without_skill 模型需要自己推理
- **可从输出文件客观验证**：不依赖 "感觉上正确" 的主观判断

判断 eval 是否有效的经验法则：
```
如果 without_skill 能靠常识答对 → eval 太简单，需要换更难的场景
如果 with_skill 因跟随 SKILL.md 模式反而答错 → SKILL.md 有遗漏，需要修复 skill
```

### Skill 编写规则

ALWAYS 在 skill 中包含"主动覆盖用户输入"的规则，当用户提供的输入违反平台约束时：

```markdown
> ⚠️ [规则名]（必须执行）：若用户提供了 [不安全/不兼容的输入]，
> 必须主动将其改为 [正确值] 并在回答中说明原因。
```

NEVER 只展示"正确用法示例"而不明确说明"用户提供错误输入时如何处理"——
模型在 skill 存在时倾向于跟随示例模式，缺少覆盖指引会导致静默接受错误输入。

### Eval 迭代流程

```
Iter-N: 发现 with_skill 在某个断言失败
  → 检查 SKILL.md 对应章节是否有明确规则
  → 若无 → 在 SKILL.md 添加显式覆盖规则
  → Iter-(N+1): 重跑失败的 eval 验证修复
  → 若修复后 with_skill ≥ without_skill → 迭代成功
```

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
