# err0.io Open Source Test Bundle

A comprehensive test suite containing 31 major open-source projects as git submodules for testing the [err0.io](https://err0.io) error code management agent.

## What is err0.io?

err0.io is an error code management system that automatically inserts unique error codes into your source code's logging statements, making it easier to trace and debug issues in production. This repository contains a large-scale test environment to validate the err0 agent across diverse programming languages and frameworks.

## Repository Contents

This repository contains 31 open-source projects organized by category:

### Android/Mobile (5 projects)
- **Signal-Android** - Private messaging for Android
- **Signal-iOS** - Private messaging for iOS
- **Telegram** - Messaging app for Android
- **Telegram-iOS** - Messaging app for iOS
- **UTM** - Virtual machines for iOS and macOS

### Backend Frameworks - JVM (4 projects)
- **spring-framework** - Application framework for Java
- **ktor** - Asynchronous framework for Kotlin
- **ratpack** - Web framework for Java
- **tomcat** - Java servlet container

### Backend Frameworks - Other (4 projects)
- **django** - Web framework for Python
- **rails** - Web framework for Ruby
- **vapor** - Web framework for Swift
- **strapi** - Headless CMS for Node.js

### Blockchain/Cryptocurrency (1 project)
- **bitcoin** - Bitcoin Core implementation

### CMS/E-commerce (4 projects)
- **WordPress** - Content management system (PHP)
- **drupal** - Content management framework (PHP)
- **magento2** - E-commerce platform (PHP)
- **moodle** - Learning management system (PHP)

### DevOps/IoT (4 projects)
- **kubernetes** - Container orchestration system
- **mender** - OTA software updater
- **SmartThingsEdgeDrivers** - Samsung SmartThings drivers
- **cerbos** - Access control and authorization

### .NET (2 projects)
- **Umbraco-CMS** - Content management system (C#)
- **roslyn** - C# and Visual Basic compiler

### Forums/Community (1 project)
- **NodeBB** - Forum software (Node.js)

### Infrastructure (1 project)
- **postfix** - Mail transfer agent

### Kotlin Libraries (1 project)
- **kotlinx.html** - HTML DSL for Kotlin

### Machine Learning (1 project)
- **pytorch** - Machine learning framework

### Rust/Systems Programming (2 projects)
- **servo** - Browser engine
- **leptos** - Web framework for Rust

### Test/Example (1 project)
- **zf2-orders** - Internal test project

## Prerequisites

### Required
- **Docker** - For running the err0 agent
  - Linux: [Install Docker Engine](https://docs.docker.com/engine/install/)
  - macOS: [Install Docker Desktop](https://docs.docker.com/desktop/install/mac-install/)
  - Windows: [Install Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)
- **Git** - Version 2.13 or later (for submodule management)
- **Perl** - For running test scripts (usually pre-installed on Linux/macOS)

### Optional
- **err0.io Account** - For generating authentication tokens
  - Sign up at your organization's err0 server
  - Or run a local err0 server (see below)

### Disk Space
- Initial clone: ~500 MB
- All submodules initialized: ~50 GB
- Individual submodules vary from 10 MB to 5 GB

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/err0io/open-source-bundle.git
cd open-source-bundle
```

### 2. Initialize Submodules

Initialize all submodules (downloads ~50 GB):

```bash
git submodule update --init --recursive
```

Or initialize specific projects only:

```bash
git submodule update --init django kubernetes rails
```

### 3. Configure Environment

Copy the environment template and edit with your values:

```bash
cp .env.template .env
nano .env  # or vim, code, etc.
```

Minimum required configuration:

```bash
ERR0_HOST=your-server.err0.io:8443
ERR0_REALM_UUID=your-realm-uuid
```

### 4. Generate Tokens

Generate authentication tokens from your err0 server for each project you want to test. Place token files in the `tokens/` directory with the naming convention:

```
tokens/err0-<project>-<date>-<uuid>.json
```

See [`tokens/README.md`](tokens/README.md) for detailed token setup instructions.

### 5. Run Tests

Test a single project:

```bash
./err0agent-dev-insert.sh tokens/err0-django-*.json django
```

Test all configured projects:

```bash
./dev-insert.sh
```

## Configuration

### Environment Variables

All scripts support configuration via environment variables. See [`.env.template`](.env.template) for all available options.

| Variable | Description | Default |
|----------|-------------|---------|
| `ERR0_HOST` | err0.io server hostname and port | `localhost:8443` |
| `ERR0_REALM_UUID` | Realm identifier | _(none)_ |
| `ERR0_DOCKER_IMAGE_LATEST` | Production Docker image | `err0io/agent:latest` |
| `ERR0_DOCKER_IMAGE_DEVELOP` | Development Docker image | `err0io/agent:develop` |
| `ERR0_DOCKER_IMAGE_LOCALDEV` | Local Docker image | `err0_io:err0_agent` |
| `ERR0_TOKEN_DIR` | Token file directory | `./tokens` |
| `ERR0_VERBOSE` | Enable verbose logging | `false` |

### Per-Project Token Overrides

Override token files for specific projects:

```bash
# In .env or on command line
export ERR0_TOKEN_DJANGO=./tokens/err0-django-staging.json
export ERR0_TOKEN_KUBERNETES=./tokens/err0-kubernetes-prod.json
```

## Scripts Reference

### Single Project Operations

#### Production Environment
```bash
# Insert error codes
./err0agent-insert.sh <token-file> <project-directory>

# Analyze error codes
./err0agent-analyse.sh <token-file> <project-directory> [--check|--dirty]
```

#### Development Environment
```bash
# Insert error codes (develop image)
./err0agent-dev-insert.sh <token-file> <project-directory>

# Analyze uncommitted changes
./err0agent-dev-analyse.sh <token-file> <project-directory>

# Check code canonicalization
./err0agent-dev-check.sh <token-file> <project-directory>
```

#### Local Development Environment
```bash
# Insert error codes (local build)
./err0agent-localdev-insert.sh <token-file> <project-directory>

# Analyze uncommitted changes (local build)
./err0agent-localdev-analyse.sh <token-file> <project-directory>

# Check code canonicalization (local build)
./err0agent-localdev-check.sh <token-file> <project-directory>
```

### Bulk Operations

```bash
# Insert error codes in all configured projects
./dev-insert.sh

# Analyze all configured projects
./dev-analyse.sh
```

### Testing

```bash
# Comprehensive integration test (4-6 hours)
./soak-test.pl

# Local development integration test
./soak-test-localdev.pl

# Code versioning behavior test
./versioning-test.pl
```

### Submodule Management

```bash
# Initialize and update all submodules to err0/initial branch
./freshen-submodules.sh

# Migrate submodules to public URLs (already done)
./scripts/migrate-submodules.sh
```

### Setup Validation

```bash
# Validate your configuration
./scripts/validate-setup.sh
```

## Workflow Examples

### Test a New Feature

```bash
# 1. Checkout initial branches
./freshen-submodules.sh

# 2. Insert error codes
./dev-insert.sh

# 3. Review changes
git submodule foreach git diff

# 4. Commit changes
git submodule foreach git add .
git submodule foreach git commit -m "Add err0 codes"

# 5. Verify canonicalization
./dev-analyse.sh
```

### Run Full Integration Test

```bash
# Run comprehensive soak test
# - Creates test branches in all submodules
# - Runs insert operations
# - Commits and tags changes
# - Verifies code canonicalization
# - Runs second insert pass to verify idempotency
./soak-test.pl
```

### Test Against Local Server

```bash
# 1. Configure for localhost
echo "ERR0_HOST=localhost:8443" > .env

# 2. Start local err0 server (separate terminal)
# (Instructions depend on your err0 server setup)

# 3. Run operations
./dev-insert.sh
./dev-analyse.sh
```

## Troubleshooting

### Docker Issues

**Problem:** `Cannot connect to the Docker daemon`
```bash
# Start Docker service
sudo systemctl start docker  # Linux
# or start Docker Desktop    # macOS/Windows
```

**Problem:** `docker: permission denied`
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

### Submodule Issues

**Problem:** `Submodule 'xxx' could not be updated`
```bash
# Re-initialize specific submodule
git submodule deinit -f xxx
git submodule update --init xxx
```

**Problem:** `No submodule mapping found in .gitmodules`
```bash
# Sync submodule URLs
git submodule sync
git submodule update --init --recursive
```

### Token Issues

**Problem:** `No token file found for project`
```bash
# Verify token file naming
ls tokens/err0-django-*.json

# Check token directory configuration
echo $ERR0_TOKEN_DIR

# See detailed token setup instructions
cat tokens/README.md
```

**Problem:** `Authentication failed`
- Verify token is not expired
- Check `ERR0_HOST` matches the `host` in token file
- Ensure network connectivity to err0 server

### Script Issues

**Problem:** `config-helper.sh not found`
```bash
# Ensure you're in the repository root
cd /path/to/open-source-bundle

# Verify script exists
ls -la scripts/config-helper.sh
```

**Problem:** UUID generation fails on Linux
- Scripts now support cross-platform UUID generation
- Should work on Linux, macOS, and Windows (Git Bash)

## Project Structure

```
open-source-bundle/
├── .env.template              # Environment configuration template
├── .gitignore                 # Git ignore patterns (includes tokens!)
├── .gitmodules                # Submodule definitions
├── README.md                  # This file
├── CLAUDE.md                  # AI assistant instructions
├── config/
│   ├── project-list.txt       # List of all 31 projects
│   └── submodule-mappings.txt # Public GitHub URL mappings
├── scripts/
│   ├── config-helper.sh       # Environment variable loader
│   ├── migrate-submodules.sh  # Submodule URL migration tool
│   └── validate-setup.sh      # Configuration validator (TBD)
├── tokens/
│   ├── .gitkeep              # Preserve empty directory
│   ├── README.md             # Token setup guide
│   └── *.json                # Authentication tokens (gitignored)
├── dev-localhost/
│   └── *.json                # Legacy token location (gitignored)
├── err0agent-*.sh            # Single-project operation scripts (8 files)
├── dev-*.sh                  # Bulk operation scripts (2 files)
├── *.pl                      # Perl test scripts (3 files)
├── freshen-submodules.sh     # Submodule initialization script
└── [31 submodule directories]
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Adding a New Project

1. Add project to `config/project-list.txt`
2. Add public URL to `config/submodule-mappings.txt`
3. Add as git submodule: `git submodule add <url> <name>`
4. Generate token for the project
5. Test: `./err0agent-dev-insert.sh tokens/err0-<name>-*.json <name>`
6. Update this README with project description

### Reporting Issues

- Bug reports: [GitHub Issues](https://github.com/err0io/open-source-bundle/issues)
- Security issues: See [SECURITY.md](SECURITY.md)
- General questions: [Discussions](https://github.com/err0io/open-source-bundle/discussions)

## Security

⚠️ **NEVER commit token files to version control!**

- Token files contain authentication credentials
- The `.gitignore` file prevents this, but double-check before commits
- See [SECURITY.md](SECURITY.md) for detailed security practices
- Rotate tokens regularly (every 90 days recommended)

## License

This repository itself is MIT licensed. Each submodule project retains its own license:

- See individual project directories for license information
- Most projects are open source (MIT, Apache 2.0, GPL, etc.)
- Respect each project's licensing terms

## Support

- **Documentation**: See [`SETUP.md`](SETUP.md) for detailed setup guide
- **Token Help**: See [`tokens/README.md`](tokens/README.md)
- **Migration Guide**: See [`MIGRATION.md`](MIGRATION.md) for existing users
- **err0.io Documentation**: https://docs.err0.io
- **Support Email**: support@err0.io

## Acknowledgments

This test bundle includes code from 31 major open-source projects. We thank all contributors to these projects for their excellent work:

- The Django Software Foundation (django)
- The Kubernetes Authors (kubernetes)
- The Ruby on Rails team (rails)
- And 28 other amazing projects!

See each project's directory for full contributor acknowledgments.

---

**Generated with err0.io** - Making error codes manageable at scale.
