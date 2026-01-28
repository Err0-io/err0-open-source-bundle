#!/bin/bash
#
# dev-analyse.sh - Analyze error codes for all configured projects
#
# This script runs analyse operations on all projects listed in
# config/project-list.txt that have token files available.
#
# Usage:
#   ./dev-analyse.sh
#
# Environment Variables:
#   ERR0_TOKEN_DIR      - Token directory (default: ./tokens)
#   ERR0_VERBOSE        - Enable verbose output (default: false)
#   ERR0_TOKEN_<PROJECT> - Override token file for specific project
#

set -e  # Exit on error

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/scripts/config-helper.sh" ]; then
    source "$SCRIPT_DIR/scripts/config-helper.sh"
else
    echo "ERROR: config-helper.sh not found" >&2
    exit 1
fi

# Get project list
PROJECT_LIST_FILE="$SCRIPT_DIR/config/project-list.txt"
if [ ! -f "$PROJECT_LIST_FILE" ]; then
    echo "ERROR: Project list not found: $PROJECT_LIST_FILE" >&2
    exit 1
fi

# Statistics
TOTAL_PROJECTS=0
SUCCESSFUL_PROJECTS=0
SKIPPED_PROJECTS=0
FAILED_PROJECTS=0

echo "========================================"
echo "err0.io Bulk Analyse Operation"
echo "========================================"
echo ""

# Read projects from config file (skip comments and empty lines)
while IFS= read -r project || [ -n "$project" ]; do
    # Skip comments and empty lines
    [[ "$project" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$project" ]] && continue

    TOTAL_PROJECTS=$((TOTAL_PROJECTS + 1))

    echo "----------------------------------------"
    echo "Project: $project"
    echo "----------------------------------------"

    # Check if project directory exists
    if [ ! -d "$project" ]; then
        echo "⚠️  SKIP: Project directory not found: $project"
        SKIPPED_PROJECTS=$((SKIPPED_PROJECTS + 1))
        echo ""
        continue
    fi

    # Find token file for project
    TOKEN_FILE=$(find_token_file "$project" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$TOKEN_FILE" ]; then
        echo "⚠️  SKIP: No token file found for project: $project"
        echo "   Generate a token and place it in $ERR0_TOKEN_DIR/"
        SKIPPED_PROJECTS=$((SKIPPED_PROJECTS + 1))
        echo ""
        continue
    fi

    echo "Token: $TOKEN_FILE"
    echo "Running analyse operation..."

    # Run analyse operation
    if ./err0agent-dev-analyse.sh "$TOKEN_FILE" "$project"; then
        echo "✅ SUCCESS: $project"
        SUCCESSFUL_PROJECTS=$((SUCCESSFUL_PROJECTS + 1))
    else
        echo "❌ FAILED: $project"
        FAILED_PROJECTS=$((FAILED_PROJECTS + 1))
    fi

    echo ""
done < "$PROJECT_LIST_FILE"

# Summary
echo "========================================"
echo "Summary"
echo "========================================"
echo "Total projects:      $TOTAL_PROJECTS"
echo "Successful:          $SUCCESSFUL_PROJECTS"
echo "Skipped:             $SKIPPED_PROJECTS"
echo "Failed:              $FAILED_PROJECTS"
echo ""

# Exit with error if any projects failed
if [ $FAILED_PROJECTS -gt 0 ]; then
    echo "⚠️  Some projects failed. See output above for details."
    exit 1
fi

echo "✅ All projects completed successfully"
exit 0
