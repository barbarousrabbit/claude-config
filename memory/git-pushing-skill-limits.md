# git-pushing skill: scope limits

## smart_commit.sh cannot make the FIRST commit of a new repo

`skills/git-pushing/scripts/smart_commit.sh` dies immediately on a freshly
`git init`-ed repo:

```
fatal: ambiguous argument 'HEAD': unknown revision or path not in the working tree
```

**Why:** line 19 is `CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)` under
`set -e`. On an unborn HEAD (no commits yet) that command exits 128, and a
failing command substitution inside an assignment aborts the whole script.

**Where it fails is safe:** line 19 runs before any staging, commit, or push,
so a failed run leaves the working tree untouched. No cleanup needed.

**How to apply:** the skill covers *incremental* pushes to an existing repo with
an `origin` remote. For a brand-new repo do the bootstrap by hand, then hand off
to the script for every later push:

```bash
git init -b main
# write .gitignore / .gitattributes first
git add -A && git status --short          # review before committing
gh repo create <name> --private --description "..."
git remote add origin https://github.com/<user>/<name>.git
git commit -F -  <<'EOF'
...message...
EOF
git push -u origin main
```

**Optional one-line fix** (not applied — would change a shared skill script):
`CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || git branch --show-current)`.

Related: [[config-portability-audit]] (gitignore only affects untracked paths —
a nested clone must be ignored *before* the first `git add`).
