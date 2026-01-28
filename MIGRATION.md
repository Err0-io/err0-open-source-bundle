# Migration Guide for Existing Users

This guide helps existing users migrate from the old configuration to the new secure, configurable system introduced in the recent updates.

## Table of Contents

1. [What Changed?](#what-changed)
2. [Do I Need to Migrate?](#do-i-need-to-migrate)
3. [Migration Overview](#migration-overview)
4. [Step-by-Step Migration](#step-by-step-migration)
5. [Backward Compatibility](#backward-compatibility)
6. [Breaking Changes](#breaking-changes)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

---

## What Changed?

### Security Improvements

**Before (Insecure):**
- 32 token files committed to git with credentials
- Hardcoded server URLs in token files
- Minimal .gitignore (only `.idea/` and `/tmp`)

**After (Secure):**
- Token files removed from version control
- Comprehensive .gitignore prevents secret leaks
- Environment-based configuration via `.env` file
- Token files in `tokens/` directory (gitignored)

### Configuration Management

**Before (Hardcoded):**
- All scripts used hardcoded Docker images
- No centralized configuration
- Token paths hardcoded in bulk scripts

**After (Configurable):**
- Environment variables for all configuration
- `.env` file for easy customization
- `config-helper.sh` for centralized config loading
- `config/project-list.txt` for project management

### Submodule Accessibility

**Before (Private Only):**
- Relative submodule URLs (`../project.git`)
- External users couldn't clone repository

**After (Public):**
- Public GitHub URLs for 30/31 submodules
- External users can clone and contribute
- Migration script with rollback capability

### Script Improvements

**Before (Basic):**
- Simple scripts with minimal error handling
- No argument validation
- Linux-specific code (UUID generation)

**After (Robust):**
- Comprehensive error checking
- Helpful usage messages
- Cross-platform support (Linux, macOS, Windows)
- Better logging and debugging

---

## Do I Need to Migrate?

### You Should Migrate If:

✅ You use this repository regularly
✅ You want to use environment variables for configuration
✅ You want improved security (token files not in git)
✅ You want to contribute to the project
✅ You want cross-platform support

### You Can Wait If:

⏸️ You rarely use this repository
⏸️ Your current setup works and you don't need new features
⏸️ You're in the middle of critical testing

**Note:** The old system still works due to backward compatibility, but **migration is recommended** for security and future compatibility.

---

## Migration Overview

### What You'll Do

1. **Pull latest changes** from the repository
2. **Copy token files** to new location (optional but recommended)
3. **Create .env file** with your configuration
4. **Test** that scripts still work
5. **Commit** your changes (excluding tokens and .env)

### What Won't Break

✅ Existing token files in `dev-localhost/` still work
✅ All script command-line arguments unchanged
✅ Existing workflows continue to function
✅ Submodules don't need re-initialization

### Time Required

- **Quick migration:** 10-15 minutes
- **Full migration:** 30-45 minutes (including testing)

---

## Step-by-Step Migration

### Step 1: Backup Your Current Setup

```bash
# Navigate to repository
cd /path/to/open-source-bundle

# Create backup of current state
git branch backup-$(date +%Y%m%d)

# Backup token files (if any outside git)
mkdir -p ~/err0-backup
cp -r dev-localhost/*.json ~/err0-backup/ 2>/dev/null || true
```

### Step 2: Pull Latest Changes

```bash
# Fetch upstream changes
git fetch origin

# Check what changed
git log HEAD..origin/master --oneline

# Pull changes
git pull origin master

# If you have local commits, rebase them
git rebase origin/master
```

**Expected changes:**
- `.gitignore` updated with security patterns
- 32 token files removed from git
- New files: `.env.template`, `tokens/README.md`, `scripts/config-helper.sh`
- Updated: All shell scripts, 2 Perl scripts
- `.gitmodules` with public URLs

### Step 3: Verify Token Files Are Preserved

```bash
# Check that local token files still exist
ls -la dev-localhost/*.json

# Should show 32 files (or however many you had)
# If missing, restore from backup:
# cp ~/err0-backup/*.json dev-localhost/
```

**Why they still exist:**
- `git rm --cached` removed them from tracking, not from disk
- Files are now gitignored but still present locally

### Step 4: Create Environment Configuration

```bash
# Copy template
cp .env.template .env

# Edit with your values
nano .env  # or vim, code, etc.
```

**Minimum configuration:**

```bash
# Replace with your actual values
ERR0_HOST=your-server.err0.io:8443
ERR0_REALM_UUID=ea3cd958-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Optional but recommended:**

```bash
# If using develop image
ERR0_DOCKER_IMAGE_DEVELOP=err0io/agent:develop

# If using custom token directory
ERR0_TOKEN_DIR=./dev-localhost  # Use old location

# Or migrate tokens to new location
ERR0_TOKEN_DIR=./tokens  # Use new location
```

### Step 5: (Optional) Migrate Tokens to New Location

```bash
# Copy tokens to new location
mkdir -p tokens
cp dev-localhost/*.json tokens/

# Set permissions
chmod 700 tokens
chmod 600 tokens/*.json

# Update .env to use new location
echo "ERR0_TOKEN_DIR=./tokens" >> .env

# Keep old tokens as backup for now
```

### Step 6: Sync Submodule URLs

```bash
# Sync to new public URLs
git submodule sync

# Update submodule remote URLs
git submodule update --remote --merge
```

**What this does:**
- Updates `.git/config` with new URLs
- Doesn't re-download submodules
- Doesn't change working directory content

### Step 7: Test Your Setup

```bash
# Test single project (quick test)
./err0agent-dev-insert.sh dev-localhost/err0-ratpack-*.json ratpack

# If using new token location:
./err0agent-dev-insert.sh tokens/err0-ratpack-*.json ratpack

# Test bulk operation
./dev-insert.sh

# Should see:
# - Progress indicators
# - Success/skip/fail counts
# - Summary at end
```

### Step 8: Verify No Secrets in Git

```bash
# Check git status (should not show token files)
git status

# Verify tokens are ignored
git check-ignore dev-localhost/*.json
git check-ignore tokens/*.json

# Check that .env is ignored
git check-ignore .env

# All should output the file paths (meaning they're ignored)
```

### Step 9: Commit Your Changes

**What to commit:**

```bash
# Add your personal changes (if any)
git add .env.local  # If you created project-specific overrides

# DO NOT add:
# - .env (contains your config)
# - tokens/*.json (secrets)
# - dev-localhost/*.json (secrets)

# If you have no personal changes to commit, you're done!
```

### Step 10: Clean Up Old Backup (Optional)

```bash
# After verifying everything works (wait a few days)
git branch -d backup-$(date +%Y%m%d)
rm -rf ~/err0-backup
```

---

## Backward Compatibility

### What Still Works

#### 1. Token Files in Old Location

```bash
# Scripts check both locations
./err0agent-dev-insert.sh dev-localhost/err0-django-*.json django
# ✅ Still works
```

#### 2. Command-Line Arguments

```bash
# All arguments unchanged
./err0agent-insert.sh <token> <project>
./err0agent-analyse.sh <token> <project>
./dev-insert.sh
./dev-analyse.sh
# ✅ All still work as before
```

#### 3. Hardcoded Defaults

```bash
# If you don't create .env, scripts use defaults:
# - ERR0_HOST=localhost:8443
# - ERR0_DOCKER_IMAGE_LATEST=err0io/agent:latest
# - ERR0_TOKEN_DIR=./tokens (with fallback to dev-localhost)
# ✅ Works without configuration
```

#### 4. Existing Workflows

```bash
# Your existing scripts and workflows continue to work
./freshen-submodules.sh
./soak-test.pl
./versioning-test.pl
# ✅ No changes required
```

### Migration Path

You can migrate gradually:

**Phase 1: Use old setup**
- Keep tokens in `dev-localhost/`
- Don't create `.env`
- Scripts use backward compatibility

**Phase 2: Add configuration**
- Create `.env` with your settings
- Still use `dev-localhost/` tokens
- Scripts use your config

**Phase 3: Full migration**
- Move tokens to `tokens/`
- Update `.env` to point to `tokens/`
- Clean setup complete

---

## Breaking Changes

### None for Existing Users! 🎉

All breaking changes were avoided through backward compatibility:

- ✅ Token file locations: Both old and new work
- ✅ Script arguments: Unchanged
- ✅ Command names: Unchanged
- ✅ Docker images: Unchanged defaults
- ✅ Submodule content: Unchanged (only URLs)

### Future Breaking Changes

These **may** break in future versions:

⚠️ **Token files in git history**
- Git history still contains old token files
- Future: May require clean history for public release
- **Action:** Rotate tokens used in git history

⚠️ **Legacy `dev-localhost/` location**
- Currently supported via fallback
- Future: May be deprecated
- **Action:** Migrate to `tokens/` directory

⚠️ **Relative submodule URL for zf2-orders**
- Still uses relative URL (`../zf2-orders.git`)
- Future: May need public fork or removal
- **Action:** No action needed yet

---

## Troubleshooting

### Problem: "git pull" Shows Conflicts

```bash
# Stash your local changes
git stash

# Pull updates
git pull origin master

# Reapply your changes
git stash pop

# Resolve any conflicts manually
```

### Problem: Token Files Disappeared

```bash
# They should still be local, check:
ls -la dev-localhost/*.json

# If truly missing, restore from backup
cp ~/err0-backup/*.json dev-localhost/

# Or regenerate from err0 server
```

### Problem: Scripts Don't Find Tokens

```bash
# Check token file naming
ls tokens/err0-*-*.json

# Must match pattern: err0-<project>-<date>-<uuid>.json

# Check environment variable
echo $ERR0_TOKEN_DIR

# Try explicit path
./err0agent-dev-insert.sh dev-localhost/err0-django-*.json django
```

### Problem: "config-helper.sh not found"

```bash
# Ensure you're in repository root
cd /path/to/open-source-bundle
pwd

# Verify file exists
ls -la scripts/config-helper.sh

# If missing, pull again
git pull origin master
```

### Problem: Submodules Won't Update

```bash
# Force sync URLs
git submodule sync --recursive

# Reinitialize
git submodule update --init --recursive

# If still failing, check network access to GitHub
curl -I https://github.com
```

### Problem: Docker Permission Denied

```bash
# Ensure Docker is running
docker ps

# Check you're in docker group
groups | grep docker

# If not, add yourself (logout/login required)
sudo usermod -aG docker $USER
```

---

## FAQ

### Q: Do I need to re-clone the repository?

**A:** No. Just `git pull` to get the latest changes.

### Q: Will my current tests/workflows break?

**A:** No. Backward compatibility ensures everything continues to work.

### Q: Do I need to move my token files?

**A:** No, but it's recommended for better organization. The old location (`dev-localhost/`) still works.

### Q: What if I've made local modifications to scripts?

**A:** Stash your changes (`git stash`), pull updates, then reapply and merge (`git stash pop`).

### Q: Do I need to update my tokens?

**A:** Not immediately, but you should rotate tokens that were in git history. See [SECURITY.md](SECURITY.md) for token rotation process.

### Q: Can I still use the old Docker images?

**A:** Yes. Docker images haven't changed. Scripts use the same images by default.

### Q: What about the zf2-orders submodule?

**A:** It still uses a relative URL. This doesn't affect you unless you're cloning fresh. We'll address this in a future update.

### Q: How do I know if migration was successful?

**A:** Run these checks:

```bash
# 1. Scripts work
./err0agent-dev-insert.sh dev-localhost/err0-ratpack-*.json ratpack

# 2. Config file exists (optional)
test -f .env && echo "✓ Config exists"

# 3. No secrets in git
git status | grep -E '(\.json|\.env)' | grep -v template
# Should output nothing

# 4. Submodules synced
git submodule status | head -5
# Should show public GitHub URLs
```

### Q: Can I contribute now?

**A:** Yes! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. The repository is now set up for external contributions.

### Q: Where can I get help?

**A:**
- Documentation: [SETUP.md](SETUP.md), [README.md](README.md)
- Issues: https://github.com/err0io/open-source-bundle/issues
- Email: support@err0.io

---

## Summary

✅ **Pull latest changes:** `git pull origin master`
✅ **Create .env file:** `cp .env.template .env` and edit
✅ **Test:** `./err0agent-dev-insert.sh <token> <project>`
✅ **Verify:** `git status` shows no secrets

Your setup is now:
- ✅ More secure (no secrets in git)
- ✅ More flexible (environment-based config)
- ✅ More accessible (public submodule URLs)
- ✅ More reliable (cross-platform support)

Welcome to the new err0.io test bundle! 🚀

---

**Need Help?** Open an issue or contact support@err0.io
