# Setup Guide

This comprehensive guide walks you through setting up the err0.io Open Source Test Bundle from scratch. Follow these steps to go from a fresh clone to running your first test.

**Estimated time:** 30-60 minutes (depending on download speeds and submodule selection)

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installing Prerequisites](#installing-prerequisites)
3. [Cloning the Repository](#cloning-the-repository)
4. [Initializing Submodules](#initializing-submodules)
5. [Configuring the Environment](#configuring-the-environment)
6. [Setting Up Authentication](#setting-up-authentication)
7. [Validating Your Setup](#validating-your-setup)
8. [Running Your First Test](#running-your-first-test)
9. [Advanced Configuration](#advanced-configuration)
10. [Platform-Specific Notes](#platform-specific-notes)

---

## System Requirements

### Minimum Requirements
- **CPU:** 2 cores
- **RAM:** 4 GB
- **Disk Space:** 60 GB (for all submodules) or 5 GB (for minimal setup)
- **Network:** Stable internet connection for Docker image downloads

### Recommended Requirements
- **CPU:** 4+ cores
- **RAM:** 8+ GB
- **Disk Space:** 100 GB (for comfortable development)
- **Network:** High-speed connection for faster setup

### Supported Operating Systems
- **Linux:** Ubuntu 20.04+, Debian 10+, RHEL 8+, Fedora 35+
- **macOS:** macOS 11 (Big Sur) or later
- **Windows:** Windows 10/11 with WSL2 or Git Bash

---

## Installing Prerequisites

### 1. Install Docker

Docker is required to run the err0 agent in containers.

#### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt-get update

# Install dependencies
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

#### macOS
```bash
# Download Docker Desktop from:
# https://docs.docker.com/desktop/install/mac-install/

# Or install via Homebrew:
brew install --cask docker

# Start Docker Desktop from Applications folder
# Wait for Docker to finish starting (icon in menu bar)
```

#### Windows
```bash
# Option 1: Docker Desktop with WSL2 (Recommended)
# 1. Enable WSL2: wsl --install
# 2. Download Docker Desktop from:
#    https://docs.docker.com/desktop/install/windows-install/
# 3. Install and restart

# Option 2: Git Bash + Docker Toolbox (Legacy)
# Not recommended for new installations
```

**Verify Docker installation:**
```bash
docker --version
docker run hello-world
```

Expected output: Docker version information and "Hello from Docker!" message.

### 2. Install Git

Git 2.13+ is required for submodule management.

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get install -y git

# RHEL/Fedora
sudo dnf install -y git
```

#### macOS
```bash
# Using Homebrew
brew install git

# Or use Xcode Command Line Tools
xcode-select --install
```

#### Windows
```bash
# Download Git for Windows from:
# https://git-scm.com/download/win

# Or use Chocolatey:
choco install git
```

**Verify Git installation:**
```bash
git --version
```

Expected output: `git version 2.13.0` or higher.

### 3. Verify Perl (Usually Pre-installed)

#### Check if Perl is installed
```bash
perl --version
```

#### Install if needed

**Linux:**
```bash
sudo apt-get install -y perl  # Ubuntu/Debian
sudo dnf install -y perl       # RHEL/Fedora
```

**macOS:**
```bash
# Perl comes pre-installed on macOS
# If needed, install via Homebrew:
brew install perl
```

**Windows:**
```bash
# Use Strawberry Perl:
# https://strawberryperl.com/

# Or via Chocolatey:
choco install strawberryperl
```

---

## Cloning the Repository

### 1. Choose a Location

Pick a directory with sufficient disk space:

```bash
# Example locations:
cd ~/projects              # Home directory
cd /opt/err0              # System-wide location (Linux)
cd /Users/$USER/Development  # macOS
```

### 2. Clone the Repository

```bash
git clone https://github.com/err0io/open-source-bundle.git
cd open-source-bundle
```

**What this downloads:**
- Repository structure and scripts: ~5 MB
- Submodule configurations (not content): ~1 MB
- Total: ~6 MB

### 3. Verify Clone

```bash
ls -la
```

You should see:
- Script files: `err0agent-*.sh`, `dev-*.sh`, `*.pl`
- Config directories: `config/`, `scripts/`, `tokens/`
- Submodule directories (empty): `django/`, `kubernetes/`, etc.

---

## Initializing Submodules

You have three options for initializing submodules:

### Option 1: Initialize Specific Projects (Recommended for First Time)

Start with a few small projects to test your setup:

```bash
# Initialize 3 small projects (~500 MB total)
git submodule update --init ratpack strapi cerbos

# List of project sizes (approximate):
# Small (<100 MB): ratpack, strapi, cerbos, leptos, vapor
# Medium (100-500 MB): django, rails, nodejs, moodle, drupal
# Large (500 MB-2 GB): kubernetes, pytorch, bitcoin, servo
# Very Large (2-5 GB): spring-framework, Signal-Android, Telegram-iOS
```

### Option 2: Initialize All Projects

Download all 31 projects (~50 GB):

```bash
git submodule update --init --recursive
```

**Warning:** This will take 30-60 minutes on a fast connection.

### Option 3: Initialize by Category

Initialize projects from specific categories:

```bash
# Backend frameworks (Python, Ruby)
git submodule update --init django rails strapi

# JVM frameworks
git submodule update --init spring-framework ktor ratpack

# Mobile apps
git submodule update --init Signal-iOS Telegram UTM

# CMS platforms
git submodule update --init WordPress drupal moodle
```

### Track Initialization Progress

```bash
# See which submodules are initialized
git submodule status

# Count initialized submodules
git submodule status | grep -v "^-" | wc -l
```

### Troubleshooting Submodule Initialization

**Problem: Submodule clone fails**
```bash
# Skip the problematic submodule and continue
git submodule update --init --recursive || true

# Or initialize individually
git submodule update --init django
git submodule update --init kubernetes
```

**Problem: Network timeout**
```bash
# Increase Git timeout
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 600

# Retry initialization
git submodule update --init --recursive
```

---

## Configuring the Environment

### 1. Create Configuration File

```bash
# Copy template
cp .env.template .env

# Edit configuration
nano .env  # or vim, code, emacs, etc.
```

### 2. Configure Required Settings

At minimum, set these variables:

```bash
# err0.io server (required)
ERR0_HOST=your-server.err0.io:8443

# Realm UUID (required)
ERR0_REALM_UUID=ea3cd958-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Where to find these values:**

1. **ERR0_HOST:**
   - For production: Your organization's err0 server URL
   - For localhost testing: `localhost:8443`
   - For cloud: `cloud.err0.io:8443`

2. **ERR0_REALM_UUID:**
   - Log into your err0 server web interface
   - Navigate to: Settings → Organization → Realm Information
   - Copy the UUID value

### 3. Configure Optional Settings

```bash
# Docker images (default values usually work)
ERR0_DOCKER_IMAGE_LATEST=err0io/agent:latest
ERR0_DOCKER_IMAGE_DEVELOP=err0io/agent:develop
ERR0_DOCKER_IMAGE_LOCALDEV=err0_io:err0_agent

# Token directory (default: ./tokens)
ERR0_TOKEN_DIR=./tokens

# Enable verbose output for debugging
ERR0_VERBOSE=false
```

### 4. Verify Configuration

```bash
# Check that .env exists and is readable
cat .env | grep -v "^#" | grep -v "^$"

# Verify Docker network connectivity
docker network ls
```

---

## Setting Up Authentication

### Method 1: Using err0.io Web Interface (Recommended)

#### Step 1: Log Into err0 Server

```bash
# Open your err0 server in browser
# Example: https://your-server.err0.io:8443
```

#### Step 2: Create Project Tokens

For each project you want to test:

1. Navigate to: **Projects** → **Select Project** → **Settings** → **Tokens**
2. Click **"Generate New Token"**
3. Set permissions: `Insert` and `Analyse`
4. Set expiration: `90 days` (recommended)
5. Click **"Create Token"**
6. Download the JSON file

#### Step 3: Move Tokens to Repository

```bash
# Move downloaded tokens to tokens/ directory
mv ~/Downloads/err0-django-*.json tokens/
mv ~/Downloads/err0-kubernetes-*.json tokens/

# Verify tokens are in place
ls -la tokens/*.json
```

### Method 2: Using API (Advanced)

```bash
# Generate token via API
curl -X POST https://your-server.err0.io/api/v1/tokens \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "project_uuid": "PROJECT_UUID",
    "permissions": ["insert", "analyse"],
    "expires_in_days": 90
  }' \
  -o tokens/err0-project-$(date +%Y%m%d)-$(uuidgen).json
```

### Method 3: Using Existing Tokens (Migration)

If you have existing tokens in `dev-localhost/`:

```bash
# Tokens still work from legacy location
# Scripts check both locations for backward compatibility

# Optional: Copy to new location
cp dev-localhost/*.json tokens/

# Or: Set environment variable to use legacy location
echo "ERR0_TOKEN_DIR=./dev-localhost" >> .env
```

### Verify Token Files

```bash
# Check token file format
python3 -m json.tool < tokens/err0-django-*.json

# Verify required fields
jq '.host, .realm_uuid, .prj_uuid, .token_uuid' tokens/err0-django-*.json

# Check token count
ls -1 tokens/*.json 2>/dev/null | wc -l
```

---

## Validating Your Setup

### 1. Run Setup Validator (Future)

```bash
# This script will be created in Phase 5
./scripts/validate-setup.sh
```

### 2. Manual Validation Checklist

Run through this checklist:

```bash
# ✓ Docker is installed and running
docker --version && docker ps

# ✓ Git is installed (2.13+)
git --version

# ✓ Perl is installed
perl --version

# ✓ Repository is cloned
pwd  # Should be in open-source-bundle directory

# ✓ At least one submodule is initialized
git submodule status | grep -v "^-" | head -5

# ✓ Configuration file exists
test -f .env && echo "✓ .env exists" || echo "✗ .env missing"

# ✓ Token directory exists
test -d tokens && echo "✓ tokens/ exists" || echo "✗ tokens/ missing"

# ✓ At least one token file exists
ls tokens/*.json >/dev/null 2>&1 && echo "✓ Tokens found" || echo "✗ No tokens"

# ✓ Scripts are executable
test -x err0agent-dev-insert.sh && echo "✓ Scripts executable" || chmod +x *.sh

# ✓ Docker can pull err0 image
docker pull err0io/agent:develop
```

---

## Running Your First Test

### 1. Start with a Small Project

Choose a small, fast project for your first test:

```bash
# Initialize a small project (if not already done)
git submodule update --init ratpack

# Verify submodule is initialized
ls -la ratpack/
```

### 2. Run Insert Operation

```bash
# Insert error codes into ratpack
./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack

# This will:
# 1. Pull Docker image (if not cached)
# 2. Mount the repository into container
# 3. Run err0 agent to insert codes
# 4. Save changes to local files
```

**Expected output:**
```
/usr/local/bin/err0.sh --token /mnt/tokens/err0-ratpack-*.json --insert /mnt/ratpack
develop: Pulling from err0io/agent
[...]
Status: Downloaded newer image for err0io/agent:develop

[Analysing project structure...]
[Inserting error codes...]
✓ Inserted 47 error codes
✓ Modified 23 files
```

### 3. Review Changes

```bash
# See what changed
cd ratpack
git status
git diff

# Count modified files
git status --porcelain | wc -l
```

### 4. Run Analyse Operation

```bash
# Analyze uncommitted changes
./err0agent-dev-analyse.sh tokens/err0-ratpack-*.json ratpack

# Expected output: List of inserted codes and their locations
```

### 5. Run Check Operation

```bash
# Verify codes are canonical
./err0agent-dev-check.sh tokens/err0-ratpack-*.json ratpack

# Expected output: "All codes are canonical" or list of issues
```

### 6. Commit Changes (Optional)

```bash
cd ratpack
git add .
git commit -m "Add err0 error codes"
cd ..
```

---

## Advanced Configuration

### Per-Project Token Overrides

Override token files for specific projects:

```bash
# In .env file
ERR0_TOKEN_DJANGO=./tokens/err0-django-staging.json
ERR0_TOKEN_KUBERNETES=./tokens/err0-kubernetes-prod.json

# Or via environment variable
ERR0_TOKEN_DJANGO=./tokens/test.json ./dev-insert.sh
```

### Using Multiple err0 Servers

Test against different environments:

```bash
# Production environment
echo "ERR0_HOST=prod.err0.io:8443" > .env.prod

# Staging environment
echo "ERR0_HOST=staging.err0.io:8443" > .env.staging

# Load specific environment
set -a; source .env.prod; set +a
./dev-insert.sh
```

### Custom Docker Images

Use your own Docker builds:

```bash
# Build local Docker image
cd /path/to/err0-agent
docker build -t err0_io:err0_agent .

# Configure to use local image
echo "ERR0_DOCKER_IMAGE_LOCALDEV=err0_io:err0_agent" >> .env

# Use local image
./err0agent-localdev-insert.sh tokens/err0-django-*.json django
```

### Parallel Execution

Run operations on multiple projects in parallel:

```bash
# Using GNU parallel (if installed)
ls tokens/*.json | parallel -j4 'PROJECT=$(basename {} | sed "s/err0-//;s/-[0-9].*//"); ./err0agent-dev-insert.sh {} $PROJECT'

# Or simple background jobs
./err0agent-dev-insert.sh tokens/err0-django-*.json django &
./err0agent-dev-insert.sh tokens/err0-rails-*.json rails &
./err0agent-dev-insert.sh tokens/err0-strapi-*.json strapi &
wait
```

---

## Platform-Specific Notes

### Linux

#### SELinux Issues
If you encounter permission errors on RHEL/Fedora:

```bash
# Temporarily disable SELinux
sudo setenforce 0

# Or add Docker to SELinux policy
sudo chcon -Rt svirt_sandbox_file_t /path/to/open-source-bundle

# Permanent solution: Configure SELinux for Docker
# See: https://docs.docker.com/storage/bind-mounts/#configure-the-selinux-label
```

#### Docker Socket Permissions
```bash
# If you get "permission denied" errors
sudo chmod 666 /var/run/docker.sock

# Better: Add user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

### macOS

#### Homebrew Path Issues
```bash
# Add Homebrew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
```

#### Docker Desktop Memory
```bash
# Allocate more memory to Docker Desktop
# Docker Desktop → Settings → Resources → Memory
# Recommended: 4-8 GB
```

#### Case-Sensitive Filesystem
```bash
# Some projects require case-sensitive filesystem
# Check current filesystem
diskutil info / | grep "File System"

# If needed, create case-sensitive volume
# Disk Utility → File → New Image → Blank Image
# Format: APFS (Case-sensitive)
```

### Windows (WSL2)

#### Configure WSL2
```bash
# Set default WSL version to 2
wsl --set-default-version 2

# Check WSL version
wsl -l -v

# Update WSL
wsl --update
```

#### Line Ending Issues
```bash
# Configure Git to handle line endings
git config --global core.autocrlf input
git config --global core.eol lf

# Re-checkout repository if needed
git checkout --force HEAD
```

#### Docker Desktop Integration
```bash
# Enable WSL2 integration in Docker Desktop
# Docker Desktop → Settings → Resources → WSL Integration
# Enable for your distribution (Ubuntu, Debian, etc.)
```

---

## Next Steps

After completing setup:

1. **Test Multiple Projects**
   ```bash
   # Initialize more submodules
   git submodule update --init django kubernetes rails

   # Run bulk operations
   ./dev-insert.sh
   ```

2. **Run Integration Tests**
   ```bash
   # Run soak test (4-6 hours)
   ./soak-test.pl
   ```

3. **Explore Documentation**
   - [README.md](README.md) - Full feature reference
   - [tokens/README.md](tokens/README.md) - Token management
   - [CONTRIBUTING.md](CONTRIBUTING.md) - Contribute to project
   - [SECURITY.md](SECURITY.md) - Security best practices

4. **Join the Community**
   - Report issues on GitHub
   - Share your experience
   - Contribute improvements

---

## Getting Help

### Common Issues

See the [Troubleshooting](README.md#troubleshooting) section in README.md.

### Support Channels

- **Documentation**: https://docs.err0.io
- **GitHub Issues**: https://github.com/err0io/open-source-bundle/issues
- **Email Support**: support@err0.io
- **Community Forum**: https://community.err0.io

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
# Enable debug output
export ERR0_VERBOSE=true

# Run operation
./err0agent-dev-insert.sh tokens/err0-django-*.json django

# Check script execution
bash -x ./err0agent-dev-insert.sh tokens/err0-django-*.json django
```

---

**Setup Complete!** 🎉

You now have a fully configured err0.io test environment. Start testing error code insertion across major open-source projects!
