# Sonda - Debian Package Installation

## Quick Start

### Install Latest Release

```bash
git clone https://github.com/yonasuriv/sonda /tmp/sonda
cd /tmp/sonda
./install.sh release -d debian
```

### Build and Install From Source

```bash
./install.sh source -d debian
```

Add `-v` to either command to show full command output. By default, the installer hides command noise and prints high-level progress plus errors.

### Lower-Level Debian Helper

The top-level installer delegates source builds to `scripts/install_debian.sh`.

The build output is kept inside the repository:

```bash
dist/sonda_<version>/
```

## Uninstallation

```bash
# Remove the package
sudo apt remove sonda

# Or
sudo dpkg -r sonda
```

## What Gets Installed

- **Binary**: `/usr/bin/sonda` - Main executable
- **Data**: `/usr/share/sonda/` - All modules, libraries, and static files
- **Desktop File**: `/usr/share/applications/sonda.desktop` - Application launcher
- **Icon**: `/usr/share/pixmaps/sonda.png` - Application icon

## Benefits of .deb Package

✅ **Clean Installation**: All files in proper system directories
✅ **Clean Uninstallation**: Complete removal with `apt remove` or `dpkg -r`
✅ **Dependency Management**: Automatic dependency resolution
✅ **Desktop Integration**: Proper .desktop file and icon
✅ **System-Wide**: Available to all users
✅ **Standard Location**: Follows Debian/Ubuntu conventions

## Verification

After installation:

```bash
# Check version
sonda --version

# Test help
sonda --help

# Check installation
dpkg -l sonda
dpkg -L sonda
```

## Troubleshooting

If `sonda` command is not found after installation:

```bash
# Reload your shell
hash -r

# Or verify binary exists
ls -l /usr/bin/sonda

# Check PATH
echo $PATH | grep /usr/bin
```

For more details, see `BUILD_DEB.md`.
