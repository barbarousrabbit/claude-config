---
description: Create a pull request from the current branch.
argument-hint: [target-branch]
---

## Variables

TARGET_BRANCH: $1 (defaults to `main`)
SOURCE_BRANCH: current branch (`git branch --show-current`)

## Workflow

1. Run `/review` (and `/security-scan` if relevant) locally first.
2. Push the branch if it isn't pushed yet: `git push -u origin "$SOURCE_BRANCH"`.
3. Create the PR with GitHub CLI, writing the body inline (no template file assumed):
   ```bash
   gh pr create \
     --base "$TARGET_BRANCH" \
     --head "$SOURCE_BRANCH" \
     --title "<Conventional PR title>" \
     --body "## Summary
   <what changed and why>

   ## Testing
   <how it was verified>"
   ```
4. Share the PR link with reviewers.
