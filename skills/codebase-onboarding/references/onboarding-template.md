# Onboarding Document Template

## 1. Architecture Overview

```
[Title]: {Project Name} Architecture
[Updated]: {Date}

System Diagram:
  Browser/Client
       |
  [Load Balancer / CDN]
       |
  [App Server (framework)]
       |
  +---------+---------+
  |         |         |
 [DB]    [Cache]   [Queue]
  |                   |
  [External APIs]   [Workers]
```

### Tech Stack Table

| Layer | Technology | Version | Why Chosen |
|-------|-----------|---------|------------|
| Frontend | {React/Vue/etc.} | {ver} | {rationale} |
| Backend | {Express/Next/etc.} | {ver} | {rationale} |
| Database | {PostgreSQL/etc.} | {ver} | {rationale} |
| Cache | {Redis/etc.} | {ver} | {rationale} |
| Queue | {BullMQ/etc.} | {ver} | {rationale} |
| CI/CD | {GitHub Actions/etc.} | - | {rationale} |

### Data Flow

1. Request arrives at {entry point}
2. Middleware chain: {auth → validation → rate-limit}
3. Route handler calls service layer
4. Service interacts with {DB/cache/external API}
5. Response formatted and returned

---

## 2. Key Files Map

| Path | Purpose | Read When |
|------|---------|-----------|
| `src/db/schema.ts` | DB models — single source of truth | Before any DB work |
| `src/lib/auth.ts` | Auth configuration | Before touching auth |
| `.env.example` | All env vars with descriptions | First setup |
| `docker-compose.yml` | Local infrastructure | First setup |
| `src/middleware/` | Request pipeline | Adding middleware |
| `src/lib/errors.ts` | Error handling patterns | Writing error responses |
| `tests/fixtures/` | Test data setup | Writing tests |

---

## 3. Setup Guide

### Prerequisites
- Node.js {version}
- Docker Desktop
- {package manager: pnpm/npm/yarn}

### Steps (target: <10 min)

```bash
# 1. Clone and install
git clone {repo-url} && cd {repo-name}
{pm} install

# 2. Start infrastructure
docker compose up -d

# 3. Configure environment
cp .env.example .env
# Fill in: DATABASE_URL, REDIS_URL, API_KEY (see .env.example comments)

# 4. Initialize database
{pm} db:migrate
{pm} db:seed          # Optional: sample data

# 5. Start dev server
{pm} dev              # → http://localhost:{port}
```

### Verification Checklist
- [ ] App loads at http://localhost:{port}
- [ ] `/api/health` returns `{"status":"ok"}`
- [ ] `{pm} test` passes
- [ ] Can log in with seed user (if applicable)

### Common Setup Issues

| Problem | Fix |
|---------|-----|
| Port {port} in use | `lsof -i :{port}` → kill process or change PORT in .env |
| DB connection refused | Ensure `docker compose up -d` completed; check `docker ps` |
| Missing env var | Compare .env against .env.example |
| Node version mismatch | Use `nvm use` (check .nvmrc) |

---

## 4. Common Tasks Runbook

### Add an API Endpoint
1. Create route file: `src/app/api/{resource}/route.ts`
2. Add service logic: `src/services/{resource}.ts`
3. Add DB query: `src/db/queries/{resource}.ts`
4. Add tests: `tests/api/{resource}.test.ts`
5. Update OpenAPI spec (if applicable)

### Run a Database Migration
```bash
{pm} db:generate       # Generate migration from schema changes
{pm} db:migrate        # Apply to local DB
{pm} db:migrate:prod   # Apply to production (CI/CD only)
```

### Add a Background Job
1. Define job: `src/jobs/{job-name}.ts`
2. Register in queue: `src/lib/queue.ts`
3. Add worker handler: `src/workers/{job-name}.ts`
4. Test: `tests/jobs/{job-name}.test.ts`

### Deploy
1. Push to `main` (auto-deploys to staging)
2. Verify on staging
3. Create release tag → deploys to production

---

## 5. Audience-Specific Notes

### For Junior Developers
- Start by reading tests — they document expected behavior
- Ask before touching schema or migration files
- Use `src/lib/` wrappers; never call external APIs directly
- Every PR needs tests

### For Senior Engineers
- Check `docs/adr/` for architecture decisions and rationale
- Review `docs/scaling.md` for known bottlenecks
- Performance budget: {X}ms p99 latency, {Y}MB memory
- Auth flow documented in `docs/auth-flow.md`

### For Contractors
- Your scope: `src/features/{your-feature}/`
- Never push to main — use feature branches
- Use `src/lib/` wrappers for external APIs
- Follow existing patterns in adjacent features

---

## 6. Confluence / Notion Export Notes

### Confluence REST API
```bash
curl -X POST "https://{domain}.atlassian.net/wiki/rest/api/content" \
  -H "Authorization: Basic {base64(email:api-token)}" \
  -H "Content-Type: application/json" \
  -d '{"type":"page","title":"Onboarding: {Project}","space":{"key":"{SPACE}"},"body":{"storage":{"value":"{html}","representation":"storage"}}}'
```

### Notion
Use `notion-to-md` or the Notion API to create blocks from this markdown.
