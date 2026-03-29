# Security Patterns for PR Review

## Secrets & Credentials
```bash
grep -nE "(password|secret|api_key|token|private_key)\s*=\s*['\"][^'\"]{8,}" $DIFF
grep -nE "AKIA[0-9A-Z]{16}" $DIFF                    # AWS access keys
grep -nE "ghp_[A-Za-z0-9]{36}" $DIFF                  # GitHub PATs
grep -nE "sk-[A-Za-z0-9]{48}" $DIFF                   # OpenAI keys
grep -nE "Bearer\s+[A-Za-z0-9\-._~+/]+=*" $DIFF      # Bearer tokens
grep -nE "-----BEGIN (RSA |EC )?PRIVATE KEY" $DIFF     # Private keys
grep -nE "mongodb(\+srv)?://[^@]+@" $DIFF              # DB connection strings with creds
```

## Injection Vulnerabilities
```bash
# XSS
grep -n "dangerouslySetInnerHTML\|innerHTML\s*=\|\.html(" $DIFF | grep "^+"
grep -n "document\.write\|document\.writeln" $DIFF | grep "^+"

# SQL Injection
grep -nE "f['\"].*SELECT|f['\"].*INSERT|f['\"].*UPDATE|f['\"].*DELETE" $DIFF | grep "^+"
grep -nE "\$\{.*\}.*FROM|string\.Format.*WHERE" $DIFF | grep "^+"

# Command Injection
grep -nE "\beval\(|\bexec\(|child_process|subprocess\.(call|run|Popen)" $DIFF | grep "^+"
grep -nE "os\.system\(|os\.popen\(" $DIFF | grep "^+"

# Path Traversal
grep -nE "path\.join\(.*req\.|readFile\(.*req\.|\.\./" $DIFF | grep "^+"
grep -nE "open\(.*request\.|fs\.(read|write).*req\." $DIFF | grep "^+"
```

## Authentication & Authorization
```bash
grep -n "bypass\|skip.*auth\|noauth\|TODO.*auth" $DIFF | grep "^+"
grep -n "@public\|@no.auth\|isAuthenticated.*false" $DIFF | grep "^+"
grep -nE "role.*=.*['\"]admin['\"]|isAdmin.*true" $DIFF | grep "^+"  # Hardcoded roles
grep -n "jwt\.decode.*verify.*false\|verify=False" $DIFF | grep "^+"  # JWT skip verify
```

## Cryptography
```bash
grep -nE "md5|sha1[^0-9]" $DIFF | grep "^+"          # Weak hashing
grep -nE "DES|RC4|ECB" $DIFF | grep "^+"              # Weak ciphers
grep -n "Math\.random\|random\.random" $DIFF | grep "^+"  # Non-crypto random
```

## Data Exposure
```bash
grep -nE "console\.(log|debug|info).*password|console\.(log|debug|info).*token" $DIFF | grep "^+"
grep -nE "JSON\.stringify.*user|\.toJSON\(\)" $DIFF | grep "^+"  # Full object serialization
grep -n "CORS.*\*\|Access-Control-Allow-Origin.*\*" $DIFF | grep "^+"  # Open CORS
```

## Severity Classification
| Pattern | Severity |
|---------|----------|
| Hardcoded secrets/keys | CRITICAL |
| SQL/command injection | CRITICAL |
| Auth bypass | CRITICAL |
| XSS (stored) | HIGH |
| Path traversal | HIGH |
| Weak crypto | MEDIUM |
| Open CORS | MEDIUM |
| Debug logging with sensitive data | LOW |
