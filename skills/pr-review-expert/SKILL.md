---
name: pr-review-expert
description: Use when reviewing a PR/MR beyond style nits — blast radius, security, breaking changes, coverage delta.
---

# PR Review Expert

Structured PR/MR review: blast radius → security → coverage → breaking changes → output report.

---

## Step 1 — Fetch Context

```bash
PR=123
gh pr view $PR --json title,body,labels,milestone,assignees | jq .
gh pr diff $PR --name-only
gh pr diff $PR > /tmp/pr-$PR.diff
```

## Step 2 — Blast Radius

```bash
# Who imports changed modules?
grep -r "from ['\"].*changed-module['\"]" src/ --include="*.ts" -l
# Cross-service? (monorepo)
gh pr diff $PR --name-only | cut -d/ -f1-2 | sort -u
# Shared contracts?
gh pr diff $PR --name-only | grep -E "types/|interfaces/|schemas/|models/"
```

**Severity:** CRITICAL=shared lib/auth/API contract · HIGH=used by >3 services · MEDIUM=single service · LOW=UI/tests

## Step 3 — Security Scan

```bash
DIFF=/tmp/pr-$PR.diff
grep -nE "(password|secret|api_key|token)\s*=\s*['\"][^'\"]{8,}" $DIFF  # hardcoded secrets
grep -nE "AKIA[0-9A-Z]{16}" $DIFF                                        # AWS keys
grep -n "dangerouslySetInnerHTML\|innerHTML\s*=" $DIFF                   # XSS
grep -nE "\beval\(|\bexec\(" $DIFF                                       # code injection
grep -n "bypass\|skip.*auth\|noauth\|TODO.*auth" $DIFF                   # auth bypass
grep -nE "path\.join\(.*req\.|readFile\(.*req\." $DIFF                   # path traversal
```

Full pattern list: `references/security-patterns.md`

## Step 4 — Test Coverage Delta

```bash
CHANGED_SRC=$(gh pr diff $PR --name-only | grep -vE "\.test\.|\.spec\.|__tests__")
CHANGED_TESTS=$(gh pr diff $PR --name-only | grep -E "\.test\.|\.spec\.|__tests__")
echo "Source: $(echo "$CHANGED_SRC" | wc -w) | Tests: $(echo "$CHANGED_TESTS" | wc -w)"
```

Flag: new function without tests · coverage drop >5% · auth/payments paths need 100%

## Step 5 — Breaking Changes

```bash
# API route removals
grep "^-" $DIFF | grep -E "router\.(get|post|put|delete|patch)\("
# TypeScript interface removals
grep "^-" $DIFF | grep -E "^-\s*(export\s+)?(interface|type) "
# DB destructive ops
grep -E "DROP TABLE|DROP COLUMN|ALTER.*NOT NULL|TRUNCATE" $DIFF
# New/removed env vars
grep "^+" $DIFF | grep -oE "process\.env\.[A-Z_]+" | sort -u
grep "^-" $DIFF | grep -oE "process\.env\.[A-Z_]+" | sort -u
```

## Step 6 — Performance Impact

```bash
grep -n "\.find\|\.findOne\|\.query\|db\." $DIFF | grep "^+" | head -20  # N+1
grep "^+" $DIFF | grep -E '"[a-z@].*":\s*"[0-9^~]' | head -20           # heavy deps
grep -n "while (true\|while(true" $DIFF | grep "^+"                      # infinite loops
```

---

## Output Format

```
## PR Review: [Title] (#NUMBER)

Blast Radius: HIGH — changes lib/auth used by 5 services
Security: 1 finding (medium)
Tests: Coverage delta +2%
Breaking Changes: None detected

--- MUST FIX (Blocking) ---
1. [file:line] [issue] → [fix]

--- SHOULD FIX (Non-blocking) ---
2. [issue]

--- SUGGESTIONS ---
3. [optimization opportunity]

--- LOOKS GOOD ---
- [positive callout]
```

Full review checklist (30+ items): `references/review-checklist.md`
