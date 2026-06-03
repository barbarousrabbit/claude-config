---
description: Stage, commit, and push the current branch following git governance rules.
---

1. Run `/review` (and `/security-scan` if the change touches anything sensitive) to ensure local checks pass.
2. Review and stage changes with `git add` (avoid staging generated or secret files).
3. Craft a Conventional Commit message (types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert).
   - Include Context / Testing inline if useful.
   - Never add AI attribution strings to commits.
4. Commit with `git commit` using the prepared message.
5. Push to origin: `git push origin $(git branch --show-current)` (for the `~/.claude` config repo this is effectively `git push origin HEAD:main`).
