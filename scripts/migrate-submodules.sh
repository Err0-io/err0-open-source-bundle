#!/bin/bash
#
# migrate-submodules.sh - Migrate submodule URLs from relative to public
#
# This script updates .gitmodules to use public GitHub URLs instead of
# relative URLs, enabling external users to clone the repository.
#
# Usage:
#   ./scripts/migrate-submodules.sh [--dry-run] [--rollback]
#
# Options:
#   --dry-run   Show what would be changed without making changes
#   --rollback  Restore .gitmodules from backup
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GITMODULES="$REPO_ROOT/.gitmodules"
BACKUP="$GITMODULES.backup"
MAPPINGS="$REPO_ROOT/config/submodule-mappings.txt"

DRY_RUN=false
ROLLBACK=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --rollback)
            ROLLBACK=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--dry-run] [--rollback]" >&2
            exit 1
            ;;
    esac
done

# ============================================================================
# Rollback Mode
# ============================================================================

if [ "$ROLLBACK" = true ]; then
    if [ ! -f "$BACKUP" ]; then
        echo "ERROR: Backup file not found: $BACKUP" >&2
        exit 1
    fi

    echo "Rolling back .gitmodules from backup..."
    cp "$BACKUP" "$GITMODULES"
    echo "✅ Rollback complete"
    echo ""
    echo "To sync submodules with restored URLs:"
    echo "  git submodule sync"
    echo "  git submodule update --init --recursive"
    exit 0
fi

# ============================================================================
# Validation
# ============================================================================

if [ ! -f "$GITMODULES" ]; then
    echo "ERROR: .gitmodules not found: $GITMODULES" >&2
    exit 1
fi

if [ ! -f "$MAPPINGS" ]; then
    echo "ERROR: Submodule mappings not found: $MAPPINGS" >&2
    exit 1
fi

# ============================================================================
# Backup
# ============================================================================

if [ "$DRY_RUN" = false ]; then
    echo "Creating backup: $BACKUP"
    cp "$GITMODULES" "$BACKUP"
    echo ""
fi

# ============================================================================
# Migration
# ============================================================================

echo "========================================"
echo "Submodule URL Migration"
echo "========================================"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN MODE - No changes will be made"
    echo ""
fi

TOTAL_SUBMODULES=0
MIGRATED_SUBMODULES=0
SKIPPED_SUBMODULES=0
FAILED_SUBMODULES=0

# Read mappings (skip comments and empty lines)
while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    # Parse submodule name and URL
    SUBMODULE=$(echo "$line" | awk '{print $1}')
    NEW_URL=$(echo "$line" | awk '{print $2}')

    TOTAL_SUBMODULES=$((TOTAL_SUBMODULES + 1))

    echo "Submodule: $SUBMODULE"

    # Check if mapping is incomplete
    if [ "$NEW_URL" = "INTERNAL_PROJECT_NEEDS_PUBLIC_FORK" ]; then
        echo "⚠️  SKIP: $SUBMODULE - Internal project, needs public fork"
        SKIPPED_SUBMODULES=$((SKIPPED_SUBMODULES + 1))
        echo ""
        continue
    fi

    # Get current URL from .gitmodules
    CURRENT_URL=$(git config -f "$GITMODULES" "submodule.$SUBMODULE.url" 2>/dev/null || echo "")

    if [ -z "$CURRENT_URL" ]; then
        echo "⚠️  SKIP: $SUBMODULE - Not found in .gitmodules"
        SKIPPED_SUBMODULES=$((SKIPPED_SUBMODULES + 1))
        echo ""
        continue
    fi

    echo "  Current URL: $CURRENT_URL"
    echo "  New URL:     $NEW_URL"

    # Check if already migrated
    if [ "$CURRENT_URL" = "$NEW_URL" ]; then
        echo "  ℹ️  Already migrated"
        MIGRATED_SUBMODULES=$((MIGRATED_SUBMODULES + 1))
        echo ""
        continue
    fi

    # Update URL
    if [ "$DRY_RUN" = false ]; then
        if git config -f "$GITMODULES" "submodule.$SUBMODULE.url" "$NEW_URL"; then
            echo "  ✅ Migrated"
            MIGRATED_SUBMODULES=$((MIGRATED_SUBMODULES + 1))
        else
            echo "  ❌ Failed to update"
            FAILED_SUBMODULES=$((FAILED_SUBMODULES + 1))
        fi
    else
        echo "  ✓ Would migrate"
        MIGRATED_SUBMODULES=$((MIGRATED_SUBMODULES + 1))
    fi

    echo ""
done < "$MAPPINGS"

# ============================================================================
# Summary
# ============================================================================

echo "========================================"
echo "Summary"
echo "========================================"
echo "Total submodules:    $TOTAL_SUBMODULES"
echo "Migrated:            $MIGRATED_SUBMODULES"
echo "Skipped:             $SKIPPED_SUBMODULES"
echo "Failed:              $FAILED_SUBMODULES"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "This was a dry run. No changes were made."
    echo "Run without --dry-run to apply changes."
    exit 0
fi

if [ $FAILED_SUBMODULES -gt 0 ]; then
    echo "⚠️  Some submodules failed to migrate."
    echo "Backup available at: $BACKUP"
    exit 1
fi

echo "✅ Migration complete!"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff .gitmodules"
echo "  2. Commit changes: git add .gitmodules && git commit -m 'Migrate submodules to public URLs'"
echo "  3. Sync submodules: git submodule sync"
echo "  4. Test clone:     cd /tmp && git clone <repo-url> test-clone"
echo ""
echo "To rollback:"
echo "  ./scripts/migrate-submodules.sh --rollback"

exit 0
