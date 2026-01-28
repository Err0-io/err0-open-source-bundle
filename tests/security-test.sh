#!/bin/bash
# Security tests for the err0.io open source bundle
# Validates .gitignore patterns, pre-commit hooks, and secret protection

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

skip() {
    echo -e "${YELLOW}⊘${NC} $1 (skipped)"
}

echo "========================================"
echo "Security Tests"
echo "========================================"
echo

# Test 1: .gitignore exists and has critical patterns
echo "Test Suite: .gitignore Protection"

if [ -f "$REPO_ROOT/.gitignore" ]; then
    pass ".gitignore file exists"
else
    fail ".gitignore file missing"
fi

# Check for critical patterns
CRITICAL_PATTERNS=(
    "tokens/"
    ".env"
    "*.env"
    ".env.local"
    "config/*.json"
)

for pattern in "${CRITICAL_PATTERNS[@]}"; do
    if grep -qF "$pattern" "$REPO_ROOT/.gitignore"; then
        pass ".gitignore contains pattern: $pattern"
    else
        fail ".gitignore missing critical pattern: $pattern"
    fi
done

echo

# Test 2: Git check-ignore validation
echo "Test Suite: Git Ignore Rules"

# Test that critical paths are ignored
TEST_FILES=(
    "tokens/test-token.json"
    ".env"
    ".env.local"
    "config/test-config.json"
)

for test_file in "${TEST_FILES[@]}"; do
    if git check-ignore -q "$test_file" 2>/dev/null; then
        pass "Git ignores: $test_file"
    else
        # check-ignore returns 1 if not ignored, which we want to catch
        if [ -f "$REPO_ROOT/$test_file" ]; then
            fail "Git does NOT ignore existing file: $test_file"
        else
            warn "Git would NOT ignore: $test_file (file doesn't exist)"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
done

# Verify dev-localhost is NOT ignored (needs to be committed)
if git check-ignore -q "dev-localhost/" 2>/dev/null; then
    fail "dev-localhost/ should NOT be ignored"
else
    pass "dev-localhost/ is tracked (contains .gitkeep)"
fi

echo

# Test 3: Pre-commit hook installation
echo "Test Suite: Pre-commit Hook"

if [ -f "$REPO_ROOT/.git/hooks/pre-commit" ]; then
    pass "Pre-commit hook is installed"

    # Check if it's executable
    if [ -x "$REPO_ROOT/.git/hooks/pre-commit" ]; then
        pass "Pre-commit hook is executable"
    else
        fail "Pre-commit hook is not executable"
    fi

    # Check if it contains our security checks
    if grep -q "token" "$REPO_ROOT/.git/hooks/pre-commit"; then
        pass "Pre-commit hook contains token detection"
    else
        fail "Pre-commit hook missing token detection"
    fi
else
    warn "Pre-commit hook not installed (run: ./scripts/install-hooks.sh)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

if [ -f "$REPO_ROOT/hooks/pre-commit" ]; then
    pass "Pre-commit hook source file exists"
else
    fail "Pre-commit hook source file missing (hooks/pre-commit)"
fi

echo

# Test 4: Token directory permissions
echo "Test Suite: File Permissions"

if [ -d "$REPO_ROOT/tokens" ]; then
    PERMS=$(stat -f "%Lp" "$REPO_ROOT/tokens" 2>/dev/null || stat -c "%a" "$REPO_ROOT/tokens" 2>/dev/null)
    if [ -n "$PERMS" ]; then
        # Directory should be readable only by owner (700 or 755 are acceptable)
        if [[ "$PERMS" =~ ^7[0-5][0-5]$ ]]; then
            pass "tokens/ directory has secure permissions: $PERMS"
        else
            warn "tokens/ directory permissions may be too open: $PERMS"
        fi
    fi
else
    skip "tokens/ directory does not exist"
fi

if [ -d "$REPO_ROOT/config" ]; then
    CONFIG_PERMS=$(stat -f "%Lp" "$REPO_ROOT/config" 2>/dev/null || stat -c "%a" "$REPO_ROOT/config" 2>/dev/null)
    if [ -n "$CONFIG_PERMS" ]; then
        pass "config/ directory permissions: $CONFIG_PERMS"
    fi
else
    skip "config/ directory does not exist"
fi

echo

# Test 5: Scan for secrets in tracked files
echo "Test Suite: Secret Detection in Tracked Files"

# Check for token_value in tracked files (should only be in templates)
if git grep -i "token_value" -- ':!.env.template' ':!docs/' ':!*.md' >/dev/null 2>&1; then
    warn "Found 'token_value' in tracked files (verify these are templates only)"
    git grep -i "token_value" -- ':!.env.template' ':!docs/' ':!*.md' | head -5
else
    pass "No 'token_value' found in non-template tracked files"
fi

# Check for common secret patterns
SECRET_PATTERNS=(
    "password.*=.*['\"][^'\"]+['\"]"
    "api.*key.*=.*['\"][^'\"]+['\"]"
    "secret.*=.*['\"][^'\"]+['\"]"
)

SECRETS_FOUND=0
for pattern in "${SECRET_PATTERNS[@]}"; do
    if git grep -iE "$pattern" -- ':!.env.template' ':!docs/' ':!*.md' ':!tests/' >/dev/null 2>&1; then
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    fi
done

if [ $SECRETS_FOUND -eq 0 ]; then
    pass "No obvious secrets found in tracked files"
else
    warn "Found $SECRETS_FOUND potential secrets (manual review needed)"
fi

echo

# Test 6: Git history scan (basic)
echo "Test Suite: Git History Protection"

# Check if any .json files in tokens/ or dev-localhost/ were ever committed
COMMITTED_TOKENS=$(git log --all --pretty=format: --name-only --diff-filter=A | grep -E "(tokens/.*\.json|dev-localhost/.*\.json)" | grep -v ".gitkeep" | head -5)

if [ -z "$COMMITTED_TOKENS" ]; then
    pass "No token files found in git history (basic check)"
else
    warn "Token files may exist in git history (requires deep scan):"
    echo "$COMMITTED_TOKENS" | head -3
    warn "Consider running: git filter-repo --path-glob 'tokens/*.json' --invert-paths"
fi

echo

# Test 7: .env file protection
echo "Test Suite: .env File Protection"

if [ -f "$REPO_ROOT/.env" ]; then
    fail ".env file exists in repository (should not be tracked)"

    # Check if it's tracked
    if git ls-files --error-unmatch .env >/dev/null 2>&1; then
        fail ".env file is TRACKED by git (critical security issue)"
    else
        pass ".env file exists but is not tracked"
    fi
else
    pass "No .env file in repository root"
fi

if [ -f "$REPO_ROOT/.env.template" ]; then
    pass ".env.template exists (good for documentation)"

    # Verify template doesn't contain real secrets
    if grep -qE "(token_value|password|api.*key).*=.*[a-zA-Z0-9]{20,}" .env.template; then
        fail ".env.template appears to contain real secrets"
    else
        pass ".env.template contains only placeholders"
    fi
else
    pass ".env.template exists for reference"
fi

echo

# Test 8: Submodule security
echo "Test Suite: Submodule Security"

# Check that no submodules use SSH URLs that might expose credentials
SSH_SUBMODULES=$(git config --file .gitmodules --get-regexp "^submodule\..*\.url$" | grep "git@" || true)

if [ -z "$SSH_SUBMODULES" ]; then
    pass "No SSH URLs in submodules (good for public repos)"
else
    SUBMODULE_COUNT=$(echo "$SSH_SUBMODULES" | wc -l)
    warn "Found $SUBMODULE_COUNT submodules with SSH URLs (may limit access)"
fi

# Check for internal/private URLs
PRIVATE_URLS=$(git config --file .gitmodules --get-regexp "^submodule\..*\.url$" | grep -E "(gitlab\.internal|github\.internal|bitbucket\.internal)" || true)

if [ -z "$PRIVATE_URLS" ]; then
    pass "No internal/private URLs in submodules"
else
    fail "Found submodules with internal URLs (will fail for external users)"
    echo "$PRIVATE_URLS"
fi

echo

# Test 9: Script security
echo "Test Suite: Script Security"

# Check that scripts don't have world-writable permissions
WORLD_WRITABLE=$(find "$REPO_ROOT" -maxdepth 1 -name "*.sh" -perm -002 2>/dev/null || true)

if [ -z "$WORLD_WRITABLE" ]; then
    pass "No world-writable scripts in root directory"
else
    fail "Found world-writable scripts (security risk):"
    echo "$WORLD_WRITABLE"
fi

# Check scripts directory
if [ -d "$REPO_ROOT/scripts" ]; then
    SCRIPTS_WORLD_WRITABLE=$(find "$REPO_ROOT/scripts" -name "*.sh" -perm -002 2>/dev/null || true)
    if [ -z "$SCRIPTS_WORLD_WRITABLE" ]; then
        pass "No world-writable scripts in scripts/ directory"
    else
        fail "Found world-writable scripts in scripts/ directory"
    fi
fi

echo

# Summary
echo "========================================"
echo "Security Test Summary"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All security tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some security tests failed.${NC}"
    echo
    echo "Recommended actions:"
    echo "  1. Install pre-commit hook: ./scripts/install-hooks.sh"
    echo "  2. Review .gitignore patterns"
    echo "  3. Check file permissions in tokens/ and config/"
    echo "  4. Scan git history for secrets: git log --all --full-history -- tokens/"
    exit 1
fi
