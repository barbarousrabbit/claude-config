---
name: codebase-onboarding
description: Use when joining an unfamiliar codebase or onboarding a teammate — architecture overview, key file map, setup guide.
user-invocable: true
---

# Codebase Onboarding

Analyze a codebase → generate audience-aware onboarding docs (architecture, key files, setup guide, contribution runbook).

**Audience modes:** junior · senior · contractor

---

## Step 1 — Gather Facts

Use cross-platform commands (work on Windows, macOS, Linux):

```bash
# Stack overview (cross-platform: use node instead of jq)
node -e "const p=require('./package.json'); console.log(JSON.stringify({name:p.name,version:p.version,scripts:p.scripts,dependencies:Object.keys(p.dependencies||{})},null,2))"

# Directory structure (top 2 levels) — use npx or built-in tools
# On macOS/Linux:
find . -maxdepth 2 -not -path '*/node_modules/*' -not -path '*/.git/*' | sort | head -60
# On Windows (PowerShell):
Get-ChildItem -Recurse -Depth 1 -Exclude node_modules,.git | Select-Object -First 60

# Largest source files (often core modules)
# On macOS/Linux:
find src/ -name "*.ts" -not -path "*/test*" -exec wc -l {} + | sort -rn | head -20
# On Windows (PowerShell):
Get-ChildItem -Path src -Recurse -Filter "*.ts" | Where-Object { $_.FullName -notmatch 'test' } | ForEach-Object { [PSCustomObject]@{Lines=(Get-Content $_.FullName | Measure-Object -Line).Lines; File=$_.FullName} } | Sort-Object Lines -Descending | Select-Object -First 20

# Routes (Next.js App Router) — works cross-platform via glob tools
# Use the Glob tool: pattern "app/**/route.ts" and "app/**/page.tsx"

# Recent major changes (git works cross-platform)
git log --oneline --since="90 days ago" | grep -E "feat|refactor|breaking"

# Top contributors (git works cross-platform)
git shortlog -sn --no-merges | head -10
```

**Tip:** When running in Claude Code, prefer using the Glob tool (for file search) and Read tool (for file contents) over shell commands — they work identically on all platforms.

---

## Step 2 — Generate Docs

Produce these sections (full templates in `references/onboarding-template.md`):

### Architecture Overview
```
[System diagram: Browser → App → DB/Cache/Queue → External APIs]
Tech stack table: Layer | Technology | Why
```

### Key Files Map
| Path | Purpose |
|------|---------|
| `src/db/schema.ts` | **Single source of truth for DB models** |
| `src/lib/auth.ts` | **Auth config — read this first** |
| `.env.example` | All env vars with descriptions |
| `docker-compose.yml` | Local infrastructure |

### Setup Guide (target: <10 minutes)
```bash
git clone ... && cd repo
pnpm install
docker compose up -d        # Postgres, Redis
cp .env.example .env        # Fill in values
pnpm db:migrate && pnpm dev # → http://localhost:3000
```

Checklist: app loads · /api/health returns `{"status":"ok"}` · tests pass

### Common Tasks Runbook
- Add API endpoint
- Run DB migration
- Add background job
- Add email template

Full runbook: `references/onboarding-template.md`

---

## Step 3 — Audience-Specific Notes

**Junior:** Start with tests — they document expected behavior. Ask before touching schema files.

**Senior:** Check `docs/adr/` for architecture decisions. Review `docs/scaling.md`.

**Contractor:** Scope = `src/features/[your-feature]/`. Never push to main. Use `src/lib/` wrappers for external APIs.

---

## Output Format Options

- **Markdown** (default) — paste into PR, wiki, or README
- **Notion** — use notion-to-md to create blocks
- **Confluence** — POST to REST API (see `references/onboarding-template.md`)

---

## Common Pitfalls

- Docs written once, never updated → add doc update to PR checklist
- Missing error troubleshooting → most valuable section for new hires
- No "why" — document decisions, not just what exists
