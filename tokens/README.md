# Token File Setup

This directory stores err0.io authentication token files. Token files contain sensitive credentials and are **gitignored** for security.

## Quick Start

### 1. Generate Tokens

Generate authentication tokens from your err0.io server:

```bash
# For each project you want to test
curl -X POST https://your-server.err0.io/api/tokens \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"project_uuid": "YOUR_PROJECT_UUID"}'
```

Or use the err0.io web interface:
1. Navigate to Settings → Tokens
2. Click "Generate New Token"
3. Select the project
4. Download the JSON file

### 2. Place Token Files

Copy or move token JSON files to this directory:

```bash
# Example: Copy from Downloads
cp ~/Downloads/err0-django-*.json ./tokens/

# Or generate directly here
./scripts/generate-tokens.sh
```

### 3. Token File Format

Token files must be valid JSON with this structure:

```json
{
  "host": "your-server.err0.io:8443",
  "realm_uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "prj_uuid": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
  "token_uuid": "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz",
  "token_value": "1.very_long_encrypted_token_string..."
}
```

### 4. Token File Naming

Token files should follow this naming convention:

```
err0-<project-name>-<date>-<uuid>.json
```

Examples:
- `err0-django-20221207-3c39a436-763f-11ed-8b95-4401bb8de3b3.json`
- `err0-kubernetes-20221207-4fc303c9-763f-11ed-8b95-4401bb8de3b3.json`
- `err0-rails-20230723-82c92bf1-1997-11ee-8025-305a3ac84b71.json`

The project name should match the subdirectory name in the repository.

## Token Management

### List Available Tokens

```bash
ls -1 tokens/*.json | sed 's/.*err0-//' | sed 's/-[0-9].*\.json$//'
```

### Find Token for Specific Project

```bash
# Find token for django
ls tokens/err0-django-*.json

# Or use the config helper
source scripts/config-helper.sh
find_token_file django
```

### Rotate Tokens

To rotate (replace) a token:

1. Generate new token from err0.io server
2. Download new token JSON file
3. Remove old token file: `rm tokens/err0-django-old.json`
4. Add new token file: `cp ~/Downloads/err0-django-new.json tokens/`

### Verify Token

Test that a token works:

```bash
# Test token for django project
./err0agent-analyse.sh tokens/err0-django-*.json django --dirty
```

If the command succeeds without authentication errors, the token is valid.

## Security Best Practices

### ⚠️ CRITICAL SECURITY WARNINGS

1. **NEVER commit token files to version control**
   - Token files contain authentication credentials
   - They are gitignored by default - do not override this!
   - If accidentally committed, rotate ALL tokens immediately

2. **NEVER share token files**
   - Each developer should generate their own tokens
   - Do not send token files via email, Slack, or other channels
   - Use secure secret management for CI/CD (GitHub Secrets, etc.)

3. **Rotate tokens regularly**
   - Rotate tokens every 90 days
   - Rotate immediately if you suspect compromise
   - Remove tokens for users who leave the project

4. **Limit token permissions**
   - Generate tokens with minimal required permissions
   - Use separate tokens for production vs development
   - Use separate tokens for CI/CD vs local development

### Check for Accidental Commits

Before pushing code, verify no tokens are staged:

```bash
git status | grep -i "\.json"
# Should NOT show any token files

git diff --cached | grep -i "token_value"
# Should return nothing
```

### Pre-commit Hook

Install a pre-commit hook to prevent token leaks:

```bash
# Create .git/hooks/pre-commit
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
if git diff --cached --name-only | grep -q "tokens/.*\.json"; then
    echo "ERROR: Attempting to commit token files!"
    echo "Token files must never be committed to version control."
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

## Troubleshooting

### "No token file found"

The scripts look for token files matching the project name. Ensure:

1. Token file exists in `tokens/` directory
2. Token file name includes project name: `err0-<project>-*.json`
3. Project name matches subdirectory name exactly

### "Authentication failed"

Common causes:

1. **Token expired**: Generate a new token
2. **Wrong server**: Check `host` in token file matches `ERR0_HOST` in `.env`
3. **Token revoked**: Generate a new token
4. **Network issue**: Check connection to err0.io server

### "Invalid JSON"

Token file must be valid JSON. Validate with:

```bash
python3 -m json.tool < tokens/err0-django-*.json
```

If invalid, re-download the token file from err0.io server.

## Environment Variable Overrides

You can override token files per-project using environment variables:

```bash
# In .env file
ERR0_TOKEN_DJANGO=./tokens/err0-django-custom.json
ERR0_TOKEN_KUBERNETES=./tokens/err0-kubernetes-staging.json

# Or on command line
ERR0_TOKEN_DJANGO=./tokens/test.json ./dev-insert.sh
```

This is useful for:
- Testing with different err0.io servers
- Using staging vs production tokens
- Per-developer token customization

## Getting Help

- **err0.io Documentation**: https://docs.err0.io/authentication/tokens
- **Generate Tokens**: https://your-server.err0.io/tokens
- **Report Issues**: https://github.com/err0io/open-source-bundle/issues
- **Support**: support@err0.io
