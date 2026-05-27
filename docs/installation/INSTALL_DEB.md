# Installing Sonda from .deb Package

## Quick Installation Guide

### Fast Path: Install Latest Release

```bash
git clone https://github.com/yonasuriv/sonda /tmp/sonda
cd /tmp/sonda
./install.sh release -d debian
```

APT installs the local package and resolves runtime dependencies from your configured repositories.

### Step 1: Build the Package From Source

```bash
./install.sh source -d debian
```

This creates the package under `dist/sonda_<version>/`. No package artifacts are written to the parent directory.

Add `-v` to show full command output. By default, the installer prompts for sudo first, then hides command noise unless a command fails.

### Step 2: Verify Installation

```bash
# Check if sonda is available
sonda --version

# Test the help
sonda --help

# Check package info
dpkg -l sonda
```

## Uninstallation

```bash
# Remove the package (clean uninstall)
sudo apt remove sonda

# Or using dpkg
sudo dpkg -r sonda
```

## What's Different from SETUP.sh?

### Advantages of .deb Package:

1. **Standard Installation**: Files go to standard system directories
   - `/usr/bin/sonda` - Executable
   - `/usr/share/sonda/` - Data files
   - `/usr/share/applications/sonda.desktop` - Desktop entry
   - `/usr/share/pixmaps/sonda.png` - Icon

2. **Clean Uninstall**: `apt remove sonda` removes everything cleanly

3. **Dependency Management**: Dependencies are automatically resolved

4. **System-Wide**: Available to all users, not just one user

5. **Desktop Integration**: Properly integrated with desktop environment

6. **Package Management**: Can be managed with standard Debian tools

## File Locations

After installation:

- **Binary**: `/usr/bin/sonda`
- **Configuration**: `/usr/share/sonda/`
- **Logs**: `~/.logs/sonda/` (per-user)
- **Desktop File**: `/usr/share/applications/sonda.desktop`
- **Icon**: `/usr/share/pixmaps/sonda.png`

## Troubleshooting

### Command not found after installation

```bash
# Reload shell
hash -r

# Or restart terminal

# Verify binary exists
ls -l /usr/bin/sonda
```

### Desktop file not appearing

```bash
# Update desktop database
sudo update-desktop-database

# Update icon cache  
sudo gtk-update-icon-cache /usr/share/pixmaps
```

### Missing dependencies

```bash
# Re-run dependency installation
./install.sh source -d debian -v
```

## Building for Distribution

To create a signed package for distribution:

```bash
# Install signing tools
sudo apt install devscripts

# Build signed package (requires GPG key)
debuild -us -uc
```

## Next Steps

- The package is ready to use!
- No need for SETUP.sh anymore
- Clean install/uninstall with standard package tools
- All features work the same as before
