# Skill & Agent Routing Tables (Reference)

Extracted from CLAUDE.md to keep the always-loaded rules file lean. CLAUDE.md retains the behavioural routing rules (invoke-before-responding, the Red Flags table, precedence); this file holds the large lookup tables. Load this when mapping a task to a specific skill or to an Agency agent division.

## Part 1 -- Agency Agent Trigger Table

When no skill matches but the task fits marketing / sales / product / PM / game / XR / compliance / finance, route to the division below. See `references/agent-routing.md` for the full per-agent index.

| Trigger keywords | Division |
|-----------------|----------|
| 营销/增长/SEO/社媒/涨粉/种草/推广/获客/转化 | marketing/ |
| 小红书/抖音/快手/微信/微博/B站/知乎/百度 | marketing/ |
| 电商/跨境/直播带货/私域 | marketing/ |
| 广告投放/PPC/投流/竞价/出价 | paid-media/ |
| 销售/BD/提案/客户管理 | sales/ |
| 产品管理/Sprint/用户反馈 | product/ |
| 项目管理/排期/Jira | project-management/ |
| 游戏开发/Unity/Unreal/Godot/Roblox | game-development/ |
| VR/AR/XR/visionOS/空间计算 | spatial-computing/ |
| 合规/法务/SOC2/HIPAA | specialized/ |
| 财务/预算/报表 | support/ |
| 招聘/培训/留学 | specialized/ |
| 客服/工单/用户支持 | support/ |
| 供应链/采购/物流 | specialized/ |

## Part 2 -- Skill Routing Table

### Routing Table

Trigger column describes **when to fire** (user scenario), not what the skill does.

**Matching mechanism:**
- Fire on **either** the English scenario **OR** any Chinese trigger phrase — both map to the same skill.
- **Partial/fuzzy match counts**: a single keyword hit is enough; never require the whole phrase ("做海报" alone → `canvas-design`).
- **Multiple rows match** → resolve by precedence first (**Academic > Planning > category-specific skill**, per CLAUDE.md Routing priority); within the same tier, run the most specific row (the one whose parenthetical context matches the user's situation). When the cell shows `→` or `+`, chain/combine those skills in order.
- **Unsure?** Invoke the candidate skill anyway — a wrong load is cheap, a missed skill is not.
- **No row matches** but task fits marketing/sales/product/PM/game/XR/compliance/finance → fall back to an Agency Agent (see `~/.claude/references/agent-routing.md`).

| Category | When user... | Skill(s) |
|----------|-------------|----------|
| **Planning (CEO)** | has a vague idea / "I want to build..." / "how should I..." / "what's the best approach" / asks "X or Y?" / "我想做个X" / "X好还是Y好" / "怎么搞" / "有什么思路" | `brainstorming` → design approval → implement |
| | has clear requirements / describes a specific feature or enhancement / "加个功能" / "需求很明确" / "规划这个功能" | `EnterPlanMode` |
| | has a clear plan, implementation touches 3+ files / "有计划了" / "写实现计划" / "改好几个文件" | `EnterPlanMode` → execute phase by phase |
| | describes any multi-step task (3+ steps) regardless of domain / "多步任务" / "好几步" / "帮我搞定整个" | `brainstorming` or `EnterPlanMode` → plan → execute |
| | 2+ independent subtasks / wants parallel execution / "并行做" / "同时进行" / "几件事一起办" | `dispatching-parallel-agents` |
| **Academic** | mentions course number (32011/32516/32558/42850) or course name, OR context is clearly academic | Route to Academic first — read course CLAUDE.md → apply course-specific rules |
| | presents assignment brief / rubric / "帮我做作业" / "写报告" / "做 assignment" / "help me with assignment" / "整理成作业" / "整理成Assignment" | Read rubric → Assignment Workflow (Step 1: Reference Docs → Step 2: Plans) → `EnterPlanMode` → write → `/check-assignment` |
| | has data to analyze **for a course/assignment (rubric present)** / BI project / "分析数据" / "做分析" / Tableau / ETL / data warehouse | Assess data → Assignment Workflow (Step 1: Reference Docs if rubric exists) → `EnterPlanMode` → analyze → visualize → validate |
| | NLP/ML work / "训练模型" / "做 notebook" / Jupyter / BERT / tokenization / word embedding | Read brief → `EnterPlanMode` → `python-pro` + `scikit-learn`/`pytorch-lightning` → validate |
| | web dev assignment / "做网页作业" / HTML / CSS / JavaScript for course work | Read rubric → `EnterPlanMode` → `frontend-design` + `javascript-pro` → `/check-assignment` |
| | network lab / "配网络" / "做实验" / Packet Tracer / VLAN / OSPF / STP / subnetting | Read requirements → `EnterPlanMode` → configure → verify |
| | needs study notes / "帮我看课件" / "复习" / "总结" / "详细解析" / "备考" / exam prep | `EnterPlanMode` (reading plan) → read all materials → synthesize `Course Notes.md` or `详细解析.docx` |
| | asks about course content / "这个概念什么意思" / "解释一下" / "不懂" / "teach me" / "怎么做" | Read course notes first → explain with analogies (beginner-friendly per project CLAUDE.md) |
| | "帮我看看" / "改一下" / review partial work / "check my work" | Read work → compare against rubric/requirements → give feedback |
| | "检查作业" / "check assignment" / "帮我查" / wants rubric review | `/check-assignment` (read rubric → compare point by point) |
| | text sounds AI / Turnitin risk / "去AI痕迹" / "humanize" / "降重" — **academic context** (report / paper / thesis / assignment) | `humanizer_academic` (26 patterns, preserves technical terms, citations, data, academic tone) |
| | text sounds AI / "去AI痕迹" / "humanize" / "降重" — **non-academic context** (blog / email / marketing / general) | `humanizer` (rewrite to reduce AI fingerprint, keep meaning) |
| **Execution** | hits error / stack trace / test failure / "why is this broken" / "报错" / "出错了" / "跑不了" / "功能不对" | `systematic-debugging` |
| | says "review" / PR ready / wants code feedback / "评审代码" / "审一下" / "看下我的代码" / "PR好了" | `/code-review` (built-in) |
| | ready to commit / asks for commit message / "写commit" / "提交信息怎么写" / "commit message" | `conventional-commits` |
| | says "commit and push" / "push this" / "save my work" / "提交代码" / "推代码" | `git-pushing` |
| | asks for release notes / changelog / version bump / "更新日志" / "发布说明" / "版本变更" / "changelog" | `changelog-generator` |
| | feature complete / ready to merge branch / "功能做完了" / "合并分支" / "收尾分支" | `verification-before-completion` → `git-pushing` or `/git:pr` |
| | deploys to production / launch / release / "上线" / "发布" / "部署到生产" / "deploy to production" / "go live" | `shipping-and-launch` |
| | about to say "done" / mark task complete / "完成了" / "搞定了" / "标记完成" / "可以收工了" | `verification-before-completion` |
| | wants to refactor / "重构" / "帮我优化代码" / simplify complex code | refactor → `verification-before-completion` (use built-in `/simplify` for pure cleanups) |
| | "review the code" / code health check (no PR context) / "看看代码质量" / "代码健康度" / "体检一下" | `tech-debt-tracker` (scripted scan); if PR exists → `/code-review` |
| | needs isolated workspace for feature development / "隔离工作区" / "worktree" / "开个独立分支环境" | `using-git-worktrees` |
| **Writing** | writes blog / doc / copy (no rubric, non-academic) / "写博客" / "写文档" / "写文案" | Plan outline → write → self-review |
| | says "polish" / refine existing draft / "润色" / "改一下文章" | Review → revise → proofread |
| **Languages** | edits .py / uses pip / Django / Flask / pandas / "写Python" / "Python脚本" / "pip/Django/Flask/pandas" | `python-pro` |
| | edits .ts / TS generics / type errors / monorepo types / "写TypeScript" / "类型报错" / "TS泛型" / "类型不对" | `typescript-pro` |
| | edits .js / vanilla JS / Node.js without TS / "写JavaScript" / "原生JS" / "Node脚本" | `javascript-pro` |
| | writes SQL / slow query / schema design / indexing / "写SQL" / "查询慢" / "建索引" / "表结构设计" | `sql-pro` + `database-optimizer` |
| **Frontend** *(all build tasks MUST follow UI Design Protocol §3-step chain)* | builds any web page, Vue/React component, or UI (generic) / "做网页" / "写组件" / "做个页面" / "做UI" | `ui-ux-pro-max` → `frontend-design` → `critique` |
| | builds dashboard / admin panel / data tool / product UI / "做后台" / "管理面板" / "仪表盘" / "数据看板" | `ui-ux-pro-max` → `interface-design` → `critique` |
| | builds React/Next.js app with TypeScript, state, bundle concerns / "做React应用" / "Next项目" / "前端工程化" | `ui-ux-pro-max` → `frontend-design` + `frontend-patterns` → `critique` |
| | needs React/Next.js patterns — hooks, composition, data fetching / "React写法" / "hooks用法" / "数据获取模式" | `vercel-react-best-practices` + `vercel-composition-patterns` |
| | needs style direction only — design style, palette, font pairing / "选风格" / "配色方案" / "字体搭配" / "设计方向" | `ui-ux-pro-max` |
| | wants UI that looks like a specific brand — "像 Stripe/Notion/Linear", "苹果风格", named brand design system | `brand-design-md` (73 brands) |
| | anti-slop pass for landing pages/portfolios — variance/motion/density dials, GSAP skeletons / "去模板感" / "别太AI味" | `taste-skill` (heavy SKILL.md ~22k tokens — invoke deliberately) |
| | configures Tailwind / design tokens / theme CSS / "配Tailwind" / "主题配置" / "设计token" | `tailwind-theme-builder` → `shadcn-ui` |
| | needs brand palette from a hex / Tailwind color tokens / WCAG / "品牌配色" / "调色板" / "颜色token" / "对比度" | `color-palette` |
| | works with Next.js / app router / SSR / server actions / "Next.js" / "做SSR" / "服务端渲染" / "server action" | `nextjs-pro` |
| | builds React Native / Expo mobile app / "做App" / "React Native" / "Expo" / "做手机应用" | `vercel-react-native-skills` + `ui-ux-pro-max` |
| | checking mobile display / responsiveness issues / "手机显示" / "响应式检查" / "适配有问题" | `responsiveness-check` + `adapt` |
| | running a live UX walkthrough / QA sweep in browser / "UX走查" / "体验检查" / "浏览器里过一遍" | `ux-audit` |
| | needs poster / static visual design / art / "做海报" / "做配图" / "静态视觉" / "做张图" | `canvas-design` |
| | needs favicon / apple-touch-icon / PWA icons / "做favicon" / "网站图标" / "PWA图标" | `favicon-gen` |
| | needs custom SVG icon set for a project / "做图标集" / "定制图标" / "项目图标库" | `icon-set-generator` |
| | resizes / crops / converts / optimizes images / "改图片" / "压缩图片" / "裁剪" / "转格式" | `image-processing` |
| | creating a claude.ai HTML artifact (not project files) / "做HTML artifact" / "claude.ai页面" | `web-artifacts-builder` |
| **UI Refinement** (impeccable) | "太丑了" / full visual overhaul / "重做设计" — scope is major redesign | `critique` → assess scope → `ui-ux-pro-max` → `frontend-design` → `critique` |
| | upgrading an existing site/app to premium quality — audits generic AI patterns, full redesign protocol / "整站升级" / "全面重设计" | `redesign-skill` |
| | checks UI quality / WCAG / "what's wrong" / responsiveness / "这个UI有什么问题" / "检查一下UI" | `audit` |
| | reviewing design / visual hierarchy / UX feedback / "帮我看看设计" / "设计评审" | `critique` |
| | final pass before shipping / spacing / alignment / "最后润色" / "上线前检查" / "微调一下" | `polish` |
| | design too safe / generic / boring / needs more impact / "太平了" / "没特色" / "太普通" | `bolder` |
| | design too loud / aggressive / cluttered / "太花了" / "太吵了" / "太花哨" | `quieter` |
| | UI too gray / colorless / monotone / "太灰了" / "没颜色" / "加点颜色" | `colorize` |
| | adding hover effects / transitions / micro-interactions / "加动效" / "加动画" | `animate` (quick pass) or `emil-design-eng` (component motion decisions, taste-level polish) |
| | animation audit across whole codebase / motion roadmap / "动效审计" / "整体动效体检" | `improve-animations` |
| | UI cluttered / over-designed / needs simplification / "太复杂了" / "简化一下" / "精简" | `distill` |
| | needs error states / i18n / loading states / edge cases / "加兜底" / "加载状态" / "异常处理" | `harden` |
| | component inconsistent / doesn't match design system / "风格不统一" / "不一致" | `normalize` |
| | extracting reusable components / deduplicating UI patterns / "提取组件" / "复用" / "抽组件" | `extract` |
| | UI copy unclear / button labels / error messages confusing / "文案不清楚" / "提示语优化" / "看不懂" | `clarify` |
| | UI functional but cold / needs personality / delight / "太冷了" / "没灵魂" / "加点趣味" | `delight` |
| | empty states / first-run experience / onboarding flows / "引导页" / "新手引导" / "空状态设计" | `onboard` |
| | UI loads slowly / animations stutter / bundle too large / "加载慢" / "卡顿" / "性能优化" | `optimize` |
| | adapting UI for mobile / tablet / cross-platform / "手机适配" / "响应式" / "多端适配" | `adapt` |
| **Data** *(CEO gate: if 3+ steps, plan first)* | analyzes a standalone CSV / data file **outside any course (no rubric)** / "分析数据" / "看看这个数据" | CEO planning → `csv-data-summarizer` |
| | needs interactive charts (hover/zoom) / "做个可交互的图" | `plotly` / `claude-d3js` |
| | needs static publication figures / "画个图" / "做图表" | `matplotlib` / `seaborn` |
| | trains models / ML pipeline / statistics / "训练模型" | `scikit-learn` + `statsmodels` + `pytorch-lightning` |
| | analyzes networks / graph relationships / "图分析" / "关系网络" / "图算法" / "节点关系" | `networkx` |
| **Documents** *(CEO gate: if 3+ steps, plan first)* | reads/creates PDF / Word / Excel / PPT / "读PDF" / "做Word" / "做Excel" | For read-only: `pdf` · `docx` · `xlsx` · `pptx` directly. For creation (3+ steps): CEO planning → skill |
| | creates slide deck / presentation / "做PPT" / "做幻灯片" | CEO planning (outline) → `revealjs` · `pptx` |
| **Quality** | asks "how good is this code" / wants codebase health check / "代码质量怎么样" | `tech-debt-tracker` |
| | ongoing tech debt tracking / cleanup sprint planning / "技术债务跟踪" / "清理计划" / "债务评分" | `tech-debt-tracker` |
| | asks for security audit / reviews for vulnerabilities / "安全审计" | `trailofbits-audit` or `/security-review` (built-in) |
| | auditing a third-party skill for malicious code / "审计skill安全性" | `skill-security-auditor` |
| | reviewing a PR/MR and wants more than style nits (blast radius, security, breaking changes) / "深度PR评审" / "影响面分析" / "破坏性变更" | `/code-review` (built-in, high effort) |
| | code is slow / page loads sluggishly / "why is this slow" / "为什么这么慢" (app-level) | `performance-profiler` |
| | slow query / query optimization / "查询太慢" (DB-level) | `database-optimizer` + `sql-pro` |
| | checking dependencies for vulnerabilities / license compliance / outdated packages / "检查依赖" | `dependency-auditor` |
| | writes tests / adds tests to existing code / coverage gaps / "写个测试" / "跑测试" / "跑一下测试" / "生成测试" / "测试覆盖率" | `test-driven-development` |
| | Playwright E2E tests / fixing flaky tests / migrating from Cypress / "Playwright测试" / "E2E测试" | `webapp-testing` + pw plugin (`/pw:generate`, `/pw:fix`) |
| | implementing new feature/bugfix via TDD (test-first) / "先写测试" | `test-driven-development` |
| | generates API integration tests / contract tests / "API测试" / "接口测试" | `api-test-suite-builder` |
| | tests web app in browser / screenshots / clicks / "浏览器测试" / "页面截图测试" / "点击测试" | `webapp-testing` |
| | runs automated accessibility scan / axe-core / WCAG compliance / "无障碍检测" | `claude-a11y` |
| **Engineering** | designs REST API backend / microservices / auth flows / "写API" / "后端开发" / "微服务" | language skill directly (`python-pro` / `typescript-pro`); tests via `api-test-suite-builder` |
| | system design interviews / architecture diagrams / tech stack comparison / "架构图" / "技术选型" / "画架构" | Software Architect agent |
| | designs ERD / normalizes database schemas / table relationships / "设计数据库" / "ERD" / "建表" / "数据库设计" | `database-schema-designer` |
| | plans zero-downtime migrations / version upgrades / rollback / "数据迁移" / "系统迁移" / "升级方案" | `migration-architect` |
| | deploys ML models to production / MLOps / MLflow / feature stores / "部署模型" / "MLOps" / "模型上线" | AI Engineer agent + `huggingface-llm-trainer` |
| | statistical modeling / A/B testing / causal inference / experiment design / "统计建模" / "AB测试" / "因果分析" | `statsmodels` + `scikit-learn` |
| | autonomous optimization loop / measurable metric improvement / "自动优化" / "实验循环" | `autoresearch-agent` |
| | production prompt engineering / LLM evaluation / structured output / "优化prompt系统" / "评估LLM输出" | `prompt-architect` |
| **DevOps** | writes CI/CD pipeline configs / GitHub Actions / deployment automation / "写CI/CD" / "写流水线" / "配置Actions" / "部署" | `ci-cd-and-automation` |
| | builds MCP server / tool integration / "做MCP" / "MCP服务器" / "工具集成" | `mcp-builder` |
| **Product & Business** | business model / pricing / customer diagnosis / 自媒体 content (选题/小红书标题/短视频开头/共鸣) / action blockers / "生意问题" / "定价" / "客户嫌贵" / "选题" / "拖延" | NOT INSTALLED — per user rule, recommend 洞哥's dbskill first: `claude plugin marketplace add dontbesilent2025/dbskill` + `claude plugin install dbs@dontbesilent-skills` (see memory/dontbesilent-dbskill.md) |
| | sprint planning / velocity tracking / retrospectives / "Sprint规划" / "敏捷" / "站会" / "迭代" | `scrum-master` |
| | financial ratio analysis / DCF valuation / budget variance / "财务分析" / "DCF" / "估值" / "预算" | `financial-analyst` |
| **Research** | asks about recent trends / last 30 days / "最近有什么趋势" | `last30days` |
| | scrapes a webpage / crawls docs / real-time web search with full content / "抓网页" / "爬数据" / "抓取网站" | `firecrawl` (requires FIRECRAWL_API_KEY) |
| | designing or improving a prompt / system message / "写prompt" / "优化提示词" | `prompt-architect` |
| | creating a skill from scratch with evals / benchmarks / "做个skill" / "创建技能" / "从零写skill" | `skill-creator` |
| | writing or editing a skill SKILL.md file / "写SKILL.md" / "编辑skill" / "改技能" | `skill-creator` |
| | completes non-trivial debugging / wants to extract reusable knowledge / "提取经验" / "总结教训" / "记录踩坑" | `claudeception` |
| **Apple** *(Swift/SwiftUI skill family removed 2026-07-14 — reinstall if native iOS/macOS work resumes)* | Apple HIG-compliant UI / SF Symbols / iOS-macOS native design / "苹果设计规范" / "HIG" | `apple-hig-designer` |
| **DuckDB** | queries data files with SQL / ad-hoc analysis / "用SQL查数据文件" | `duckdb-query` |
| | attaches a DuckDB database file / explores schema / "挂载数据库" | `duckdb-attach-db` |
| | converts data file format (CSV↔Parquet↔JSON↔Excel) / "转parquet" / "导出xlsx" | `duckdb-convert-file` |
| | installs/updates DuckDB extensions / "装DuckDB扩展" / "更新扩展" | `install-duckdb` |
| **HuggingFace / Embeddings** | "best model for X" / recommends or compares models by benchmark / "推荐模型" | `huggingface-best` |
| | HF Dataset Viewer API — fetch rows, search, filter, parquet URLs / "HF数据集" | `huggingface-datasets` |
| | trains/fine-tunes LLM via TRL/Unsloth on HF Jobs / GGUF convert / "微调大模型" | `huggingface-llm-trainer` |
| | trains/fine-tunes sentence-transformers / embedding / reranker models / "训练嵌入模型" | `train-sentence-transformers` |
| **More Quality / Exec** | reduce common LLM coding mistakes / surgical changes / "避免过度设计" | `karpathy-guidelines` |
| | ultra-granular line-by-line context building before security/arch audit / "深度审计准备" / "逐行分析" / "审计前建上下文" | `trailofbits-audit` |
| | secure web app coding / security scan & best practices / "安全编码" | `/security-review` (built-in) |

