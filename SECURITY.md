# Security Policy

This document outlines security practices and policies for the err0.io Open Source Test Bundle.

## Table of Contents

1. [Reporting Security Issues](#reporting-security-issues)
2. [Security Best Practices](#security-best-practices)
3. [Token Management](#token-management)
4. [Pre-Commit Security Checks](#pre-commit-security-checks)
5. [Incident Response](#incident-response)
6. [Security Updates](#security-updates)

---

## Reporting Security Issues

### ⚠️ DO NOT Open Public Issues for Security Vulnerabilities

If you discover a security vulnerability, please report it privately.

### Reporting Process

**Contact:** security@err0.io

**Include in your report:**
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if applicable)
- Your contact information

**Response timeline:**
- **Initial response:** Within 48 hours
- **Status update:** Within 7 days
- **Fix timeline:** Varies by severity (see below)

### Severity Levels

| Severity | Impact | Response Time |
|----------|--------|---------------|
| **Critical** | Authentication bypass, token exposure | 24-48 hours |
| **High** | Data exposure, privilege escalation | 7 days |
| **Medium** | Information disclosure, DoS | 30 days |
| **Low** | Minor information leak | 90 days |

---

## Security Best Practices

### 1. Token Security

#### What Should NEVER Be Committed

❌ **NEVER commit these to version control:**
- Token JSON files (`*.json` in `tokens/` or `dev-localhost/`)
- Environment files with secrets (`.env`, `.env.local`)
- API keys or passwords
- Private keys or certificates
- Database credentials

#### What CAN Be Committed

✅ **Safe to commit:**
- `.env.template` (template without real values)
- Documentation about tokens (`tokens/README.md`)
- Token file structure examples (with fake/placeholder values)
- Scripts and configuration

### 2. Environment Security

#### Secure Your .env File

```bash
# Set restrictive permissions
chmod 600 .env

# Verify ownership
ls -la .env
# Should show: -rw------- (only owner can read/write)

# Ensure it's gitignored
git check-ignore .env
# Should output: .env
```

#### Don't Echo Secrets

```bash
# BAD - logs secret to console
echo "Token: $ERR0_TOKEN_VALUE"

# GOOD - only log non-sensitive info
echo "Token file: $ERR0_TOKEN_FILE (exists: $(test -f $ERR0_TOKEN_FILE && echo yes || echo no))"
```

### 3. Docker Security

#### Run with Least Privilege

```bash
# Don't run Docker as root if possible
# Add user to docker group instead
sudo usermod -aG docker $USER

# Verify non-root access
docker ps
```

#### Limit Container Privileges

```bash
# Scripts already use --rm flag (remove after execution)
# Scripts use bind mounts (not full volume access)
# Scripts run with user's permissions

# If you modify scripts, maintain these security practices
```

### 4. Network Security

#### Use TLS for err0 Server

```bash
# In .env file, prefer HTTPS
ERR0_HOST=https://your-server.err0.io:8443

# Not recommended for production:
# ERR0_HOST=http://insecure-server.err0.io:8080
```

#### Restrict Network Access

```bash
# If running local err0 server, bind to localhost only
# Not: 0.0.0.0:8443
# Use: 127.0.0.1:8443

# Configure firewall rules for production servers
```

---

## Token Management

### Token Lifecycle

#### 1. Generation

```bash
# Generate with minimal required permissions
# Don't use admin tokens for testing
# Prefer project-specific tokens

# Set expiration (recommended: 90 days)
# Shorter for production: 30-60 days
# Longer for development: 180-365 days
```

#### 2. Storage

```bash
# Store in tokens/ directory (gitignored)
mkdir -p tokens
chmod 700 tokens

# Set restrictive permissions on token files
chmod 600 tokens/*.json

# Never store in home directory or temp locations
# Don't: ~/err0-token.json
# Don't: /tmp/token.json
```

#### 3. Usage

```bash
# Access tokens only via scripts (which load from config)
# Don't hardcode token paths in custom scripts

# Use environment variable overrides
ERR0_TOKEN_DJANGO=./tokens/custom-token.json ./dev-insert.sh
```

#### 4. Rotation

```bash
# Rotate tokens regularly (every 90 days recommended)

# Rotation process:
# 1. Generate new token
# 2. Test with new token
# 3. Replace old token file
# 4. Revoke old token in err0 server
# 5. Verify old token no longer works

# Set a reminder for rotation
echo "*/90 * * * * echo 'Time to rotate err0 tokens'" | crontab -
```

#### 5. Revocation

```bash
# Revoke immediately if:
# - Token was accidentally committed
# - Token was exposed in logs
# - Team member leaves project
# - Suspicious activity detected

# Revocation steps:
# 1. Revoke in err0 server (Settings → Tokens → Revoke)
# 2. Delete local token file
# 3. Generate new token
# 4. Update all users/systems using old token
```

### Token Compromise Response

**If a token is accidentally committed:**

1. **Immediately revoke** the token in err0 server
2. **Generate** a new token
3. **Remove** token from git history:
   ```bash
   # Using git filter-branch (for old repos)
   git filter-branch --force --index-filter \
     'git rm --cached --ignore-unmatch tokens/compromised-token.json' \
     --prune-empty --tag-name-filter cat -- --all

   # Or using BFG Repo Cleaner (recommended)
   bfg --delete-files compromised-token.json
   git reflog expire --expire=now --all && git gc --prune=now --aggressive
   ```
4. **Force push** to remote (if you have authority)
5. **Notify** all collaborators to re-clone
6. **Audit** for any unauthorized access

---

## Pre-Commit Security Checks

### Automated Checks

Install pre-commit hooks to prevent security issues:

#### 1. Create Pre-Commit Hook

```bash
# Create hook file
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Running security checks..."

# Check 1: Prevent token file commits
if git diff --cached --name-only | grep -qE '\.json$' | grep -E '(tokens/|dev-localhost/)'; then
    echo -e "${RED}ERROR: Attempting to commit token files!${NC}"
    echo "Token files must never be committed to version control."
    echo ""
    echo "Files being committed:"
    git diff --cached --name-only | grep -E '\.json$' | grep -E '(tokens/|dev-localhost/)'
    echo ""
    echo "To unstage: git reset HEAD <file>"
    exit 1
fi

# Check 2: Prevent .env file commits
if git diff --cached --name-only | grep -qE '^\.env$'; then
    echo -e "${RED}ERROR: Attempting to commit .env file!${NC}"
    echo ".env files may contain secrets and should not be committed."
    echo ""
    echo "To unstage: git reset HEAD .env"
    exit 1
fi

# Check 3: Scan for common secrets in diff
SECRETS_FOUND=0
while IFS= read -r line; do
    # Check for patterns that might be secrets
    if echo "$line" | grep -qiE '(password|secret|api[_-]?key|token[_-]?value)\s*[:=]'; then
        echo -e "${RED}WARNING: Possible secret found in commit:${NC}"
        echo "$line"
        SECRETS_FOUND=1
    fi
done < <(git diff --cached)

if [ $SECRETS_FOUND -eq 1 ]; then
    echo ""
    echo -e "${RED}Possible secrets detected in your commit!${NC}"
    echo "Please review the above lines carefully."
    echo ""
    read -p "Are you sure these are not secrets? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Commit aborted."
        exit 1
    fi
fi

# Check 4: Ensure token files are gitignored
if ! git check-ignore -q tokens/*.json 2>/dev/null; then
    echo -e "${RED}WARNING: Token files may not be gitignored!${NC}"
    echo "Verify .gitignore includes: /tokens/*.json"
fi

echo -e "${GREEN}Security checks passed!${NC}"
exit 0
EOF

# Make executable
chmod +x .git/hooks/pre-commit
```

#### 2. Test Pre-Commit Hook

```bash
# Try to commit a token file (should fail)
git add tokens/test-token.json
git commit -m "Test"
# Expected: Error message and commit blocked

# Unstage the file
git reset HEAD tokens/test-token.json
```

### Manual Checks

Before every commit, manually verify:

```bash
# Check what's being committed
git diff --cached

# Look for sensitive data
git diff --cached | grep -i "password\|secret\|token"

# Verify token files are ignored
git status --ignored | grep -E '(tokens/|dev-localhost/).*\.json'
```

---

## Incident Response

### If Credentials Are Exposed

**Immediate Actions (0-1 hour):**

1. **Revoke** compromised credentials immediately
2. **Rotate** all potentially affected tokens
3. **Audit** access logs for unauthorized usage
4. **Document** incident details

**Short-term Actions (1-24 hours):**

5. **Notify** affected parties (internal team, users if applicable)
6. **Clean** git history if credentials were committed
7. **Update** security practices to prevent recurrence
8. **Monitor** for suspicious activity

**Long-term Actions (1-7 days):**

9. **Review** security policies
10. **Implement** additional safeguards
11. **Train** team on security best practices
12. **Document** lessons learned

### Incident Template

```markdown
## Security Incident Report

**Date:** YYYY-MM-DD
**Reporter:** Name
**Severity:** Critical / High / Medium / Low

### Description
Brief description of incident

### Timeline
- HH:MM - Incident discovered
- HH:MM - Credentials revoked
- HH:MM - Issue resolved

### Impact
- Number of tokens exposed: X
- Duration of exposure: X hours/days
- Unauthorized access detected: Yes/No

### Root Cause
What caused the incident

### Resolution
Steps taken to resolve

### Prevention
How to prevent similar incidents

### Lessons Learned
Key takeaways
```

---

## Security Updates

### Staying Informed

**Subscribe to:**
- err0.io security mailing list: security-announce@err0.io
- GitHub repository watch (Releases only)
- Docker Hub for err0io/agent image updates

**Check regularly:**
- [GitHub Security Advisories](https://github.com/err0io/open-source-bundle/security/advisories)
- [err0.io Security Page](https://err0.io/security)

### Applying Updates

```bash
# Update repository
git pull upstream master

# Update Docker images
docker pull err0io/agent:latest
docker pull err0io/agent:develop

# Check for changes to security practices
git log --oneline --grep="security\|SECURITY"

# Review SECURITY.md for updates
git diff HEAD~10 SECURITY.md
```

### Vulnerability Disclosure Timeline

When we discover a vulnerability:

1. **Day 0:** Vulnerability identified
2. **Day 1-7:** Fix developed and tested
3. **Day 7:** Fix released, security advisory published
4. **Day 14:** Detailed disclosure (if appropriate)

Users are notified via:
- Security advisory (GitHub)
- Email (if subscribed)
- Release notes

---

## Security Checklist

### Setup Security

- [ ] `.env` file has restrictive permissions (600)
- [ ] `tokens/` directory has restrictive permissions (700)
- [ ] All token files have restrictive permissions (600)
- [ ] Pre-commit hooks installed
- [ ] `.gitignore` includes token patterns
- [ ] No secrets in git history (`git log --all -p | grep -i token_value`)

### Operational Security

- [ ] Tokens rotated every 90 days
- [ ] Tokens have minimal required permissions
- [ ] Tokens have expiration dates set
- [ ] Using TLS for err0 server connections
- [ ] Docker images updated regularly
- [ ] No root/admin tokens in use for testing

### Development Security

- [ ] Code reviewed for security issues
- [ ] No hardcoded secrets in scripts
- [ ] Input validation in place
- [ ] Error messages don't leak sensitive info
- [ ] Security tests pass

---

## Questions?

For security-related questions:
- **General:** security@err0.io
- **Vulnerabilities:** security@err0.io (private)
- **Documentation:** docs@err0.io

For non-security questions, see [README.md](README.md) or [CONTRIBUTING.md](CONTRIBUTING.md).

---

**Security is everyone's responsibility.** Thank you for keeping err0.io secure! 🔒
