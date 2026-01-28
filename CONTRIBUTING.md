# Contributing to err0.io Open Source Test Bundle

Thank you for your interest in contributing! This guide will help you make meaningful contributions to the err0.io test bundle.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
3. [Getting Started](#getting-started)
4. [Development Workflow](#development-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing Requirements](#testing-requirements)
7. [Submitting Changes](#submitting-changes)
8. [Adding New Projects](#adding-new-projects)
9. [Recognition](#recognition)

---

## Code of Conduct

This project follows a Code of Conduct to ensure a welcoming environment for all contributors.

### Our Standards

- **Be respectful** - Treat all contributors with respect and professionalism
- **Be constructive** - Provide helpful, actionable feedback
- **Be inclusive** - Welcome contributors of all backgrounds and experience levels
- **Be collaborative** - Work together towards common goals

### Unacceptable Behavior

- Harassment, discrimination, or hostile comments
- Personal attacks or ad hominem arguments
- Trolling or inflammatory remarks
- Publishing others' private information

### Reporting

Report violations to: conduct@err0.io

---

## How Can I Contribute?

### Reporting Bugs

Found a bug? Help us fix it!

**Before submitting:**
- Check [existing issues](https://github.com/err0io/open-source-bundle/issues)
- Test with the latest version
- Gather relevant information (OS, Docker version, error messages)

**Bug Report Template:**
```markdown
**Description**
Clear description of the bug

**Steps to Reproduce**
1. Run command: `./err0agent-insert.sh ...`
2. Observe error: ...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happened

**Environment**
- OS: Ubuntu 22.04
- Docker: 24.0.5
- Git: 2.40.1
- Submodules initialized: django, kubernetes

**Logs/Output**
```
paste relevant logs here
```
```

### Suggesting Enhancements

Have an idea for improvement?

**Enhancement Request Template:**
```markdown
**Feature Description**
Clear description of the proposed feature

**Use Case**
Why is this feature needed? What problem does it solve?

**Proposed Implementation**
How might this be implemented?

**Alternatives Considered**
What alternatives have you considered?

**Additional Context**
Screenshots, examples, or related issues
```

### Improving Documentation

Documentation improvements are always welcome!

**Areas to improve:**
- Clarify confusing sections
- Fix typos and grammar
- Add examples and use cases
- Improve troubleshooting guides
- Translate to other languages

### Contributing Code

See [Development Workflow](#development-workflow) below.

---

## Getting Started

### 1. Fork the Repository

```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/open-source-bundle.git
cd open-source-bundle

# Add upstream remote
git remote add upstream https://github.com/err0io/open-source-bundle.git
```

### 2. Set Up Development Environment

```bash
# Copy environment template
cp .env.template .env

# Edit with your test server details
nano .env

# Initialize submodules (optional, only if needed for your changes)
git submodule update --init ratpack django
```

### 3. Create a Branch

```bash
# Update your fork
git fetch upstream
git checkout master
git merge upstream/master

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

**Branch naming conventions:**
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or fixes

---

## Development Workflow

### Making Changes

1. **Make your changes**
   ```bash
   # Edit files
   nano scripts/config-helper.sh

   # Test your changes
   ./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack
   ```

2. **Follow coding standards** (see below)

3. **Write/update tests**
   ```bash
   # Add test cases if applicable
   # Update existing tests if behavior changed
   ```

4. **Update documentation**
   ```bash
   # Update README.md if user-facing changes
   # Update SETUP.md if setup process changed
   # Add/update code comments
   ```

### Testing Your Changes

#### Shell Scripts

```bash
# Syntax check
bash -n your-script.sh

# Linting (if shellcheck installed)
shellcheck your-script.sh

# Manual testing
./your-script.sh --help
./your-script.sh tokens/test.json test-project
```

#### Perl Scripts

```bash
# Syntax check
perl -c your-script.pl

# Linting (if perlcritic installed)
perlcritic your-script.pl

# Manual testing
./your-script.pl
```

#### Configuration Files

```bash
# Validate JSON
jq empty < config/file.json

# Validate YAML (if applicable)
yamllint config/file.yaml
```

### Commit Messages

Write clear, descriptive commit messages:

**Format:**
```
Short summary (50 chars or less)

Detailed explanation if needed (wrap at 72 chars):
- What changed
- Why the change was made
- Any breaking changes or migration notes

Closes #123
```

**Examples:**

Good:
```
Add validation to config-helper.sh

- Check that .env file exists before sourcing
- Validate ERR0_HOST format
- Print helpful error messages for missing config

This prevents confusing errors when configuration is incomplete.
```

Bad:
```
fixed stuff
```

```
made some changes to scripts
```

### Keeping Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Merge into your branch
git checkout master
git merge upstream/master

# Rebase your feature branch
git checkout feature/your-feature
git rebase master
```

---

## Coding Standards

### Shell Scripts (Bash)

**Style:**
- Use `#!/bin/bash` (not `#!/bin/sh`)
- Indent with 4 spaces
- Use double quotes for variables: `"$VAR"`
- Check exit codes: `|| die "error message"`
- Use meaningful variable names: `token_file` not `tf`

**Example:**
```bash
#!/bin/bash

# Function documentation
#
# Args:
#   $1 - Token file path
#   $2 - Project directory
function process_project() {
    local token_file="$1"
    local project_dir="$2"

    if [ ! -f "$token_file" ]; then
        echo "ERROR: Token file not found: $token_file" >&2
        return 1
    fi

    echo "Processing: $project_dir"
    # Implementation
}
```

**Error handling:**
```bash
# Check prerequisites
command -v docker >/dev/null 2>&1 || {
    echo "ERROR: docker is required but not installed" >&2
    exit 1
}

# Validate arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <token-file> <project-dir>" >&2
    exit 1
fi
```

### Perl Scripts

**Style:**
- Use `#!/usr/bin/perl -w`
- Enable strict: `use strict;`
- Enable warnings: `use warnings;`
- Indent with 4 spaces
- Use meaningful variable names

**Example:**
```perl
#!/usr/bin/perl -w

use strict;
use warnings;
use POSIX qw(strftime);

# Process each submodule
my @projects = qw(django kubernetes rails);

foreach my $project (@projects) {
    print "Processing: $project\n";

    my $exit_code = system("./err0agent-dev-insert.sh tokens/err0-$project-*.json $project");

    if ($exit_code != 0) {
        die "[ERROR] Failed to process $project\n";
    }
}
```

### Documentation (Markdown)

**Style:**
- Use ATX-style headers: `# Header`
- Wrap lines at 80 characters (exception: code blocks, links)
- Use fenced code blocks with language hints
- Use lists for multiple items
- Use tables for structured data

**Example:**
```markdown
## Section Title

Brief introduction to the section.

### Subsection

Instructions or explanation here.

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |

**Example usage:**

```bash
command --option value
```
```

### Configuration Files

**JSON:**
```json
{
  "key": "value",
  "nested": {
    "inner_key": "inner_value"
  },
  "array": [
    "item1",
    "item2"
  ]
}
```

**Shell environment:**
```bash
# Comments explain why
VARIABLE_NAME=value

# Group related variables
# Server configuration
ERR0_HOST=localhost:8443
ERR0_REALM_UUID=ea3cd958-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

---

## Testing Requirements

### Pre-Commit Checklist

Before committing, verify:

- [ ] Code follows style guidelines
- [ ] Scripts are executable: `chmod +x *.sh`
- [ ] No syntax errors: `bash -n script.sh`
- [ ] No secrets committed: `git diff --cached | grep -i "token_value"`
- [ ] Documentation updated if needed
- [ ] Tested on your system
- [ ] Commit message is clear and descriptive

### Test Levels

#### 1. Unit Testing (Scripts)

Test individual scripts work correctly:

```bash
# Test with invalid arguments
./script.sh
# Expected: Usage message and exit 1

# Test with valid arguments
./script.sh tokens/test.json project
# Expected: Successful execution
```

#### 2. Integration Testing (Small Scale)

Test with a small project:

```bash
# Initialize small project
git submodule update --init ratpack

# Run full workflow
./freshen-submodules.sh
./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack
./err0agent-dev-check.sh tokens/err0-ratpack-*.json ratpack

# Verify no unexpected changes
cd ratpack && git status
```

#### 3. Soak Testing (Full Scale)

Run comprehensive test suite:

```bash
# This takes 4-6 hours
./soak-test.pl
```

### Platform Testing

Test on multiple platforms if possible:

- **Linux**: Ubuntu 22.04 or later
- **macOS**: macOS 12 or later
- **Windows**: WSL2 with Ubuntu

---

## Submitting Changes

### 1. Prepare Your Changes

```bash
# Make sure you're on your feature branch
git status

# Review your changes
git diff master

# Stage changes
git add file1.sh file2.pl docs/README.md

# Commit with descriptive message
git commit -m "Add feature XYZ

- Detailed explanation
- List of changes
- Breaking changes (if any)
"
```

### 2. Push to Your Fork

```bash
# Push feature branch to your fork
git push origin feature/your-feature-name
```

### 3. Create Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select base: `err0io/open-source-bundle:master`
4. Select compare: `your-fork:feature/your-feature-name`
5. Fill out PR template (see below)
6. Click "Create Pull Request"

### Pull Request Template

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)

## Testing

Describe testing performed:

- [ ] Tested on Linux
- [ ] Tested on macOS
- [ ] Tested on Windows/WSL2
- [ ] Ran soak-test.pl successfully
- [ ] Tested with multiple projects
- [ ] Updated tests pass

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex sections
- [ ] Updated documentation
- [ ] No new warnings
- [ ] Added tests (if applicable)
- [ ] All tests pass
- [ ] No secrets committed

## Related Issues

Closes #123
Related to #456
```

### 4. Code Review Process

**What to expect:**

1. **Automated checks** run (if configured)
2. **Maintainer review** within 1-7 days
3. **Feedback** provided as review comments
4. **Updates** requested if needed
5. **Approval** and merge when ready

**Responding to feedback:**

```bash
# Make requested changes
nano script.sh

# Commit changes
git add script.sh
git commit -m "Address review feedback

- Fix error handling
- Add input validation
- Update documentation
"

# Push updates
git push origin feature/your-feature-name
```

---

## Adding New Projects

To add a new project to the test bundle:

### 1. Research the Project

- **Name**: Official project name
- **URL**: Public GitHub URL
- **Category**: Mobile, Backend, CMS, etc.
- **Language**: Primary programming language
- **Size**: Repository size
- **License**: Project license

### 2. Add to Configuration

```bash
# Add to project list
echo "new-project" >> config/project-list.txt

# Add to submodule mappings
echo "new-project https://github.com/org/project.git" >> config/submodule-mappings.txt
```

### 3. Add Submodule

```bash
# Add as git submodule
git submodule add https://github.com/org/project.git new-project

# Initialize to err0/initial branch
cd new-project
git checkout -b err0/initial
git push origin err0/initial
cd ..

# Commit submodule addition
git add .gitmodules new-project config/
git commit -m "Add new-project to test bundle"
```

### 4. Generate Token

1. Create project in err0 server
2. Generate authentication token
3. Save to `tokens/err0-new-project-*.json`

### 5. Test Integration

```bash
# Test insert operation
./err0agent-dev-insert.sh tokens/err0-new-project-*.json new-project

# Test analyse operation
./err0agent-dev-analyse.sh tokens/err0-new-project-*.json new-project

# Verify check operation
./err0agent-dev-check.sh tokens/err0-new-project-*.json new-project
```

### 6. Update Documentation

```bash
# Add to README.md under appropriate category
nano README.md

# Update SETUP.md with project details
nano SETUP.md
```

### 7. Submit Pull Request

Follow [Submitting Changes](#submitting-changes) process above.

---

## Recognition

### Contributors

All contributors are recognized in:

- **GitHub Contributors page**
- **Release notes** for significant contributions
- **CONTRIBUTORS.md** file (if created)

### Maintainers

Active contributors may be invited to become maintainers with:

- Commit access
- Review responsibilities
- Decision-making participation

---

## Questions?

### Getting Help

- **Documentation**: [SETUP.md](SETUP.md), [README.md](README.md)
- **Discussions**: https://github.com/err0io/open-source-bundle/discussions
- **Email**: contribute@err0.io

### Quick Reference

```bash
# Setup
git clone https://github.com/YOUR_USERNAME/open-source-bundle.git
cd open-source-bundle
git remote add upstream https://github.com/err0io/open-source-bundle.git

# Development
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "Description"
git push origin feature/my-feature
# ... create PR on GitHub ...

# Stay updated
git fetch upstream
git rebase upstream/master
```

---

Thank you for contributing to err0.io! 🎉

Your contributions help make error code management better for everyone.
