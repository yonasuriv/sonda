# Sonda Debian Package

## Overview

Sonda is now available as a proper Debian package (`.deb`), providing clean installation and uninstallation without needing the SETUP.sh script.

## Quick Start

### Install Latest Release

```bash
git clone https://github.com/yonasuriv/sonda /tmp/sonda
cd /tmp/sonda
./install.sh release -d debian
```

### Build the Package

```bash
./install.sh source -d debian
```

### Install

```bash
# Install the latest release package
./install.sh release -d debian
```

### Uninstall

```bash
# Clean removal
sudo apt remove sonda
```

## Package Structure

### Files Created

```
build/debian/
├── changelog          # Version history
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
- Install with `apt-get install ./dist/sonda_*/sonda_*.deb`
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
- net-tools
- sysstat
- mesa-utils
- upower
- wmctrl
- x11-xserver-utils
- libglib2.0-bin

**Recommended:**
- python3-pip
- lolcat (optional - falls back to single color if not installed)

Runtime dependencies are automatically resolved when the helper installs the local `.deb` with APT.

## Building the Package

### Method 1: Using the Helper Script (Easiest)

```bash
./scripts/install_debian.sh build  # Build only
./install.sh source -d debian      # Build and install
make -f build/debian/rules clean   # Clean build artifacts
```

Artifacts are kept under `.build/` and `dist/`; nothing is written to the parent directory.

### Method 2: Using Debian Rules

```bash
make -f build/debian/rules build-package
```

### Method 3: Using debuild (for signed packages)

```bash
debuild -us -uc
```

## Installation Steps

1. **Build the package:**
   ```bash
   ./scripts/install_debian.sh build
   ```

2. **Install the package:**
   ```bash
   ./install.sh source -d debian
   ```

3. **Verify installation:**
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
   ./install.sh source -d debian
   ```

## Troubleshooting

### Build Issues

**Error: "command not found: dh"**
```bash
./install.sh source -d debian -v
```

**Error: "dpkg-buildpackage: command not found"**
```bash
./install.sh source -d debian -v
```

### Installation Issues

**Error: "dependency problems"**
```bash
./install.sh release -d debian -v
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
- **Version:** from `build/debian/changelog`
- **Architecture:** all (architecture-independent)
- **Section:** utils
- **Priority:** optional
- **Maintainer:** yonasuriv

## Next Steps

1. Build the package: `./scripts/install_debian.sh build`
2. Test installation: `./install.sh source -d debian`
3. Verify functionality: `sonda --help`
4. Distribute the `.deb` from `dist/sonda_<version>/`

The package is production-ready and follows Debian packaging standards!
