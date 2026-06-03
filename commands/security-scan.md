---
description: Run the security scan gate before pushing.
---

1. Ensure gitleaks is available (Windows: `winget install gitleaks` or `scoop install gitleaks`, or download the release binary). Gate the scan behind availability:
   ```bash
   command -v gitleaks >/dev/null || { echo "gitleaks not installed — install via winget/scoop, then re-run"; exit 0; }
   ```
2. Scan for committed secrets:
   ```bash
   gitleaks detect --source "$HOME/.claude" --verbose --redact
   ```
   - Resolve any findings before continuing. Note: `.mcp.json`, `.credentials.json`, and `settings.local.json` are git-ignored, so a token living there is not committed — but rotate anything that has leaked into git history.
3. Optional — audit Python deps only if you maintain first-party `requirements*.txt` (the repo's `skills/` and `plugins/` are vendored; do NOT audit those):
   ```bash
   command -v safety >/dev/null && find "$HOME/.claude" -maxdepth 2 -name "requirements*.txt" -not -path "*/skills/*" -not -path "*/plugins/*" -exec safety check --full-report --file {} \; || echo "no first-party requirements / safety not installed"
   ```
4. Record results inline. After a clean pass, proceed with the commit/push workflow.
