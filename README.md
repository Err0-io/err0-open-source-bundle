<div align="center">

# err0.io Open Source Test Bundle

<img src="https://err0.io/img/logo3.png" alt="err0.io logo" width="200"/>

### Testing Infrastructure for 31 Major Open-Source Projects

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Projects](https://img.shields.io/badge/Projects-31-green.svg)](#repository-contents)
[![Docker](https://img.shields.io/badge/Docker-Required-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![err0.io](https://img.shields.io/badge/Powered%20by-err0.io-orange)](https://err0.io)

[**Quick Start**](#quick-start) • [**Documentation**](#documentation) • [**Contributing**](CONTRIBUTING.md) • [**Support**](#support)

---

</div>

## 🎯 What is This?

A comprehensive test suite containing **31 major open-source projects** as git submodules for testing the [err0.io](https://err0.io) error code management agent across diverse programming languages and frameworks.

### What is err0.io?

**err0.io** is an error code management system that automatically inserts unique error codes into your source code's logging statements, making it easier to trace and debug issues in production. This repository provides a large-scale test environment to validate the err0 agent's capabilities.

## ✨ Features

- 🔧 **31 Production Projects** - Test across real-world codebases
- 🐳 **Docker-Based** - Consistent execution environment
- 🤖 **Automated Testing** - Comprehensive soak tests and validation
- 🔒 **Secure** - Token-based authentication with gitignored credentials
- 📚 **Multi-Language** - Java, Python, Ruby, Rust, Kotlin, Swift, C#, JavaScript, and more
- ⚡ **Flexible** - Production, development, and local testing modes

## 📦 Repository Contents

This repository contains **31 open-source projects** organized by category:

<details>
<summary><b>🤖 Android/Mobile (5 projects)</b></summary>

- **Signal-Android** - Private messaging for Android
- **Signal-iOS** - Private messaging for iOS
- **Telegram** - Messaging app for Android
- **Telegram-iOS** - Messaging app for iOS
- **UTM** - Virtual machines for iOS and macOS

</details>

<details>
<summary><b>☕ Backend Frameworks - JVM (4 projects)</b></summary>

- **spring-framework** - Application framework for Java
- **ktor** - Asynchronous framework for Kotlin
- **ratpack** - Web framework for Java
- **tomcat** - Java servlet container

</details>

<details>
<summary><b>🌐 Backend Frameworks - Other (4 projects)</b></summary>

- **django** - Web framework for Python
- **rails** - Web framework for Ruby
- **vapor** - Web framework for Swift
- **strapi** - Headless CMS for Node.js

</details>

<details>
<summary><b>₿ Blockchain/Cryptocurrency (1 project)</b></summary>

- **bitcoin** - Bitcoin Core implementation

</details>

<details>
<summary><b>📝 CMS/E-commerce (4 projects)</b></summary>

- **WordPress** - Content management system (PHP)
- **drupal** - Content management framework (PHP)
- **magento2** - E-commerce platform (PHP)
- **moodle** - Learning management system (PHP)

</details>

<details>
<summary><b>🚀 DevOps/IoT (4 projects)</b></summary>

- **kubernetes** - Container orchestration system
- **mender** - OTA software updater
- **SmartThingsEdgeDrivers** - Samsung SmartThings drivers
- **cerbos** - Access control and authorization

</details>

<details>
<summary><b>💎 .NET (2 projects)</b></summary>

- **Umbraco-CMS** - Content management system (C#)
- **roslyn** - C# and Visual Basic compiler

</details>

<details>
<summary><b>💬 Forums/Community (1 project)</b></summary>

- **NodeBB** - Forum software (Node.js)

</details>

<details>
<summary><b>📧 Infrastructure (1 project)</b></summary>

- **postfix** - Mail transfer agent

</details>

<details>
<summary><b>🎨 Kotlin Libraries (1 project)</b></summary>

- **kotlinx.html** - HTML DSL for Kotlin

</details>

<details>
<summary><b>🧠 Machine Learning (1 project)</b></summary>

- **pytorch** - Machine learning framework

</details>

<details>
<summary><b>🦀 Rust/Systems Programming (2 projects)</b></summary>

- **servo** - Browser engine
- **leptos** - Web framework for Rust

</details>

<details>
<summary><b>🧪 Test/Example (1 project)</b></summary>

- **zf2-orders** - Internal test project

</details>

## 🚀 Quick Start

### Prerequisites

| Requirement | Version | Installation |
|------------|---------|--------------|
| 🐳 **Docker** | Latest | [Install Docker](https://docs.docker.com/get-docker/) |
| 📦 **Git** | 2.13+ | Pre-installed on most systems |
| 🔧 **Perl** | Any | Pre-installed on Linux/macOS |

**Disk Space Requirements:**
- Initial clone: ~500 MB
- All submodules: ~50 GB
- Individual submodules: 10 MB - 5 GB each

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Err0-io/err0-open-source-bundle.git
cd err0-open-source-bundle

# 2. Initialize submodules (choose one)
# Option A: Initialize specific projects only (recommended)
git submodule update --init --depth 1 django rails kubernetes

# Option B: Initialize all projects (downloads ~50 GB)
git submodule update --init --depth 1

# Option C: Full history with err0/initial branches
./freshen-submodules.sh

# 3. Configure environment
cp .env.template .env
nano .env  # Edit with your err0 server details

# 4. Set up authentication tokens
# See tokens/README.md for instructions
```

### First Test Run

```bash
# Test a single project
./err0agent-dev-insert.sh tokens/err0-django-*.json django

# Test all configured projects
./dev-insert.sh
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [**SETUP.md**](SETUP.md) | 📚 Detailed setup and configuration guide |
| [**TESTING.md**](TESTING.md) | 🧪 Testing workflows and soak tests |
| [**SECURITY.md**](SECURITY.md) | 🔒 Security practices and token management |
| [**CONTRIBUTING.md**](CONTRIBUTING.md) | 🤝 Contribution guidelines |
| [**MIGRATION.md**](MIGRATION.md) | 🔄 Migration guide for existing users |
| [**tokens/README.md**](tokens/README.md) | 🎫 Token generation instructions |

## 🔧 Usage

### Script Overview

| Script | Purpose | Environment |
|--------|---------|-------------|
| `err0agent-insert.sh` | Insert error codes | Production (`latest`) |
| `err0agent-dev-insert.sh` | Insert error codes | Development (`develop`) |
| `err0agent-localdev-insert.sh` | Insert error codes | Local build |
| `err0agent-analyse.sh` | Analyze error codes | Production |
| `err0agent-dev-analyse.sh` | Analyze uncommitted changes | Development |
| `err0agent-dev-check.sh` | Check canonicalization | Development |
| `dev-insert.sh` | Bulk insert (all projects) | Development |
| `dev-analyse.sh` | Bulk analyze (all projects) | Development |

### Example Workflows

#### 🧪 Test a New Feature

```bash
# Initialize submodules
./freshen-submodules.sh

# Insert error codes into all projects
./dev-insert.sh

# Review changes
git submodule foreach git diff

# Commit changes
git submodule foreach git add .
git submodule foreach git commit -m "Add err0 codes"

# Verify canonicalization
./dev-analyse.sh
```

#### 🔬 Run Comprehensive Soak Test

```bash
# Full integration test (4-6 hours)
# - Creates test branches
# - Runs insert operations
# - Commits and tags changes
# - Verifies code canonicalization
# - Tests idempotency
./soak-test.pl
```

#### 🏠 Test Against Local Server

```bash
# Configure for localhost
echo "ERR0_HOST=localhost:8443" > .env

# Run operations
./dev-insert.sh
./dev-analyse.sh
```

## 🔐 Security

> ⚠️ **NEVER commit token files to version control!**

- Token files contain authentication credentials
- `.gitignore` prevents accidental commits
- Pre-commit hooks validate no secrets are committed
- Rotate tokens regularly (every 90 days recommended)
- See [SECURITY.md](SECURITY.md) for detailed practices

## 🤝 Contributing

We welcome contributions! Here's how you can help:

- 🐛 **Report Bugs** - [Open an issue](https://github.com/Err0-io/err0-open-source-bundle/issues)
- 💡 **Suggest Features** - [Start a discussion](https://github.com/Err0-io/err0-open-source-bundle/discussions)
- 📝 **Improve Docs** - Submit documentation improvements
- 🔧 **Add Projects** - Propose new open-source projects to test

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🛠️ Troubleshooting

<details>
<summary><b>🐳 Docker Issues</b></summary>

**Cannot connect to Docker daemon:**
```bash
# Start Docker service
sudo systemctl start docker  # Linux
# or start Docker Desktop     # macOS/Windows
```

**Permission denied:**
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

</details>

<details>
<summary><b>📦 Submodule Issues</b></summary>

**Submodule could not be updated:**
```bash
git submodule deinit -f <project>
git submodule update --init <project>
```

**No submodule mapping found:**
```bash
git submodule sync
git submodule update --init
```

</details>

<details>
<summary><b>🎫 Token Issues</b></summary>

**No token file found:**
```bash
# Check token file naming
ls tokens/err0-django-*.json

# Verify token directory
echo $ERR0_TOKEN_DIR

# Read setup guide
cat tokens/README.md
```

**Authentication failed:**
- Verify token is not expired
- Check `ERR0_HOST` matches token's `host` field
- Ensure network connectivity to err0 server

</details>

## 📊 Project Structure

```
err0-open-source-bundle/
├── 📄 README.md                  # This file
├── 📄 SETUP.md                   # Detailed setup guide
├── 📄 TESTING.md                 # Testing documentation
├── 📄 SECURITY.md                # Security practices
├── 📄 CONTRIBUTING.md            # Contribution guidelines
├── 📄 LICENSE                    # Apache 2.0 license
├── 📁 config/                    # Configuration files
│   ├── project-list.txt          # All 31 projects
│   └── submodule-mappings.txt    # GitHub URL mappings
├── 📁 scripts/                   # Helper scripts
│   ├── config-helper.sh          # Environment loader
│   ├── validate-setup.sh         # Setup validator
│   └── install-hooks.sh          # Git hooks installer
├── 📁 hooks/                     # Pre-commit hooks
│   └── pre-commit                # Token detection
├── 📁 tests/                     # Test suite
│   ├── security-test.sh          # Security validation
│   ├── unit-test.sh              # Unit tests
│   └── integration-test.sh       # Integration tests
├── 📁 tokens/                    # Token storage (gitignored)
│   ├── README.md                 # Token setup guide
│   └── *.json                    # Authentication tokens
├── 🔧 err0agent-*.sh             # Operation scripts (11 files)
├── 🔧 dev-*.sh                   # Bulk operation scripts
├── 🧪 soak-test*.pl              # Integration test scripts
├── 🔄 freshen-submodules.sh      # Submodule manager
└── 📁 [31 submodule directories] # Open-source projects
```

## 📜 License

This repository is licensed under the [Apache License 2.0](LICENSE).

**Note:** Each submodule project retains its own license (MIT, Apache 2.0, GPL, etc.). Please refer to individual project directories for their specific licensing terms.

## 🙏 Acknowledgments

This test bundle includes code from **31 major open-source projects**. We extend our gratitude to all contributors:

- 🐍 The Django Software Foundation
- ☸️ The Kubernetes Authors
- 💎 The Ruby on Rails team
- 🌸 The Spring Framework team
- ...and 27 other amazing projects!

See each project's directory for full contributor acknowledgments.

## 💬 Support

Need help? We've got you covered:

- 📚 **Documentation** - See [SETUP.md](SETUP.md) for detailed guides
- 🎫 **Token Help** - See [tokens/README.md](tokens/README.md)
- 🔄 **Migration** - See [MIGRATION.md](MIGRATION.md) for existing users
- 🌐 **err0.io Docs** - https://docs.err0.io
- 📧 **Support Email** - support@err0.io
- 💬 **GitHub Discussions** - [Ask questions](https://github.com/Err0-io/err0-open-source-bundle/discussions)

## 🔗 Related Projects

- [err0.io](https://err0.io) - Main error code management platform
- [err0 Agent](https://github.com/Err0-io/agent) - Error code insertion agent
- [err0 Documentation](https://docs.err0.io) - Comprehensive guides

---

<div align="center">

**Made with ❤️ by the err0.io team**

[![err0.io](https://img.shields.io/badge/Visit-err0.io-orange?style=for-the-badge)](https://err0.io)

</div>
