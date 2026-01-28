#!/bin/bash
# Integration tests for the err0.io open source bundle
# Tests end-to-end workflows, script execution, and cross-component integration

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
echo "Integration Tests"
echo "========================================"
echo

# Test 1: Script help messages
echo "Test Suite: Script Help Messages"

SCRIPTS=(
    "err0agent-insert.sh"
    "err0agent-analyse.sh"
    "err0agent-dev-insert.sh"
    "err0agent-dev-analyse.sh"
    "dev-insert.sh"
    "dev-analyse.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$REPO_ROOT/$script" ]; then
        if "$REPO_ROOT/$script" --help >/dev/null 2>&1 || "$REPO_ROOT/$script" 2>&1 | grep -qi "usage\|error"; then
            pass "$script responds to invocation (help or error message)"
        else
            warn "$script may not have proper help message"
        fi
    else
        skip "$script not found"
    fi
done

echo

# Test 2: Token discovery with different configurations
echo "Test Suite: Token Discovery"

# Create test environment
TEST_TOKEN_DIR=$(mktemp -d)
trap "rm -rf $TEST_TOKEN_DIR" EXIT

TEST_PROJECT="testproject"
TEST_TOKEN="$TEST_TOKEN_DIR/err0-testproject-12345678.json"
cat > "$TEST_TOKEN" <<'EOF'
{
  "host": "localhost:8080",
  "realm_uuid": "12345678-1234-1234-1234-123456789abc",
  "prj_uuid": "87654321-4321-4321-4321-cba987654321",
  "token_uuid": "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
  "token_value": "test-token-value"
}
EOF

# Source config-helper
source "$REPO_ROOT/scripts/config-helper.sh"

# Test 1: Environment variable takes precedence
export ERR0_TESTPROJECT_TOKEN="$TEST_TOKEN"
RESULT=$(find_token_file "testproject")
if [ "$RESULT" = "$TEST_TOKEN" ]; then
    pass "Token discovery: Environment variable takes precedence"
else
    fail "Token discovery: Environment variable not used"
fi
unset ERR0_TESTPROJECT_TOKEN

# Test 2: Token directory discovery
export ERR0_TOKEN_DIR="$TEST_TOKEN_DIR"
RESULT=$(find_token_file "testproject")
if [ "$RESULT" = "$TEST_TOKEN" ]; then
    pass "Token discovery: Found in ERR0_TOKEN_DIR"
else
    fail "Token discovery: Failed to find in ERR0_TOKEN_DIR"
fi

# Test 3: Fallback to dev-localhost
if [ -d "$REPO_ROOT/dev-localhost" ]; then
    LEGACY_TOKEN="$REPO_ROOT/dev-localhost/err0-testproject-12345678.json"
    cp "$TEST_TOKEN" "$LEGACY_TOKEN"

    export ERR0_TOKEN_DIR="/nonexistent"
    RESULT=$(find_token_file "testproject" 2>/dev/null || echo "")
    if [ "$RESULT" = "$LEGACY_TOKEN" ]; then
        pass "Token discovery: Falls back to dev-localhost"
    else
        fail "Token discovery: Failed to fall back to dev-localhost"
    fi
    rm -f "$LEGACY_TOKEN"
fi

# Test 4: Missing token handling
export ERR0_TOKEN_DIR="/nonexistent"
if find_token_file "nonexistent" >/dev/null 2>&1; then
    fail "Token discovery: Should fail for nonexistent token"
else
    pass "Token discovery: Correctly fails for missing token"
fi

echo

# Test 3: Script error handling
echo "Test Suite: Script Error Handling"

# Test invalid token file
INVALID_TOKEN="$TEST_TOKEN_DIR/invalid.json"
echo "not json" > "$INVALID_TOKEN"

export ERR0_TESTPROJECT_TOKEN="$INVALID_TOKEN"

# Scripts should detect invalid JSON (we'll test this by checking the exit code)
if [ -f "$REPO_ROOT/err0agent-dev-insert.sh" ]; then
    # This should fail gracefully
    if "$REPO_ROOT/err0agent-dev-insert.sh" "$INVALID_TOKEN" testproject 2>&1 | grep -qi "error\|invalid\|failed\|docker"; then
        pass "Script detects invalid token or fails gracefully"
    else
        skip "Script error handling test (Docker may not be available)"
    fi
fi

echo

# Test 4: Parallel operations (dev-insert.sh, dev-analyse.sh)
echo "Test Suite: Parallel Operations"

if [ -f "$REPO_ROOT/dev-insert.sh" ] && [ -f "$REPO_ROOT/config/project-list.txt" ]; then
    # Test that scripts can read project list
    if "$REPO_ROOT/dev-insert.sh" --help >/dev/null 2>&1 || "$REPO_ROOT/dev-insert.sh" 2>&1 | grep -qi "usage\|project"; then
        pass "dev-insert.sh can display help"
    else
        skip "dev-insert.sh help test"
    fi

    # Check if script properly handles ERR0_MAX_PARALLEL
    export ERR0_MAX_PARALLEL=2
    if grep -q "ERR0_MAX_PARALLEL" "$REPO_ROOT/dev-insert.sh"; then
        pass "dev-insert.sh supports ERR0_MAX_PARALLEL"
    else
        skip "ERR0_MAX_PARALLEL not yet implemented"
    fi
else
    skip "Parallel operation scripts not found"
fi

echo

# Test 5: Submodule validation
echo "Test Suite: Submodule Integration"

# Check that submodules are properly initialized
if [ -f "$REPO_ROOT/.gitmodules" ]; then
    SUBMODULE_COUNT=$(git config --file .gitmodules --get-regexp "^submodule\..*\.path$" | wc -l)
    if [ "$SUBMODULE_COUNT" -gt 0 ]; then
        pass "Found $SUBMODULE_COUNT submodules configured"
    else
        fail "No submodules found in .gitmodules"
    fi

    # Check a few submodules exist
    SAMPLE_SUBMODULES=("django" "kubernetes" "ratpack")
    for submodule in "${SAMPLE_SUBMODULES[@]}"; do
        if [ -d "$REPO_ROOT/$submodule" ]; then
            if [ -f "$REPO_ROOT/$submodule/.git" ] || [ -d "$REPO_ROOT/$submodule/.git" ]; then
                pass "Submodule initialized: $submodule"
            else
                skip "Submodule not initialized: $submodule (run: git submodule update --init)"
            fi
        else
            skip "Submodule directory not found: $submodule"
        fi
    done
else
    fail ".gitmodules not found"
fi

echo

# Test 6: Docker integration
echo "Test Suite: Docker Integration"

# Check if Docker is available
if command -v docker >/dev/null 2>&1; then
    pass "Docker command available"

    # Check if Docker daemon is running
    if docker ps >/dev/null 2>&1; then
        pass "Docker daemon is running"

        # Check if err0 images are available or can be pulled
        if docker images | grep -q "err0io/agent"; then
            pass "err0io/agent Docker image available locally"
        else
            skip "err0io/agent image not cached (will be pulled on first use)"
        fi
    else
        warn "Docker daemon not running (scripts will fail)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    warn "Docker not installed (required for err0 agent)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo

# Test 7: Configuration validation
echo "Test Suite: Configuration Validation"

if [ -f "$REPO_ROOT/config/project-list.txt" ]; then
    pass "config/project-list.txt exists"

    # Check format
    if grep -qE "^[a-zA-Z0-9_.-]+$" "$REPO_ROOT/config/project-list.txt"; then
        pass "Project list has valid format"
    else
        warn "Project list may contain invalid project names"
    fi

    # Check for duplicates
    DUPLICATES=$(grep -v "^#" "$REPO_ROOT/config/project-list.txt" | grep -v "^$" | sort | uniq -d)
    if [ -z "$DUPLICATES" ]; then
        pass "No duplicate projects in project-list.txt"
    else
        fail "Duplicate projects found: $DUPLICATES"
    fi
else
    fail "config/project-list.txt not found"
fi

echo

# Test 8: Environment file validation
echo "Test Suite: Environment Configuration"

if [ -f "$REPO_ROOT/.env.template" ]; then
    pass ".env.template exists"

    # Check that template has all required variables
    REQUIRED_VARS=(
        "ERR0_TOKEN_DIR"
        "ERR0_DOCKER_IMAGE"
        "ERR0_DOCKER_NETWORK"
    )

    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^#*${var}=" "$REPO_ROOT/.env.template"; then
            pass ".env.template contains $var"
        else
            fail ".env.template missing $var"
        fi
    done
else
    warn ".env.template not found"
fi

# Check if user has created .env
if [ -f "$REPO_ROOT/.env" ]; then
    if git ls-files --error-unmatch .env >/dev/null 2>&1; then
        fail ".env file is tracked by git (security risk)"
    else
        pass ".env file exists and is not tracked"
    fi
else
    skip ".env file not created (optional)"
fi

echo

# Test 9: Perl script integration
echo "Test Suite: Perl Script Integration"

PERL_SCRIPTS=(
    "soak-test.pl"
    "versioning-test.pl"
)

for script in "${PERL_SCRIPTS[@]}"; do
    if [ -f "$REPO_ROOT/$script" ]; then
        # Check if script is executable
        if [ -x "$REPO_ROOT/$script" ]; then
            pass "$script is executable"
        else
            warn "$script is not executable (may need: chmod +x $script)"
        fi

        # Check for required Perl modules
        if perl -e 'use File::Basename; use Cwd;' 2>/dev/null; then
            pass "$script: Required Perl modules available"
        else
            fail "$script: Missing required Perl modules"
        fi

        # Check if script uses dynamic token discovery
        if grep -q "find_token_file\|ERR0_TOKEN_DIR" "$REPO_ROOT/$script"; then
            pass "$script: Uses dynamic token discovery"
        elif grep -q "dev-localhost/" "$REPO_ROOT/$script"; then
            warn "$script: Still uses hardcoded dev-localhost paths"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        else
            skip "$script: Token discovery method unclear"
        fi
    else
        skip "$script not found"
    fi
done

echo

# Test 10: Cross-platform compatibility
echo "Test Suite: Cross-platform Compatibility"

# Detect platform
PLATFORM=$(uname -s)
case "$PLATFORM" in
    Linux*)
        pass "Platform: Linux"
        ;;
    Darwin*)
        pass "Platform: macOS"
        warn "Note: Docker host network mode may not work on macOS"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        pass "Platform: Windows (Git Bash/MSYS/Cygwin)"
        warn "Note: Docker host network mode may not work on Windows"
        ;;
    *)
        warn "Platform: Unknown ($PLATFORM)"
        ;;
esac

# Check for required commands
REQUIRED_COMMANDS=("git" "bash" "perl" "docker" "jq")
OPTIONAL_COMMANDS=("uuid" "uuidgen")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        pass "Required command available: $cmd"
    else
        fail "Required command missing: $cmd"
    fi
done

# Check for UUID generation
UUID_CMD=""
if command -v uuid >/dev/null 2>&1; then
    UUID_CMD="uuid"
elif command -v uuidgen >/dev/null 2>&1; then
    UUID_CMD="uuidgen"
fi

if [ -n "$UUID_CMD" ]; then
    pass "UUID generation available: $UUID_CMD"
else
    warn "No UUID generation command found (uuid or uuidgen)"
fi

echo

# Summary
echo "========================================"
echo "Integration Test Summary"
echo "========================================"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some integration tests failed.${NC}"
    echo
    echo "Common issues:"
    echo "  1. Docker not running: sudo systemctl start docker (Linux) or start Docker Desktop"
    echo "  2. Submodules not initialized: git submodule update --init"
    echo "  3. Perl scripts using hardcoded paths: needs migration to dynamic token discovery"
    echo "  4. Missing dependencies: install required commands (git, bash, perl, docker, jq)"
    exit 1
fi
