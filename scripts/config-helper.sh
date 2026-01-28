#!/bin/bash
#
# config-helper.sh - Configuration loader and helper functions
#
# This script provides configuration management for err0.io scripts.
# It loads environment variables from .env file and provides helper functions.
#
# Usage:
#   source scripts/config-helper.sh
#
# Then use the following functions:
#   find_token_file <project>  - Find token file for project
#   get_config <var_name>      - Get configuration variable with defaults
#

# Get the repository root directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================================================
# Load .env file if present
# ============================================================================

if [ -f "$REPO_ROOT/.env" ]; then
    # Load .env file, ignoring comments and empty lines
    set -a
    source <(grep -v '^#' "$REPO_ROOT/.env" | grep -v '^[[:space:]]*$')
    set +a

    if [ "${ERR0_VERBOSE:-false}" = "true" ]; then
        echo "[config-helper] Loaded configuration from .env" >&2
    fi
fi

# ============================================================================
# Set default values for all configuration variables
# ============================================================================

# Server configuration
export ERR0_HOST="${ERR0_HOST:-localhost:8443}"
export ERR0_REALM_UUID="${ERR0_REALM_UUID:-}"

# Docker image configuration
export ERR0_DOCKER_IMAGE_LATEST="${ERR0_DOCKER_IMAGE_LATEST:-err0io/agent:latest}"
export ERR0_DOCKER_IMAGE_DEVELOP="${ERR0_DOCKER_IMAGE_DEVELOP:-err0io/agent:develop}"
export ERR0_DOCKER_IMAGE_LOCALDEV="${ERR0_DOCKER_IMAGE_LOCALDEV:-err0_io:err0_agent}"

# Token configuration
export ERR0_TOKEN_DIR="${ERR0_TOKEN_DIR:-$REPO_ROOT/tokens}"

# Docker configuration
export ERR0_DOCKER_NETWORK="${ERR0_DOCKER_NETWORK:-host}"
export ERR0_DOCKER_MOUNT="${ERR0_DOCKER_MOUNT:-/mnt}"

# Verbosity
export ERR0_VERBOSE="${ERR0_VERBOSE:-false}"

# ============================================================================
# Helper function: Find token file for a project
# ============================================================================
#
# Usage: find_token_file <project>
#
# Searches for token file in the following order:
# 1. Environment variable: ERR0_TOKEN_<PROJECT_UPPER>
# 2. Token directory: $ERR0_TOKEN_DIR/err0-<project>-*.json
# 3. Legacy directory: $REPO_ROOT/dev-localhost/err0-<project>-*.json
#
# Returns: Path to token file (via stdout)
# Exit code: 0 if found, 1 if not found
#
find_token_file() {
    local project="$1"

    if [ -z "$project" ]; then
        echo "ERROR: find_token_file requires project name as argument" >&2
        return 1
    fi

    # Convert project name to uppercase for environment variable
    local project_upper=$(echo "$project" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    local env_var_name="ERR0_TOKEN_${project_upper}"

    # Check for project-specific environment variable
    local env_token_path="${!env_var_name}"
    if [ -n "$env_token_path" ]; then
        if [ -f "$env_token_path" ]; then
            echo "$env_token_path"
            return 0
        else
            echo "WARNING: Token file specified in $env_var_name not found: $env_token_path" >&2
        fi
    fi

    # Search in token directory (case-insensitive for project name)
    local token_pattern="$ERR0_TOKEN_DIR/err0-${project}-*.json"
    local token_files=($(ls $token_pattern 2>/dev/null))

    if [ ${#token_files[@]} -gt 0 ]; then
        # If multiple files match, use the most recent one
        local latest_token=$(ls -t "${token_files[@]}" 2>/dev/null | head -n 1)
        echo "$latest_token"
        return 0
    fi

    # Fallback: Check legacy dev-localhost directory (for backward compatibility)
    local legacy_pattern="$REPO_ROOT/dev-localhost/err0-${project}-*.json"
    local legacy_files=($(ls $legacy_pattern 2>/dev/null))

    if [ ${#legacy_files[@]} -gt 0 ]; then
        local latest_legacy=$(ls -t "${legacy_files[@]}" 2>/dev/null | head -n 1)
        if [ "${ERR0_VERBOSE:-false}" = "true" ]; then
            echo "WARNING: Using legacy token from dev-localhost/. Consider moving to tokens/ directory." >&2
        fi
        echo "$latest_legacy"
        return 0
    fi

    # Not found
    echo "ERROR: No token file found for project: $project" >&2
    echo "ERROR: Searched in:" >&2
    echo "ERROR:   - Environment variable: $env_var_name" >&2
    echo "ERROR:   - Token directory: $token_pattern" >&2
    echo "ERROR:   - Legacy directory: $legacy_pattern" >&2
    echo "ERROR: See tokens/README.md for token setup instructions." >&2
    return 1
}

# ============================================================================
# Helper function: Get configuration variable with default
# ============================================================================
#
# Usage: get_config <var_name> [default_value]
#
# Returns: Value of configuration variable, or default if not set
#
get_config() {
    local var_name="$1"
    local default_value="$2"

    local value="${!var_name}"

    if [ -z "$value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# ============================================================================
# Helper function: Validate configuration
# ============================================================================
#
# Usage: validate_config
#
# Checks that required configuration is present.
# Exit code: 0 if valid, 1 if invalid
#
validate_config() {
    local errors=0

    # Check for .env file
    if [ ! -f "$REPO_ROOT/.env" ]; then
        echo "WARNING: .env file not found. Using default configuration." >&2
        echo "WARNING: Copy .env.template to .env and configure for your environment." >&2
    fi

    # Check for token directory
    if [ ! -d "$ERR0_TOKEN_DIR" ]; then
        echo "ERROR: Token directory not found: $ERR0_TOKEN_DIR" >&2
        errors=$((errors + 1))
    fi

    # Check if any token files exist
    local token_count=$(ls -1 "$ERR0_TOKEN_DIR"/*.json 2>/dev/null | wc -l)
    if [ "$token_count" -eq 0 ]; then
        echo "WARNING: No token files found in $ERR0_TOKEN_DIR" >&2
        echo "WARNING: See tokens/README.md for token setup instructions." >&2
    fi

    return $errors
}

# ============================================================================
# Helper function: Print configuration summary
# ============================================================================
#
# Usage: print_config
#
# Prints current configuration to stderr for debugging.
#
print_config() {
    echo "=== err0.io Configuration ===" >&2
    echo "ERR0_HOST:                 $ERR0_HOST" >&2
    echo "ERR0_REALM_UUID:           ${ERR0_REALM_UUID:-<not set>}" >&2
    echo "ERR0_DOCKER_IMAGE_LATEST:  $ERR0_DOCKER_IMAGE_LATEST" >&2
    echo "ERR0_DOCKER_IMAGE_DEVELOP: $ERR0_DOCKER_IMAGE_DEVELOP" >&2
    echo "ERR0_DOCKER_IMAGE_LOCALDEV: $ERR0_DOCKER_IMAGE_LOCALDEV" >&2
    echo "ERR0_TOKEN_DIR:            $ERR0_TOKEN_DIR" >&2
    echo "ERR0_DOCKER_NETWORK:       $ERR0_DOCKER_NETWORK" >&2
    echo "ERR0_DOCKER_MOUNT:         $ERR0_DOCKER_MOUNT" >&2
    echo "ERR0_VERBOSE:              $ERR0_VERBOSE" >&2
    echo "=============================" >&2
}

# ============================================================================
# Auto-validate if ERR0_VERBOSE is enabled
# ============================================================================

if [ "${ERR0_VERBOSE:-false}" = "true" ]; then
    print_config
    validate_config || true
fi

# Export functions so they're available to scripts that source this file
export -f find_token_file
export -f get_config
export -f validate_config
export -f print_config
