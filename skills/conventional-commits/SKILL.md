---
name: conventional-commits
description: Use when creating git commits or writing commit messages — enforces Conventional Commits spec.
---

# Conventional Commits

Write structured, semantic commit messages following the Conventional Commits 1.0.0 specification.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | When to Use |
|------|------------|
| `feat` | New feature for the user |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, semicolons (no code change) |
| `refactor` | Code change that neither fixes nor adds |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `build` | Build system, dependencies (npm, pip) |
| `ci` | CI/CD configuration |
| `chore` | Maintenance tasks |
| `revert` | Reverting a previous commit |

## Rules
1. ALWAYS use lowercase type
2. ALWAYS keep description under 72 characters
3. ALWAYS use imperative mood ("add" not "added")
4. Use scope to specify the affected module: `feat(auth): add login flow`
5. Add `BREAKING CHANGE:` footer or `!` after type for breaking changes
6. Body explains WHY, not WHAT (the diff shows what)

## Examples
- `feat(cart): add quantity selector to product page`
- `fix(api): handle null response from payment gateway`
- `docs: update installation guide for Windows`
- `refactor!: drop support for Node 16`
