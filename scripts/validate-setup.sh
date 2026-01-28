#!/bin/bash
#
# validate-setup.sh - Validate err0.io test bundle setup
#
# This script checks that your environment is properly configured
# to run the err0.io test bundle.
#
# Usage:
#   ./scripts/validate-setup.sh [--verbose]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0
CHECKS_TOTAL=0

# Verbose mode
VERBOSE=false
if [[ "$1" == "--verbose" ]]; then
    VERBOSE=true
fi

# Get script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_check() {
    local message="$1"
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    if [ "$VERBOSE" = true ]; then
        echo -n "Checking: $message... "
    fi
}

print_pass() {
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    if [ "$VERBOSE" = true ]; then
        echo -e "${GREEN}✓ PASS${NC}"
    else
        echo -e "${GREEN}✓${NC} $1"
    fi
}

print_fail() {
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
    echo -e "${RED}✗ FAIL${NC}: $1"
}

print_warning() {
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
    echo -e "${YELLOW}⚠ WARNING${NC}: $1"
}

print_info() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}ℹ${NC} $1"
    fi
}

# ============================================================================
# Validation Checks
# ============================================================================

validate_prerequisites() {
    print_header "Prerequisites"

    # Check Docker
    print_check "Docker installed"
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        print_pass "Docker installed (version $DOCKER_VERSION)"

        # Check Docker is running
        print_check "Docker daemon running"
        if docker ps >/dev/null 2>&1; then
            print_pass "Docker daemon is running"
        else
            print_fail "Docker daemon is not running. Start Docker and try again."
        fi
    else
        print_fail "Docker is not installed. See SETUP.md for installation instructions."
    fi

    # Check Git
    print_check "Git installed"
    if command -v git >/dev/null 2>&1; then
        GIT_VERSION=$(git --version | awk '{print $3}')
        GIT_MAJOR=$(echo "$GIT_VERSION" | cut -d. -f1)
        GIT_MINOR=$(echo "$GIT_VERSION" | cut -d. -f2)

        if [ "$GIT_MAJOR" -gt 2 ] || ([ "$GIT_MAJOR" -eq 2 ] && [ "$GIT_MINOR" -ge 13 ]); then
            print_pass "Git installed (version $GIT_VERSION)"
        else
            print_warning "Git version $GIT_VERSION found. Version 2.13+ recommended for submodule support."
        fi
    else
        print_fail "Git is not installed. Install Git and try again."
    fi

    # Check Perl
    print_check "Perl installed"
    if command -v perl >/dev/null 2>&1; then
        PERL_VERSION=$(perl --version | grep -oP 'v\d+\.\d+\.\d+' | head -1)
        print_pass "Perl installed ($PERL_VERSION)"
    else
        print_warning "Perl is not installed. Required for test scripts (soak-test.pl, etc.)"
    fi
}

validate_repository() {
    print_header "Repository Structure"

    # Check we're in the right directory
    print_check "In repository root"
    if [ -f "$REPO_ROOT/README.md" ] && [ -f "$REPO_ROOT/.gitmodules" ]; then
        print_pass "Repository root detected"
    else
        print_fail "Not in repository root. Run from: /path/to/open-source-bundle"
        return
    fi

    # Check critical files exist
    print_check "Critical files present"
    local missing_files=()
    for file in .gitignore .gitmodules README.md SETUP.md .env.template; do
        if [ ! -f "$REPO_ROOT/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        print_pass "All critical files present"
    else
        print_fail "Missing files: ${missing_files[*]}"
    fi

    # Check critical directories exist
    print_check "Critical directories present"
    local missing_dirs=()
    for dir in config scripts tokens; do
        if [ ! -d "$REPO_ROOT/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -eq 0 ]; then
        print_pass "All critical directories present"
    else
        print_fail "Missing directories: ${missing_dirs[*]}"
    fi

    # Check scripts are executable
    print_check "Scripts are executable"
    local non_executable=()
    for script in err0agent-insert.sh err0agent-analyse.sh dev-insert.sh dev-analyse.sh; do
        if [ -f "$REPO_ROOT/$script" ] && [ ! -x "$REPO_ROOT/$script" ]; then
            non_executable+=("$script")
        fi
    done

    if [ ${#non_executable[@]} -eq 0 ]; then
        print_pass "All scripts are executable"
    else
        print_warning "Non-executable scripts: ${non_executable[*]}. Run: chmod +x *.sh"
    fi
}

validate_configuration() {
    print_header "Configuration"

    # Check .env file exists
    print_check ".env configuration file"
    if [ -f "$REPO_ROOT/.env" ]; then
        print_pass ".env file exists"

        # Load configuration
        set -a
        source "$REPO_ROOT/.env" 2>/dev/null || true
        set +a

        # Check ERR0_HOST
        print_check "ERR0_HOST configured"
        if [ -n "$ERR0_HOST" ]; then
            print_pass "ERR0_HOST set to: $ERR0_HOST"
        else
            print_warning "ERR0_HOST not set in .env (will use default: localhost:8443)"
        fi

        # Check ERR0_REALM_UUID
        print_check "ERR0_REALM_UUID configured"
        if [ -n "$ERR0_REALM_UUID" ]; then
            print_pass "ERR0_REALM_UUID is configured"
        else
            print_warning "ERR0_REALM_UUID not set in .env (may cause authentication issues)"
        fi
    else
        print_warning ".env file not found. Create from template: cp .env.template .env"
    fi

    # Check config-helper.sh exists and is valid
    print_check "config-helper.sh script"
    if [ -f "$REPO_ROOT/scripts/config-helper.sh" ]; then
        if bash -n "$REPO_ROOT/scripts/config-helper.sh" 2>/dev/null; then
            print_pass "config-helper.sh is valid"
        else
            print_fail "config-helper.sh has syntax errors"
        fi
    else
        print_fail "scripts/config-helper.sh not found"
    fi

    # Check project list
    print_check "Project list configuration"
    if [ -f "$REPO_ROOT/config/project-list.txt" ]; then
        PROJECT_COUNT=$(grep -v "^#" "$REPO_ROOT/config/project-list.txt" | grep -v "^$" | wc -l | tr -d ' ')
        print_pass "Project list found ($PROJECT_COUNT projects)"
    else
        print_fail "config/project-list.txt not found"
    fi
}

validate_tokens() {
    print_header "Authentication Tokens"

    # Check token directory exists
    print_check "Token directory"
    if [ -d "$REPO_ROOT/tokens" ]; then
        print_pass "tokens/ directory exists"

        # Check permissions
        PERMS=$(stat -f "%OLp" "$REPO_ROOT/tokens" 2>/dev/null || stat -c "%a" "$REPO_ROOT/tokens" 2>/dev/null)
        if [ -n "$PERMS" ]; then
            print_info "tokens/ permissions: $PERMS"
        fi
    else
        print_fail "tokens/ directory not found. Create it: mkdir -p tokens"
    fi

    # Count token files
    print_check "Token files"
    TOKEN_COUNT=$(ls -1 "$REPO_ROOT/tokens"/*.json 2>/dev/null | wc -l | tr -d ' ')
    LEGACY_COUNT=$(ls -1 "$REPO_ROOT/dev-localhost"/*.json 2>/dev/null | wc -l | tr -d ' ')

    if [ "$TOKEN_COUNT" -gt 0 ]; then
        print_pass "Found $TOKEN_COUNT token file(s) in tokens/"
    elif [ "$LEGACY_COUNT" -gt 0 ]; then
        print_warning "No tokens in tokens/, but found $LEGACY_COUNT in dev-localhost/ (legacy location)"
    else
        print_warning "No token files found. Generate tokens and place in tokens/ directory."
    fi

    # Validate token file format (if any exist)
    if [ "$TOKEN_COUNT" -gt 0 ]; then
        print_check "Token file format"
        TOKEN_FILE=$(ls "$REPO_ROOT/tokens"/*.json 2>/dev/null | head -1)
        if command -v jq >/dev/null 2>&1; then
            if jq -e '.host and .realm_uuid and .prj_uuid and .token_uuid and .token_value' "$TOKEN_FILE" >/dev/null 2>&1; then
                print_pass "Token file format is valid"
            else
                print_warning "Token file may be missing required fields"
            fi
        elif command -v python3 >/dev/null 2>&1; then
            if python3 -m json.tool < "$TOKEN_FILE" >/dev/null 2>&1; then
                print_pass "Token file is valid JSON"
            else
                print_fail "Token file is not valid JSON"
            fi
        else
            print_info "Cannot validate JSON (jq or python3 not available)"
        fi
    fi

    # Check token files are gitignored
    print_check "Token files are gitignored"
    if git check-ignore "$REPO_ROOT/tokens"/*.json >/dev/null 2>&1; then
        print_pass "Token files are properly gitignored"
    else
        if [ "$TOKEN_COUNT" -eq 0 ]; then
            print_info "No token files to check"
        else
            print_fail "Token files are NOT gitignored! This is a security risk!"
        fi
    fi
}

validate_submodules() {
    print_header "Git Submodules"

    # Check .gitmodules exists
    print_check ".gitmodules file"
    if [ -f "$REPO_ROOT/.gitmodules" ]; then
        SUBMODULE_COUNT=$(git config --file "$REPO_ROOT/.gitmodules" --get-regexp "^submodule\." | grep "\.path" | wc -l | tr -d ' ')
        print_pass ".gitmodules found ($SUBMODULE_COUNT submodules configured)"
    else
        print_fail ".gitmodules not found"
        return
    fi

    # Count initialized submodules
    print_check "Initialized submodules"
    INITIALIZED_COUNT=$(git submodule status | grep -v "^-" | wc -l | tr -d ' ')

    if [ "$INITIALIZED_COUNT" -gt 0 ]; then
        print_pass "$INITIALIZED_COUNT submodule(s) initialized"
    else
        print_warning "No submodules initialized. Run: git submodule update --init <project>"
    fi

    # Check for relative URLs (should all be public now)
    print_check "Submodule URLs are public"
    RELATIVE_COUNT=$(git config --file "$REPO_ROOT/.gitmodules" --get-regexp "url" | grep -c "\.\." || true)

    if [ "$RELATIVE_COUNT" -eq 0 ]; then
        print_pass "All submodule URLs are public (no relative paths)"
    elif [ "$RELATIVE_COUNT" -eq 1 ]; then
        print_warning "1 submodule uses relative URL (likely zf2-orders, which is internal)"
    else
        print_warning "$RELATIVE_COUNT submodules use relative URLs"
    fi
}

validate_docker_images() {
    print_header "Docker Images"

    # Check if we can access Docker
    if ! command -v docker >/dev/null 2>&1 || ! docker ps >/dev/null 2>&1; then
        print_info "Docker not accessible, skipping image checks"
        return
    fi

    # Check for err0 images
    print_check "err0io/agent:latest image"
    if docker images | grep -q "err0io/agent.*latest"; then
        print_pass "err0io/agent:latest image available locally"
    else
        print_info "err0io/agent:latest not cached (will be pulled on first use)"
    fi

    print_check "err0io/agent:develop image"
    if docker images | grep -q "err0io/agent.*develop"; then
        print_pass "err0io/agent:develop image available locally"
    else
        print_info "err0io/agent:develop not cached (will be pulled on first use)"
    fi

    # Test pulling an image
    print_check "Can pull Docker images"
    if timeout 10 docker pull hello-world >/dev/null 2>&1; then
        print_pass "Can successfully pull Docker images"
    else
        print_warning "Unable to pull Docker images (network issue or timeout)"
    fi
}

validate_security() {
    print_header "Security Checks"

    # Check .gitignore patterns
    print_check ".gitignore security patterns"
    if grep -q "/tokens/\*\.json" "$REPO_ROOT/.gitignore" && grep -q "/dev-localhost/\*\.json" "$REPO_ROOT/.gitignore"; then
        print_pass ".gitignore includes token file patterns"
    else
        print_fail ".gitignore missing token file patterns! Update .gitignore immediately."
    fi

    # Check if .env is gitignored
    print_check ".env file is gitignored"
    if [ -f "$REPO_ROOT/.env" ]; then
        if git check-ignore "$REPO_ROOT/.env" >/dev/null 2>&1; then
            print_pass ".env is properly gitignored"
        else
            print_fail ".env is NOT gitignored! This is a security risk!"
        fi
    else
        print_info ".env file doesn't exist yet"
    fi

    # Check if pre-commit hook is installed
    print_check "Pre-commit hook installed"
    if [ -f "$REPO_ROOT/.git/hooks/pre-commit" ]; then
        if [ -x "$REPO_ROOT/.git/hooks/pre-commit" ]; then
            # Check if it's our hook (contains token detection)
            if grep -q "token" "$REPO_ROOT/.git/hooks/pre-commit" 2>/dev/null; then
                print_pass "Pre-commit hook installed and active"
            else
                print_warning "Pre-commit hook installed but may not be ours"
            fi
        else
            print_warning "Pre-commit hook exists but is not executable"
        fi
    else
        print_fail "Pre-commit hook not installed! Run: ./scripts/install-hooks.sh"
    fi

    # Check if pre-commit hook source exists
    print_check "Pre-commit hook source file"
    if [ -f "$REPO_ROOT/hooks/pre-commit" ]; then
        print_pass "hooks/pre-commit source file exists"
    else
        print_fail "hooks/pre-commit source file missing"
    fi

    # Check for secrets in git history
    print_check "No secrets in current staged files"
    if git diff --cached | grep -qi "token_value\|password\|secret"; then
        print_fail "Possible secrets found in staged changes!"
    else
        print_pass "No obvious secrets in staged changes"
    fi

    # Check file permissions
    if [ -f "$REPO_ROOT/.env" ]; then
        print_check ".env file permissions"
        PERMS=$(stat -f "%OLp" "$REPO_ROOT/.env" 2>/dev/null || stat -c "%a" "$REPO_ROOT/.env" 2>/dev/null)
        if [ "$PERMS" = "600" ] || [ "$PERMS" = "400" ]; then
            print_pass ".env has secure permissions ($PERMS)"
        else
            print_warning ".env has permissions $PERMS (recommend 600). Run: chmod 600 .env"
        fi
    fi
}

validate_functionality() {
    print_header "Functionality Tests"

    # Test config-helper.sh can be sourced
    print_check "config-helper.sh can be loaded"
    if bash -c "source '$REPO_ROOT/scripts/config-helper.sh' 2>/dev/null"; then
        print_pass "config-helper.sh loads successfully"
    else
        print_fail "config-helper.sh cannot be loaded (syntax error?)"
    fi

    # Test script help messages
    print_check "Scripts show help messages"
    if [ -x "$REPO_ROOT/err0agent-insert.sh" ]; then
        if "$REPO_ROOT/err0agent-insert.sh" 2>&1 | grep -q "Usage:"; then
            print_pass "Scripts provide help messages"
        else
            print_warning "Scripts may not have proper usage messages"
        fi
    fi

    # Test that we can list projects
    print_check "Can read project list"
    if [ -f "$REPO_ROOT/config/project-list.txt" ]; then
        PROJECT_COUNT=$(grep -v "^#" "$REPO_ROOT/config/project-list.txt" | grep -v "^$" | wc -l | tr -d ' ')
        if [ "$PROJECT_COUNT" -gt 0 ]; then
            print_pass "Can read $PROJECT_COUNT projects from config"
        else
            print_fail "project-list.txt appears to be empty"
        fi
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    cd "$REPO_ROOT"

    echo ""
    echo "================================================================"
    echo "  err0.io Open Source Test Bundle - Setup Validation"
    echo "================================================================"
    echo ""
    echo "Repository: $REPO_ROOT"
    echo "Date: $(date)"
    echo ""

    # Run all validation checks
    validate_prerequisites
    validate_repository
    validate_configuration
    validate_tokens
    validate_submodules
    validate_docker_images
    validate_security
    validate_functionality

    # Print summary
    print_header "Summary"

    echo "Total checks: $CHECKS_TOTAL"
    echo -e "${GREEN}Passed:       $CHECKS_PASSED${NC}"
    echo -e "${YELLOW}Warnings:     $CHECKS_WARNING${NC}"
    echo -e "${RED}Failed:       $CHECKS_FAILED${NC}"
    echo ""

    # Determine overall status
    if [ $CHECKS_FAILED -eq 0 ]; then
        if [ $CHECKS_WARNING -eq 0 ]; then
            echo -e "${GREEN}✓ Setup validation PASSED${NC}"
            echo ""
            echo "Your environment is fully configured and ready to use!"
            echo ""
            echo "Next steps:"
            echo "  1. Initialize submodules: git submodule update --init <project>"
            echo "  2. Run first test: ./err0agent-dev-insert.sh tokens/err0-<project>-*.json <project>"
            echo "  3. See SETUP.md for detailed usage instructions"
            echo ""
            exit 0
        else
            echo -e "${YELLOW}⚠ Setup validation PASSED with warnings${NC}"
            echo ""
            echo "Your environment is mostly configured, but some non-critical issues were found."
            echo "Review warnings above and address them if needed."
            echo ""
            exit 0
        fi
    else
        echo -e "${RED}✗ Setup validation FAILED${NC}"
        echo ""
        echo "Your environment has issues that need to be addressed."
        echo "Review failed checks above and fix them before proceeding."
        echo ""
        echo "For help, see:"
        echo "  - SETUP.md for setup instructions"
        echo "  - README.md for troubleshooting"
        echo "  - Or open an issue: https://github.com/err0io/open-source-bundle/issues"
        echo ""
        exit 1
    fi
}

# Run main function
main "$@"
