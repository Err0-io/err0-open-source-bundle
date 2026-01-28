#!/bin/bash
#
# err0agent-localdev-analyse.sh - Analyze error codes using err0.io agent (local build)
#
# Usage:
#   ./err0agent-localdev-analyse.sh <token-file> <project-directory>
#
# Example:
#   ./err0agent-localdev-analyse.sh tokens/err0-django-*.json django
#
# Environment Variables:
#   ERR0_DOCKER_IMAGE_LOCALDEV  - Docker image to use (default: err0_io:err0_agent)
#   ERR0_DOCKER_NETWORK         - Docker network mode (default: host)
#   ERR0_DOCKER_MOUNT           - Container mount point (default: /mnt)
#

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/scripts/config-helper.sh" ]; then
    source "$SCRIPT_DIR/scripts/config-helper.sh"
fi

# Use configured docker image or default
DOCKER_IMAGE="${ERR0_DOCKER_IMAGE_LOCALDEV:-err0_io:err0_agent}"
DOCKER_NETWORK="${ERR0_DOCKER_NETWORK:-host}"
DOCKER_MOUNT="${ERR0_DOCKER_MOUNT:-/mnt}"

# Check arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <token-file> <project-directory>" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  $0 tokens/err0-django-*.json django" >&2
    echo "" >&2
    echo "Configuration:" >&2
    echo "  Docker Image: $DOCKER_IMAGE" >&2
    echo "" >&2
    exit 1
fi

# Verify token file exists
if [ ! -f "$1" ]; then
    echo "ERROR: Token file not found: $1" >&2
    exit 1
fi

# Verify project directory exists
if [ ! -d "$2" ]; then
    echo "ERROR: Project directory not found: $2" >&2
    exit 1
fi

# Validate Docker is running
if ! docker ps >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running" >&2
    echo "" >&2
    echo "Please start Docker:" >&2
    echo "  - macOS/Windows: Start Docker Desktop" >&2
    echo "  - Linux: sudo systemctl start docker" >&2
    echo "" >&2
    exit 1
fi

# Show command (for debugging)
echo "/usr/local/bin/err0.sh --token $DOCKER_MOUNT/$1 --analyse --dirty $DOCKER_MOUNT/$2"

# Run (no pull for local images - using locally built image)
docker run --rm --network="$DOCKER_NETWORK" \
    --mount type=bind,source="$(pwd)",destination="$DOCKER_MOUNT" \
    "$DOCKER_IMAGE" \
    /usr/local/bin/err0.sh --token "$DOCKER_MOUNT/$1" --analyse --dirty "$DOCKER_MOUNT/$2"
