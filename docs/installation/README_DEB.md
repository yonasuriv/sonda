# Sonda - Debian Package Installation

## Quick Start

### Build and Install

```bash
# Install build dependencies (minimal set)
sudo apt update
sudo apt install -y build-essential debhelper-compat dh-python python3-all python3-pip

# Build the package
make build

# Install the package
sudo dpkg -i ../sonda_*.deb

# If dependencies are missing:
sudo apt-get install -f
```

### Or use the simple method:

```bash
make install
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
