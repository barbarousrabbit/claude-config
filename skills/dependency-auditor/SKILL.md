---
name: dependency-auditor
description: Use when checking dependencies for vulnerabilities, license issues, outdated packages, or bloat.
---

# Dependency Auditor

Multi-language dependency audit: vulnerabilities · license compliance · outdated packages · bloat.

**Supported:** npm/yarn · pip/poetry · go.mod · Cargo · Gemfile · pom.xml · composer

---

## Quick Audit Commands

### Security Vulnerabilities
```bash
# Node.js
npm audit --audit-level=high
npx audit-ci --high

# Python
pip-audit                          # pip install pip-audit
safety check -r requirements.txt   # pip install safety

# Go
govulncheck ./...                  # go install golang.org/x/vuln/cmd/govulncheck@latest

# Rust
cargo audit                        # cargo install cargo-audit
```

### License Compliance
```bash
# Node.js — list all licenses
npx license-checker --summary
npx license-checker --failOn "GPL-2.0;GPL-3.0;AGPL-3.0"  # block copyleft

# Python
pip-licenses --format=markdown

# Go
go-licenses check ./...            # github.com/google/go-licenses
```

### Outdated Packages
```bash
npm outdated                       # shows current/wanted/latest
npx npm-check-updates             # shows upgradeable deps

pip list --outdated
poetry show --outdated

go list -u -m all                  # Go modules

cargo outdated                     # cargo install cargo-outdated
```

### Unused Dependencies
```bash
npx depcheck                       # Node.js unused deps
pip-autoremove --list              # Python unused

# Find imports vs package.json discrepancies
grep -r "^import\|^from\|require(" src/ | grep -oE "'[^']+'" | sort -u
```

---

## Risk Classification

| Update Type | Risk | Action |
|-------------|------|--------|
| Patch (x.y.Z) | Low | Apply immediately |
| Minor (x.Y.z) | Medium | Review changelog, test |
| Major (X.y.z) | High | Plan migration sprint |
| CVE critical | CRITICAL | Block deploy, patch now |

**License risk:** GPL/AGPL in commercial project → legal review required

---

## Output Format

```
## Dependency Audit: [project] @ [date]

CRITICAL: 2 high-severity CVEs
  - lodash@4.17.15: CVE-2021-23337 (prototype pollution) → upgrade to 4.17.21
  - axios@0.21.0:   CVE-2021-3749  (ReDoS)              → upgrade to 0.21.2

LICENSE: 1 concern
  - some-pkg@1.0: GPL-3.0 — incompatible with commercial distribution

OUTDATED: 8 packages (2 major, 6 minor/patch)
  Major (needs attention): react 17 → 18, webpack 4 → 5
  Patch (safe): lodash, axios (see above), 4 others

UNUSED: 3 packages not imported: left-pad, moment, uuid
```

Full scan scripts: `scripts/dep_scanner.py` · `scripts/license_checker.py` · `scripts/upgrade_planner.py`
