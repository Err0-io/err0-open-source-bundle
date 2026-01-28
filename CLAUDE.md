# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a test bundle for err0.io consisting of 31+ open source projects as git submodules. The repository is used to test the err0 agent, which inserts and analyzes error codes in codebases.

## Repository Structure

The repository contains:
- Multiple open source projects as git submodules (django, kubernetes, spring-framework, rails, pytorch, bitcoin, etc.)
- Docker-based err0 agent wrapper scripts for running tests
- Perl-based soak testing scripts for comprehensive integration testing
- JSON configuration files in `dev-localhost/` directory mapping each project to its err0 configuration

## Key Concepts

### err0 Agent Operations

The err0 agent performs two main operations:
- **Insert**: Adds error codes to source files in a project
- **Analyse**: Reports on error codes in a project, with two modes:
  - `--dirty`: Analyzes uncommitted changes
  - `--check`: Validates that all codes are canonical

### Script Variants

Three deployment environments are supported:
1. **Production** (`err0agent-*.sh`): Uses `err0io/agent:latest` from Docker Hub
2. **Development** (`err0agent-dev-*.sh`): Uses `err0io/agent:develop` from Docker Hub
3. **Local Development** (`err0agent-localdev-*.sh`): Uses locally built `err0_io:err0_agent` image

## Common Commands

### Basic Operations

Insert error codes into a project (production):
```bash
./err0agent-insert.sh <token-file> <project-directory>
```

Analyze error codes in a project (production):
```bash
./err0agent-analyse.sh <token-file> <project-directory>
```

### Development Operations

Run against a localhost server for all configured projects:
```bash
./dev-insert.sh    # Insert codes into all projects
./dev-analyse.sh   # Analyze codes in all projects
```

### Submodule Management

Initialize and update all submodules to `err0/initial` branch:
```bash
./freshen-submodules.sh
```

This script:
- Initializes and updates all submodules
- Fetches all tags and branches
- Checks out the `err0/initial` branch in each submodule
- Pulls latest changes

### Testing

Run comprehensive soak test (development environment):
```bash
./soak-test.pl
```

Run soak test against local development server:
```bash
./soak-test-localdev.pl
```

The soak test:
1. Creates a timestamped branch in all submodules
2. Runs insert operations on all projects
3. Commits changes and creates tags
4. Runs check operations to verify code canonicalization
5. Runs a second insert pass to verify idempotency
6. Fails if the second insert produces any changes

Run versioning test (tests code versioning behavior):
```bash
./versioning-test.pl
```

## Docker Integration

All err0 agent operations run via Docker with:
- Network mode: `host` (to access localhost servers)
- Volume mount: Current directory mounted at `/mnt` in container
- Token files and project directories are accessed via `/mnt/` prefix inside container

## Working with Submodules

Each submodule:
- Tracks an `err0/initial` branch as the baseline for testing
- Has a corresponding configuration JSON file in `dev-localhost/`
- Is tested independently by the err0 agent

To work on a specific project:
```bash
cd <project-directory>
git checkout err0/initial
```

## Token Files

Token files in `dev-localhost/` contain:
- `host`: The err0 server hostname and port
- `realm_uuid`: Realm identifier
- `prj_uuid`: Project identifier
- `token_uuid` and `token_value`: Authentication credentials

## Test Workflow

The typical test workflow is:
1. Checkout `err0/initial` branches in all submodules
2. Run insert operations (adds error codes)
3. Commit changes
4. Run check operations (validates codes are canonical)
5. Run second insert pass (should produce no changes, verifying idempotency)
