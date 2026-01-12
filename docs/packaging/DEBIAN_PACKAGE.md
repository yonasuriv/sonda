# Sonda Debian Package

## Overview

Sonda is now available as a proper Debian package (`.deb`), providing clean installation and uninstallation without needing the SETUP.sh script.

## Quick Start

### Build the Package

```bash
# Install build dependencies (one-time)
sudo apt update
sudo apt install -y build-essential debhelper dh-python python3-all

# Build the package
make build
```

### Install

```bash
# Install the .deb file
sudo dpkg -i ../sonda_*.deb

# Fix dependencies if needed
sudo apt-get install -f
```

### Uninstall

```bash
# Clean removal
sudo apt remove sonda
```

## Package Structure

### Files Created

```
debian/
├── changelog          # Version history
├── compat             # Debhelper compatibility
├── control            # Package metadata and dependencies
├── copyright          # License information
├── postinst          # Post-installation script
├── postrm            # Post-removal script
├── prerm             # Pre-removal script
├── rules             # Build rules
└── source/
    └── format        # Source package format
```

### Installation Locations

After installation, files are placed in standard system directories:

- `/usr/bin/sonda` - Main executable (available system-wide)
- `/usr/share/sonda/` - All data files (bin, lib, modules, static)
- `/usr/share/applications/sonda.desktop` - Desktop application entry
- `/usr/share/pixmaps/sonda.png` - Application icon
- `~/.logs/sonda/` - User log files (created per-user)

## Advantages Over SETUP.sh

### ✅ Standard Package Management
- Install with `dpkg -i` or `apt install`
- Uninstall with `apt remove` or `dpkg -r`
- Automatic dependency resolution
- Package information via `dpkg -l sonda`

### ✅ Clean Installation
- Files in proper system directories
- No manual symlink creation needed
- No sudoers modifications
- No user-specific installations

### ✅ Clean Uninstallation
- Complete removal with one command
- No leftover files or directories
- Desktop database automatically updated
- Icon cache automatically updated

### ✅ System-Wide Access
- Available to all users
- No per-user installation needed
- Standard Linux package structure

### ✅ Desktop Integration
- Proper .desktop file installation
- Icon in standard location
- Appears in application menus
- Desktop database integration

## Dependencies

The package automatically handles these dependencies:

**Required:**
- bash (>= 4.0)
- curl
- git
- python3
- python3-psutil
- python3-requests
- python3-colorama
- inxi
- pciutils
- lolcat

**Recommended:**
- python3-pip

All dependencies are automatically installed when you run `apt-get install -f` after installing the .deb file.

## Building the Package

### Method 1: Using Makefile (Easiest)

```bash
make build        # Build only
make install      # Build and install
make clean        # Clean build artifacts
```

### Method 2: Using dpkg-buildpackage

```bash
dpkg-buildpackage -us -uc -b
```

### Method 3: Using debuild (for signed packages)

```bash
debuild -us -uc
```

## Installation Steps

1. **Build the package:**
   ```bash
   make build
   ```

2. **Install the package:**
   ```bash
   sudo dpkg -i ../sonda_*.deb
   ```

3. **Fix dependencies (if needed):**
   ```bash
   sudo apt-get install -f
   ```

4. **Verify installation:**
   ```bash
   sonda --version
   ```

## Uninstallation

```bash
# Remove the package
sudo apt remove sonda

# Or
sudo dpkg -r sonda
```

This will:
- Remove `/usr/bin/sonda`
- Remove `/usr/share/sonda/`
- Remove desktop file and icon
- Update desktop database
- Update icon cache
- **Keep user logs** in `~/.logs/sonda/` (user data preserved)

## Verification

After installation, verify everything works:

```bash
# Check binary
which sonda
sonda --version

# Check package
dpkg -l sonda
dpkg -L sonda

# Check desktop file
desktop-file-validate /usr/share/applications/sonda.desktop

# Test functionality
sonda --help
sonda -s
```

## Migration from SETUP.sh Installation

If you previously installed using SETUP.sh:

1. **Uninstall old installation:**
   ```bash
   sudo ./SETUP.sh -u
   ```

2. **Remove old files manually (if needed):**
   ```bash
   sudo rm -rf ~/.local/share/sonda
   sudo rm -f /usr/share/sonda
   sudo rm -f /usr/bin/sonda
   ```

3. **Install new .deb package:**
   ```bash
   make build
   sudo dpkg -i ../sonda_*.deb
   sudo apt-get install -f
   ```

## Troubleshooting

### Build Issues

**Error: "command not found: dh"**
```bash
sudo apt install debhelper
```

**Error: "dpkg-buildpackage: command not found"**
```bash
sudo apt install build-essential devscripts
```

### Installation Issues

**Error: "dependency problems"**
```bash
sudo apt-get install -f
```

**Error: "command not found: sonda"**
```bash
hash -r  # Reload shell
# Or restart terminal
```

### Desktop Integration Issues

**Desktop file not appearing:**
```bash
sudo update-desktop-database
sudo gtk-update-icon-cache /usr/share/pixmaps
```

## Package Information

- **Package Name:** sonda
- **Version:** 1.8.2-1
- **Architecture:** all (architecture-independent)
- **Section:** utils
- **Priority:** optional
- **Maintainer:** yonasuriv

## Next Steps

1. Build the package: `make build`
2. Test installation: `sudo dpkg -i ../sonda_*.deb`
3. Verify functionality: `sonda --help`
4. Distribute the .deb file to users

The package is production-ready and follows Debian packaging standards!
