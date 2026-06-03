---
description: Run the local review gate before pushing ~/.claude config changes.
---

Review pass for this `~/.claude` config repo (Windows host):

1. Confirm the working tree has only intentional changes: `git -C ~/.claude status --short`.
2. Validate JSON configs are well-formed:
   ```bash
   for f in settings.json settings.local.json .mcp.json plugins/*.json; do
     python -c "import json,sys; json.load(open(sys.argv[1]))" "$HOME/.claude/$f" && echo "OK $f" || echo "BAD $f"
   done
   ```
3. Lint shell hooks/scripts (if shellcheck is available):
   ```bash
   command -v shellcheck >/dev/null && shellcheck "$HOME"/.claude/scripts/*.sh || echo "shellcheck not installed — skipping"
   ```
4. Markdown sanity on key docs (if markdown-link-check is available):
   ```bash
   command -v markdown-link-check >/dev/null && markdown-link-check "$HOME/.claude/CLAUDE.md" || echo "markdown-link-check not installed — skipping"
   ```
5. Summarize results inline. Fix any failures before committing.
