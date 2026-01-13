# Sonda - Code Review & Best Practices Report

This document outlines all deviations from coding best practices, improvements needed, fixes required, and proper installation/uninstallation/update procedures.

---

## Table of Contents

1. [Critical Security Issues](#critical-security-issues)
2. [Error Handling Issues](#error-handling-issues)
3. [Code Quality Issues](#code-quality-issues)
4. [Architecture & Design Issues](#architecture--design-issues)
5. [Documentation Issues](#documentation-issues)
6. [Installation Instructions](#installation-instructions)
7. [Uninstallation Instructions](#uninstallation-instructions)
8. [Automatic Update from GitHub](#automatic-update-from-github)
9. [Recommended Improvements](#recommended-improvements)

---

## Critical Security Issues

### 1. **Unsafe Use of `eval`**
**Location:** `bin/init` (lines 49, 51, 60, 62)

**Issue:** The `pprint` and `LOGRUN` functions use `eval` to execute commands, which is a security risk if user input is not properly sanitized.

```bash
# Current (unsafe):
eval "$command"
eval "$function_name"
```

**Fix:** Use direct command execution or proper command arrays:
```bash
# Safer approach:
pprint() {
    local command="$1"
    if [[ -n "$PRETTYP" ]]; then
        echo -e "${DIM}${WHITE}$($command | sed 's/\x1b\[[0-9;]*m//g') ${RT}"
    else
        $command
    fi
}
```

### 2. **Sudoers Modification Without Validation**
**Location:** `SETUP.sh` (lines 157-172)

**Issue:** The script modifies `/etc/sudoers` without proper validation or backup. This could lock users out of their system if the entry is malformed.

**Fix:**
- Validate the sudoers entry format before adding
- Create a backup of `/etc/sudoers` before modification
- Use `visudo -c` to validate syntax
- Provide rollback mechanism

### 3. **Hardcoded Desktop Path**
**Location:** `bin/init` (line 27)

**Issue:** Log files are written to `$HOMEUSER/Desktop/` which may not exist on all systems (especially headless servers).

```bash
LOGFILE="$HOMEUSER/Desktop/system_$(date +%d%m%y).log"
```

**Fix:** Use `$HOME` or `$XDG_DATA_HOME` with fallback:
```bash
LOGFILE="${XDG_DATA_HOME:-$HOME/.local/share}/sonda/logs/system_$(date +%d%m%y).log"
mkdir -p "$(dirname "$LOGFILE")"
```

### 4. **Missing Input Validation**
**Location:** Multiple files

**Issue:** No validation of user input, file paths, or command-line arguments before use.

**Fix:** Add input validation for all user-provided data.

---

## Error Handling Issues

### 1. **Missing `set -euo pipefail`**
**Location:** All bash scripts

**Issue:** Scripts don't fail on errors, undefined variables, or pipe failures.

**Fix:** Add at the beginning of all bash scripts:
```bash
#!/bin/bash
set -euo pipefail
```

### 2. **No Error Checking for File Operations**
**Location:** `bin/init`, `modules/core/main`, `lib/includes/logic`

**Issue:** File reads (`cat`, `grep`) don't check if files exist or are readable.

**Example:**
```bash
hostname=$(cat /etc/hostname)  # Will fail if file doesn't exist
```

**Fix:**
```bash
if [[ -r /etc/hostname ]]; then
    hostname=$(cat /etc/hostname)
else
    hostname="Unknown"
fi
```

### 3. **Missing Error Handling in Python Script**
**Location:** `modules/core/netinfo` (lines 151-162)

**Issue:** Exception handling is present but could be more specific and informative.

**Fix:** Add more specific exception handling and logging.

### 4. **No Rollback on Installation Failure**
**Location:** `SETUP.sh`

**Issue:** If installation fails partway through, partial installation remains.

**Fix:** Implement transaction-like behavior with rollback capability.

### 5. **Missing Exit Codes**
**Location:** Multiple scripts

**Issue:** Scripts don't return proper exit codes, making it difficult to determine success/failure programmatically.

**Fix:** Ensure all scripts return appropriate exit codes (0 for success, non-zero for failure).

---

## Code Quality Issues

### 1. **Commented-Out Code**
**Location:** `bin/init` (lines 3-12, 118-124, 140-146, 272-275)

**Issue:** Large blocks of commented code should be removed or documented.

**Fix:** Remove commented code or move to version control history.

### 2. **Inconsistent Error Messages**
**Location:** Throughout codebase

**Issue:** Error messages use different formats and styles.

**Fix:** Standardize error message format using a centralized error handling function.

### 3. **Hardcoded Values**
**Location:** Multiple files

**Issue:** Hardcoded paths, URLs, and values should be configurable.

**Examples:**
- `REPO_URL="https://raw.githubusercontent.com/yonasuriv/sonda/refs/heads/main/lib/version/current"`
- Installation directory paths

**Fix:** Use configuration files or environment variables.

### 4. **Duplicate Code**
**Location:** `lib/includes/logic` and `modules/core/main`

**Issue:** Similar code for reading system information exists in multiple places.

**Fix:** Consolidate into shared functions.

### 5. **Missing Function Documentation**
**Location:** All bash functions

**Issue:** Functions lack documentation about parameters, return values, and side effects.

**Fix:** Add proper function documentation:
```bash
# Function: system_info
# Description: Gathers and displays comprehensive system information
# Parameters: None
# Returns: 0 on success, non-zero on failure
# Side effects: Outputs formatted system information to stdout
```

### 6. **Inconsistent Variable Naming**
**Location:** Throughout codebase

**Issue:** Mix of UPPERCASE, lowercase, and camelCase variable names.

**Fix:** Adopt consistent naming convention (e.g., UPPERCASE for constants, lowercase for variables).

### 7. **Missing Dependency Checks**
**Location:** `bin/init`, `SETUP.sh`

**Issue:** Scripts don't check if required commands (`curl`, `git`, `python3`, etc.) are available before use.

**Fix:** Add dependency checking function:
```bash
check_dependencies() {
    local deps=("curl" "git" "python3" "lspci")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing dependencies: ${missing[*]}"
        return 1
    fi
    return 0
}
```

### 8. **Unsafe File Sourcing**
**Location:** `bin/init` (lines 93-107)

**Issue:** Files are sourced without checking if they exist.

**Fix:**
```bash
if [[ -f "$STYLE" ]]; then
    source "$STYLE"
else
    echo "Error: Style file not found: $STYLE" >&2
    exit 1
fi
```

### 9. **Race Conditions**
**Location:** `bin/init` (line 33)

**Issue:** Temporary file creation without proper locking.

```bash
echo "[i] File created..." | cat - "$LOGFILE" > temp_file && mv temp_file "$LOGFILE"
```

**Fix:** Use atomic operations or proper locking mechanisms.

---

## Architecture & Design Issues

### 1. **Tight Coupling**
**Location:** `bin/init`

**Issue:** Main script sources many files directly, creating tight coupling.

**Fix:** Implement a module loading system with dependency resolution.

### 2. **No Configuration Management**
**Location:** Entire codebase

**Issue:** No centralized configuration file for paths, URLs, and settings.

**Fix:** Create a configuration file (e.g., `/etc/sonda.conf` or `~/.config/sonda.conf`).

### 3. **Mixed Responsibilities**
**Location:** `bin/init`

**Issue:** Main script handles argument parsing, file operations, and business logic.

**Fix:** Separate concerns into different functions/modules.

### 4. **No Logging Framework**
**Location:** Entire codebase

**Issue:** Ad-hoc logging with no centralized logging system.

**Fix:** Implement a proper logging framework with levels (DEBUG, INFO, WARN, ERROR).

### 5. **Hardcoded Python Path**
**Location:** `bin/init` (line 170)

**Issue:** Uses `python` instead of `python3`, which may not exist on all systems.

**Fix:** Use `python3` explicitly or check for availability.

---

## Documentation Issues

### 1. **License Mismatch**
**Location:** `README.md` vs `LICENSE`

**Issue:** README states "MIT License" but LICENSE file contains GPL v3.

**Fix:** Align license information in both files.

### 2. **Missing API Documentation**
**Location:** All modules

**Issue:** No documentation for functions, parameters, or return values.

**Fix:** Add comprehensive API documentation.

### 3. **Incomplete README**
**Location:** `README.md`

**Issue:** Missing information about:
- System requirements
- Troubleshooting
- Development setup
- Contributing guidelines
- Known issues

**Fix:** Expand README with comprehensive documentation.

### 4. **No Man Pages**
**Location:** Entire codebase

**Issue:** No manual pages for command-line interface.

**Fix:** Create man pages for the `sonda` command.

### 5. **Missing Changelog**
**Location:** Repository root

**Issue:** No CHANGELOG.md file to track version history.

**Fix:** Create and maintain a CHANGELOG.md file.

---

## Installation Instructions

### Prerequisites

1. **System Requirements:**
   - Debian-based Linux distribution (Ubuntu, Debian, Kali Linux, etc.)
   - Bash 4.0 or higher
   - Python 3.6 or higher
   - Git
   - Sudo/root access for installation

2. **Required Dependencies:**
   - `curl` - For fetching remote version information
   - `git` - For cloning and updating the repository
   - `python3` - For network information module
   - `python3-psutil` - For network interface information
   - `python3-requests` - For IP geolocation API calls
   - `python3-colorama` - For colored terminal output
   - `lspci` - For hardware information (usually in `pciutils` package)
   - `inxi` - For system information
   - `net-tools`, `sysstat`, `mesa-utils`, `upower`, `wmctrl`, `x11-xserver-utils`, `libglib2.0-bin` - System utilities
   
   **Optional:**
   - `lolcat` - For rainbow-colored output (falls back to single color if not installed)
   - `python3-pip` - For manual Python package management

### Clean Installation

#### Method 1: From GitHub Repository (Recommended)

```bash
# Clone the repository
git clone https://github.com/yonasuriv/sonda.git
cd sonda

# Make SETUP.sh executable
chmod +x SETUP.sh

# Run installation (requires sudo)
sudo ./SETUP.sh -i
# or
sudo ./SETUP.sh --install
```

#### Method 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/yonasuriv/sonda.git
cd sonda

# Install Python dependencies
pip3 install -r requirements.txt

# Install system dependencies (Debian/Ubuntu)
sudo apt update
sudo apt install -y lolcat inxi pciutils

# Copy files to installation directory
INSTALL_DIR="$HOME/.local/share/sonda"
mkdir -p "$INSTALL_DIR"
cp -r . "$INSTALL_DIR"

# Create symlink to binary
sudo ln -sf "$INSTALL_DIR/bin/init" /usr/bin/sonda
sudo chmod +x /usr/bin/sonda

# Install desktop file (optional)
sudo cp "$INSTALL_DIR/static/shortcuts/sonda.desktop" /usr/share/applications/

# Set proper permissions
sudo chown -R "$USER:$USER" "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"
```

### Post-Installation

1. **Verify Installation:**
   ```bash
   sonda --version
   ```

2. **Test Basic Functionality:**
   ```bash
   sonda -s    # System information
   sonda -n    # Network information
   sonda -h    # Help
   ```

3. **Update Shell Configuration (Optional):**
   The installation script may add `sonda -x` to your shell's rc file. Check:
   ```bash
   grep "sonda" ~/.bashrc   # For bash
   grep "sonda" ~/.zshrc    # For zsh
   ```

---

## Uninstallation Instructions

### Method 1: Using SETUP Script (Recommended)

```bash
# Navigate to installation directory (if you still have the repo)
cd /path/to/sonda

# Run uninstallation
sudo ./SETUP.sh -u
# or
sudo ./SETUP.sh --uninstall
```

### Method 2: Manual Uninstallation

```bash
# Remove binary symlink
sudo rm -f /usr/bin/sonda

# Remove desktop file
sudo rm -f /usr/share/applications/sonda.desktop

# Remove symbolic link from /usr/share
sudo rm -f /usr/share/sonda

# Remove installation directory
rm -rf ~/.local/share/sonda

# Remove sudoers entry (if added)
sudo visudo  # Manually remove the entry for apt update

# Remove from shell rc files (if added)
sed -i '/sonda -x/d' ~/.bashrc
sed -i '/sonda -x/d' ~/.zshrc
```

### Cleanup Verification

```bash
# Verify binary is removed
which sonda  # Should return nothing

# Verify files are removed
ls ~/.local/share/sonda  # Should return "No such file or directory"

# Verify desktop file is removed
ls /usr/share/applications/sonda.desktop  # Should return "No such file or directory"
```

---

## Automatic Update from GitHub

### Method 1: Using Built-in Update Command

```bash
# Check current version
sonda --version

# Check for updates
sonda -v

# Update to latest version
sonda -u
# or
sonda --update
```

### Method 2: Manual Update via Git

```bash
# Navigate to installation directory
cd ~/.local/share/sonda

# Ensure git is configured
git config --global --add safe.directory ~/.local/share/sonda

# Fetch latest changes
git fetch origin main

# Check what will be updated
git log HEAD..origin/main

# Update to latest version
git pull origin main

# Verify update
sonda --version
```

### Method 3: Automated Update Script

Create a script for automated updates:

```bash
#!/bin/bash
# File: ~/bin/update-sonda.sh

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/sonda"
REPO_URL="https://github.com/yonasuriv/sonda.git"

if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "Error: Sonda not installed at $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# Check if it's a git repository
if [[ ! -d .git ]]; then
    echo "Error: Installation directory is not a git repository"
    exit 1
fi

# Configure git safe directory
git config --global --add safe.directory "$INSTALL_DIR"

# Fetch and pull latest changes
echo "Updating Sonda..."
git fetch origin main
git pull origin main

# Get version
VERSION=$(cat lib/version/current 2>/dev/null || echo "Unknown")
echo "Sonda updated to version: $VERSION"
```

Make it executable:
```bash
chmod +x ~/bin/update-sonda.sh
```

Add to crontab for automatic updates (optional):
```bash
# Update weekly on Sundays at 2 AM
0 2 * * 0 ~/bin/update-sonda.sh >> ~/.local/share/sonda/update.log 2>&1
```

### Method 4: Reinstall from GitHub

If the installation directory is corrupted or not a git repository:

```bash
# Backup current installation (optional)
cp -r ~/.local/share/sonda ~/.local/share/sonda.backup

# Remove old installation
rm -rf ~/.local/share/sonda

# Reinstall from GitHub
git clone https://github.com/yonasuriv/sonda.git ~/.local/share/sonda

# Ensure binary symlink exists
sudo ln -sf ~/.local/share/sonda/bin/init /usr/bin/sonda
sudo chmod +x /usr/bin/sonda
```

### Update Troubleshooting

**Issue: "fatal: not a git repository"**
```bash
cd ~/.local/share/sonda
git init
git remote add origin https://github.com/yonasuriv/sonda.git
git fetch origin main
git reset --hard origin/main
```

**Issue: "Permission denied"**
```bash
# Fix permissions
sudo chown -R "$USER:$USER" ~/.local/share/sonda
chmod -R u+w ~/.local/share/sonda
```

**Issue: "safe.directory" error**
```bash
git config --global --add safe.directory ~/.local/share/sonda
```

---

## Recommended Improvements

### High Priority

1. **Add Error Handling:**
   - Implement `set -euo pipefail` in all bash scripts
   - Add error checking for all file operations
   - Implement proper exit codes

2. **Security Hardening:**
   - Remove or secure `eval` usage
   - Add input validation
   - Implement safe sudoers modification

3. **Dependency Management:**
   - Add dependency checking before execution
   - Create proper requirements file for system packages
   - Document all dependencies

4. **Configuration Management:**
   - Create centralized configuration file
   - Make paths and URLs configurable
   - Support environment variable overrides

### Medium Priority

5. **Code Quality:**
   - Remove commented code
   - Standardize error messages
   - Consolidate duplicate code
   - Add function documentation

6. **Testing:**
   - Add unit tests for functions
   - Add integration tests
   - Add test coverage reporting

7. **Logging:**
   - Implement proper logging framework
   - Add log rotation
   - Support different log levels

### Low Priority

8. **Documentation:**
   - Expand README
   - Create man pages
   - Add API documentation
   - Create CHANGELOG

9. **User Experience:**
   - Add progress indicators
   - Improve error messages
   - Add verbose/debug modes
   - Implement dry-run option

10. **Performance:**
    - Optimize file I/O operations
    - Cache frequently accessed data
    - Reduce redundant system calls

---

## Summary

This codebase has several areas that need improvement, particularly around:
- **Security:** Unsafe `eval` usage, improper sudoers handling
- **Error Handling:** Missing error checks and proper exit codes
- **Code Quality:** Commented code, inconsistent styles, duplicate code
- **Documentation:** License mismatch, incomplete documentation

However, the core functionality is solid, and with the recommended improvements, this can become a robust and maintainable system information tool.

---

## Contributing

When contributing to this project, please:
1. Follow the coding standards outlined in this document
2. Add proper error handling to all new code
3. Document all functions and major code sections
4. Test your changes thoroughly
5. Update this document if you identify new issues or improvements

---

**Last Updated:** $(date +"%Y-%m-%d")
**Version:** 1.8.2
