# Testing Guide

This document describes the testing strategy and available tests for the err0.io Open Source Test Bundle.

## Quick Start

```bash
# Validate your setup
./scripts/validate-setup.sh

# Run functionality tests
./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack

# Run comprehensive test suite (4-6 hours)
./soak-test.pl
```

## Test Levels

### 1. Setup Validation

Validates that your environment is properly configured.

**Script:** `./scripts/validate-setup.sh`

**Checks:**
- Prerequisites (Docker, Git, Perl)
- Repository structure
- Configuration files
- Authentication tokens
- Git submodules
- Docker images
- Security settings
- Basic functionality

**Usage:**
```bash
# Standard validation
./scripts/validate-setup.sh

# Verbose output
./scripts/validate-setup.sh --verbose
```

**Exit codes:**
- `0` - All checks passed (may have warnings)
- `1` - One or more checks failed

### 2. Unit Tests (Individual Scripts)

Test individual scripts in isolation.

**Examples:**

```bash
# Test insert script with invalid arguments
./err0agent-insert.sh
# Expected: Usage message, exit 1

# Test with valid arguments
./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack
# Expected: Successful execution

# Test analyse script
./err0agent-dev-analyse.sh tokens/err0-ratpack-*.json ratpack
# Expected: Analysis report
```

### 3. Integration Tests (Small Scale)

Test with a few small projects.

**Example workflow:**

```bash
# Initialize small projects
git submodule update --init ratpack strapi cerbos

# Run bulk insert
./dev-insert.sh

# Verify results
cd ratpack && git status && cd ..
cd strapi && git status && cd ..
cd cerbos && git status && cd ..

# Run analyse
./dev-analyse.sh
```

### 4. Soak Tests (Full Scale)

Comprehensive integration tests across all projects.

**Test: `soak-test.pl`**

Duration: 4-6 hours
Projects: All 31 projects

**What it does:**
1. Checks out `err0/initial` branches in all submodules
2. Creates timestamped test branches
3. Runs insert operations on all projects
4. Commits changes and creates tags
5. Runs check operations to verify canonicalization
6. Runs second insert pass
7. Verifies second pass produces no changes (idempotency)

**Usage:**
```bash
# Full soak test (production workflow)
./soak-test.pl

# Local development soak test
./soak-test-localdev.pl
```

**Success criteria:**
- All insert operations succeed
- All check operations pass (codes are canonical)
- Second insert pass produces zero changes

### 5. Versioning Tests

Tests code versioning behavior.

**Test: `versioning-test.pl`**

Duration: 10-15 minutes

**What it does:**
- Creates temporary test repository
- Tests error code insertion and versioning
- Verifies code stability across multiple passes

**Usage:**
```bash
./versioning-test.pl
```

## Platform Testing

### Linux (Ubuntu 22.04+)

```bash
# Install prerequisites
sudo apt-get update
sudo apt-get install -y docker.io git perl

# Clone and test
git clone https://github.com/err0io/open-source-bundle.git
cd open-source-bundle
./scripts/validate-setup.sh
```

### macOS (12+)

```bash
# Install prerequisites
brew install --cask docker
brew install git

# Clone and test
git clone https://github.com/err0io/open-source-bundle.git
cd open-source-bundle
./scripts/validate-setup.sh
```

### Windows (WSL2)

```bash
# In WSL2 Ubuntu
sudo apt-get update
sudo apt-get install -y docker.io git perl

# Clone and test
git clone https://github.com/err0io/open-source-bundle.git
cd open-source-bundle
./scripts/validate-setup.sh
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive

      - name: Run validation
        run: ./scripts/validate-setup.sh

      - name: Test with small project
        run: |
          git submodule update --init ratpack
          # Add token setup here
          ./err0agent-dev-insert.sh tokens/test.json ratpack
```

## Test Matrix

| Test | Duration | Projects | Purpose |
|------|----------|----------|---------|
| validate-setup.sh | 1 min | 0 | Environment validation |
| Single project | 2-5 min | 1 | Quick functionality check |
| Small scale | 10-20 min | 3-5 | Integration testing |
| versioning-test.pl | 10-15 min | 1 (temp) | Code versioning behavior |
| soak-test.pl | 4-6 hours | 31 | Full integration test |

## Security Testing

### Pre-Commit Checks

```bash
# Manual security check before commit
git diff --cached | grep -i "token_value\|password\|secret"

# Should return nothing
```

### Automated Pre-Commit Hook

See [SECURITY.md](SECURITY.md#pre-commit-security-checks) for pre-commit hook setup.

## Troubleshooting Tests

### Test Failures

**Problem: validate-setup.sh fails**
- Review failed checks
- See README.md troubleshooting section
- Verify prerequisites installed

**Problem: Perl tests fail with UUID error**
- Scripts now support cross-platform UUID generation
- Should work on Linux, macOS, Windows
- If issues persist, check `perl --version`

**Problem: Docker tests fail**
- Verify Docker is running: `docker ps`
- Check network connectivity
- Try manual pull: `docker pull err0io/agent:develop`

**Problem: Soak test fails mid-way**
- Check which project failed (error code [DEV-XXXX])
- Verify token is valid for that project
- Check submodule is properly initialized
- Run single project test to debug

### Test Environment

```bash
# Reset test environment
git submodule foreach git checkout err0/initial
git submodule foreach git clean -fd

# Or use the freshen script
./freshen-submodules.sh
```

## Performance Testing

### Measuring Execution Time

```bash
# Time single project
time ./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack

# Time bulk operation
time ./dev-insert.sh

# Profile soak test
time ./soak-test.pl
```

### Expected Performance

| Operation | Small Project | Medium Project | Large Project |
|-----------|--------------|----------------|---------------|
| Insert | 30-60s | 2-5 min | 10-30 min |
| Analyse | 10-20s | 1-2 min | 5-10 min |
| Check | 10-20s | 1-2 min | 5-10 min |

Project sizes:
- Small: < 100 MB (ratpack, strapi, cerbos)
- Medium: 100-500 MB (django, rails, drupal)
- Large: > 500 MB (kubernetes, pytorch, spring-framework)

## Test Coverage

### Scripts Tested

- ✅ err0agent-insert.sh
- ✅ err0agent-analyse.sh
- ✅ err0agent-dev-insert.sh
- ✅ err0agent-dev-analyse.sh
- ✅ err0agent-dev-check.sh
- ✅ err0agent-localdev-insert.sh
- ✅ err0agent-localdev-analyse.sh
- ✅ err0agent-localdev-check.sh
- ✅ dev-insert.sh
- ✅ dev-analyse.sh
- ✅ scripts/config-helper.sh
- ✅ scripts/validate-setup.sh
- ✅ scripts/migrate-submodules.sh

### Test Scripts

- ✅ soak-test.pl
- ✅ soak-test-localdev.pl
- ✅ versioning-test.pl

### Platforms Tested

- ✅ Linux (Ubuntu 22.04, Debian 11)
- ✅ macOS (12+)
- ✅ Windows WSL2 (Ubuntu)

## Regression Testing

After making changes, run this checklist:

```bash
# 1. Validate setup
./scripts/validate-setup.sh

# 2. Test script help messages
./err0agent-insert.sh
./err0agent-analyse.sh

# 3. Test single project
git submodule update --init ratpack
./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack

# 4. Test bulk operations (if tokens available)
./dev-insert.sh

# 5. Run versioning test
./versioning-test.pl

# 6. (Optional) Run full soak test
./soak-test.pl
```

## Test Data

### Sample Token File

For testing, use a token with minimal permissions:

```json
{
  "host": "test-server.err0.io:8443",
  "realm_uuid": "00000000-0000-0000-0000-000000000000",
  "prj_uuid": "11111111-1111-1111-1111-111111111111",
  "token_uuid": "22222222-2222-2222-2222-222222222222",
  "token_value": "test.token.value..."
}
```

### Test Projects

Recommended projects for testing (ordered by size):

1. **ratpack** (smallest) - Quick tests
2. **strapi** (small) - Node.js testing
3. **cerbos** (small) - Go testing
4. **django** (medium) - Python testing
5. **rails** (medium) - Ruby testing

## Contributing Tests

When adding new features:

1. Add tests to `scripts/validate-setup.sh`
2. Test on multiple platforms
3. Update this document
4. Add to CI pipeline (if applicable)

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

**Questions?** See [README.md](README.md) for troubleshooting or open an issue.
