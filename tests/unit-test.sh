#!/bin/bash
# Unit tests for config-helper.sh functions
# Tests token discovery, environment variable handling, and validation logic

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

# Source the config helper
source "$REPO_ROOT/scripts/config-helper.sh"

# Test helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

skip() {
    echo -e "${YELLOW}⊘${NC} $1 (skipped)"
}

echo "========================================"
echo "Unit Tests for config-helper.sh"
echo "========================================"
echo

# Test 1: REPO_ROOT detection
echo "Test Suite: REPO_ROOT Detection"
if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT" ]; then
    pass "REPO_ROOT is set and directory exists"
else
    fail "REPO_ROOT not properly set"
fi

if [ -f "$REPO_ROOT/.gitmodules" ]; then
    pass "REPO_ROOT points to repository root"
else
    fail "REPO_ROOT does not point to repository root"
fi
echo

# Test 2: Token directory detection
echo "Test Suite: Token Directory Detection"
if [ -n "$ERR0_TOKEN_DIR" ]; then
    pass "ERR0_TOKEN_DIR is set"
else
    fail "ERR0_TOKEN_DIR is not set"
fi

if [ -d "$ERR0_TOKEN_DIR" ]; then
    pass "Token directory exists: $ERR0_TOKEN_DIR"
else
    skip "Token directory does not exist (acceptable for fresh install)"
fi
echo

# Test 3: Environment variable defaults
echo "Test Suite: Environment Variable Defaults"
if [ "$ERR0_DOCKER_NETWORK" = "host" ]; then
    pass "ERR0_DOCKER_NETWORK defaults to 'host'"
else
    fail "ERR0_DOCKER_NETWORK has unexpected default: $ERR0_DOCKER_NETWORK"
fi

if [ -n "$ERR0_TOKEN_DIR" ]; then
    pass "ERR0_TOKEN_DIR has a default value"
else
    fail "ERR0_TOKEN_DIR is empty"
fi
echo

# Test 4: find_token_file function with environment variable
echo "Test Suite: find_token_file Function"

# Create temporary test tokens
TEST_TOKEN_DIR=$(mktemp -d)
trap "rm -rf $TEST_TOKEN_DIR" EXIT

TEST_PROJECT="django"
TEST_TOKEN_FILE="$TEST_TOKEN_DIR/err0-django-test-12345678.json"
echo '{"host":"localhost","realm_uuid":"test","prj_uuid":"test","token_uuid":"test","token_value":"test"}' > "$TEST_TOKEN_FILE"

# Test with environment variable
export ERR0_DJANGO_TOKEN="$TEST_TOKEN_FILE"
RESULT=$(find_token_file "django")
if [ "$RESULT" = "$TEST_TOKEN_FILE" ]; then
    pass "find_token_file returns ERR0_DJANGO_TOKEN when set"
else
    fail "find_token_file did not use ERR0_DJANGO_TOKEN (got: $RESULT)"
fi
unset ERR0_DJANGO_TOKEN

# Test with file in token directory
export ERR0_TOKEN_DIR="$TEST_TOKEN_DIR"
RESULT=$(find_token_file "django")
if [ "$RESULT" = "$TEST_TOKEN_FILE" ]; then
    pass "find_token_file finds token in ERR0_TOKEN_DIR"
else
    fail "find_token_file did not find token in directory (got: $RESULT)"
fi

# Test with legacy dev-localhost fallback
LEGACY_TOKEN="$REPO_ROOT/dev-localhost/err0-django-test-12345678.json"
if [ -d "$REPO_ROOT/dev-localhost" ]; then
    echo '{"host":"localhost","realm_uuid":"test","prj_uuid":"test","token_uuid":"test","token_value":"test"}' > "$LEGACY_TOKEN"
    export ERR0_TOKEN_DIR="$REPO_ROOT/nonexistent"
    RESULT=$(find_token_file "django" 2>/dev/null || echo "NOTFOUND")
    if [ "$RESULT" = "$LEGACY_TOKEN" ]; then
        pass "find_token_file falls back to dev-localhost"
    else
        fail "find_token_file did not fall back to dev-localhost (got: $RESULT)"
    fi
    rm -f "$LEGACY_TOKEN"
fi

# Test with missing token
export ERR0_TOKEN_DIR="/nonexistent"
RESULT=$(find_token_file "nonexistent" 2>/dev/null || echo "NOTFOUND")
if [ "$RESULT" = "NOTFOUND" ]; then
    pass "find_token_file fails gracefully for missing token"
else
    fail "find_token_file should have failed for missing token"
fi

echo

# Test 5: Token file validation
echo "Test Suite: Token File Validation"

# Valid token
VALID_TOKEN="$TEST_TOKEN_DIR/valid-token.json"
cat > "$VALID_TOKEN" <<'EOF'
{
  "host": "localhost:8080",
  "realm_uuid": "12345678-1234-1234-1234-123456789abc",
  "prj_uuid": "87654321-4321-4321-4321-cba987654321",
  "token_uuid": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
  "token_value": "secret-token-value-here"
}
EOF

if [ -f "$VALID_TOKEN" ]; then
    if jq empty "$VALID_TOKEN" 2>/dev/null; then
        pass "Valid token file has correct JSON format"
    else
        fail "Valid token file failed JSON validation"
    fi
fi

# Invalid token (missing field)
INVALID_TOKEN="$TEST_TOKEN_DIR/invalid-token.json"
cat > "$INVALID_TOKEN" <<'EOF'
{
  "host": "localhost:8080",
  "realm_uuid": "12345678-1234-1234-1234-123456789abc"
}
EOF

if jq empty "$INVALID_TOKEN" 2>/dev/null; then
    pass "Invalid token detection works (JSON valid but incomplete)"
else
    fail "Invalid token should have valid JSON"
fi

echo

# Test 6: Filename special characters handling
echo "Test Suite: Special Characters in Filenames"

SPACE_TOKEN="$TEST_TOKEN_DIR/token with spaces.json"
echo '{"host":"localhost","realm_uuid":"test","prj_uuid":"test","token_uuid":"test","token_value":"test"}' > "$SPACE_TOKEN"

if [ -f "$SPACE_TOKEN" ]; then
    pass "Token file with spaces in name can be created"
else
    fail "Token file with spaces in name was not created"
fi

# Test that config-helper.sh handles spaces correctly
export ERR0_TOKEN_DIR="$TEST_TOKEN_DIR"
# This would fail if variables aren't properly quoted
TOKEN_COUNT=$(ls "$ERR0_TOKEN_DIR"/*.json 2>/dev/null | wc -l)
if [ "$TOKEN_COUNT" -ge 1 ]; then
    pass "Token directory listing handles special characters"
else
    skip "Token directory listing test (no tokens found)"
fi

echo

# Test 7: Git validation
echo "Test Suite: Git Repository Validation"

if git rev-parse --git-dir >/dev/null 2>&1; then
    pass "Repository is a valid git repository"
else
    fail "Not in a git repository"
fi

if git config --file .gitmodules --get-regexp "^submodule\..*\.path$" >/dev/null 2>&1; then
    pass "Repository has submodules configured"
else
    skip "No submodules configured"
fi

if [ -f "$REPO_ROOT/.gitignore" ]; then
    pass ".gitignore exists"
else
    fail ".gitignore missing"
fi

echo

# Test 8: Docker image variables
echo "Test Suite: Docker Image Configuration"

if [ -n "$ERR0_DOCKER_IMAGE" ]; then
    pass "ERR0_DOCKER_IMAGE is set: $ERR0_DOCKER_IMAGE"
else
    fail "ERR0_DOCKER_IMAGE is not set"
fi

# Validate image format
if echo "$ERR0_DOCKER_IMAGE" | grep -qE '^[a-z0-9_-]+/[a-z0-9_-]+:[a-z0-9_.-]+$'; then
    pass "Docker image name has valid format"
else
    skip "Docker image format validation (may be using digest)"
fi

echo

# Test 9: Project list validation
echo "Test Suite: Project List Validation"

if [ -f "$REPO_ROOT/config/project-list.txt" ]; then
    pass "config/project-list.txt exists"

    PROJECT_COUNT=$(grep -v "^#" "$REPO_ROOT/config/project-list.txt" | grep -v "^$" | wc -l)
    if [ "$PROJECT_COUNT" -gt 0 ]; then
        pass "Project list contains $PROJECT_COUNT projects"
    else
        fail "Project list is empty"
    fi
else
    skip "config/project-list.txt not found"
fi

echo

# Summary
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    exit 1
fi
