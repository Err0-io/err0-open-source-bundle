#!/bin/bash
# Installs git hooks for the err0.io open source bundle
# This script copies hook scripts from hooks/ to .git/hooks/

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Installing git hooks..."

# Check if we're in a git repository
if [ ! -d "$REPO_ROOT/.git" ]; then
    echo "ERROR: Not in a git repository" >&2
    echo "Expected .git directory at: $REPO_ROOT/.git" >&2
    exit 1
fi

# Check if hooks directory exists
if [ ! -d "$REPO_ROOT/hooks" ]; then
    echo "ERROR: hooks/ directory not found" >&2
    echo "Expected directory at: $REPO_ROOT/hooks" >&2
    exit 1
fi

# Install pre-commit hook
if [ -f "$REPO_ROOT/hooks/pre-commit" ]; then
    cp "$REPO_ROOT/hooks/pre-commit" "$REPO_ROOT/.git/hooks/pre-commit"
    chmod +x "$REPO_ROOT/.git/hooks/pre-commit"
    echo "✅ Installed: pre-commit hook"
else
    echo "⚠️  WARNING: hooks/pre-commit not found, skipping" >&2
fi

# Check for other hooks to install
HOOK_COUNT=0
for hook in "$REPO_ROOT/hooks"/*; do
    if [ -f "$hook" ] && [ "$(basename "$hook")" != "pre-commit" ]; then
        HOOK_NAME=$(basename "$hook")
        cp "$hook" "$REPO_ROOT/.git/hooks/$HOOK_NAME"
        chmod +x "$REPO_ROOT/.git/hooks/$HOOK_NAME"
        echo "✅ Installed: $HOOK_NAME hook"
        HOOK_COUNT=$((HOOK_COUNT + 1))
    fi
done

# Summary
echo ""
if [ -f "$REPO_ROOT/.git/hooks/pre-commit" ]; then
    echo "✓ Git hooks installed successfully"
    echo ""
    echo "Pre-commit hook will protect against:"
    echo "  - Committing token files (tokens/, config/)"
    echo "  - Committing .env files"
    echo "  - Committing secrets (passwords, API keys)"
    echo "  - Committing AWS credentials or private keys"
else
    echo "✗ Hook installation failed" >&2
    exit 1
fi

exit 0
