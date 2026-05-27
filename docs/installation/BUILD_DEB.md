# Building Sonda Debian Package

## Prerequisites

Install build dependencies (minimal set - only what's needed to build):

```bash
./install.sh source -d debian
```

## Building the Package

### Method 1: Using the Helper Script (Recommended)

```bash
# Build the package
./scripts/install_debian.sh build

# Build and install
./install.sh source -d debian

# Clean build artifacts
make -f debian/rules clean
```

Build artifacts are kept inside the repository under `.build/` and `dist/`.

### Method 2: Using Debian Rules

```bash
# Build the package
make -f debian/rules build-package
```

### Method 3: Using debuild (for signed packages)

```bash
# Build signed package (requires GPG setup)
debuild -us -uc
```

## Installation

### Install the .deb package:

```bash
# Install the built package and resolve runtime dependencies through APT
./install.sh source -d debian
```

### Or install the local package directly:

```bash
sudo apt-get install ./dist/sonda_*/sonda_*.deb
```

## Uninstallation

```bash
# Remove the package
sudo apt remove sonda

# Or using dpkg
sudo dpkg -r sonda
```

## Package Structure

The package installs:
- Binary: `/usr/bin/sonda`
- Data files: `/usr/share/sonda/`
- Desktop file: `/usr/share/applications/sonda.desktop`
- Icon: `/usr/share/pixmaps/sonda.png`

## Verification

After installation, verify:

```bash
# Check if binary is available
which sonda

# Test the command
sonda --version

# Check desktop file
desktop-file-validate /usr/share/applications/sonda.desktop

# Check package info
dpkg -l sonda
dpkg -L sonda
```

## Troubleshooting

### Build fails with "command not found: dh"
```bash
./install.sh source -d debian -v
```

### Missing dependencies during build
```bash
./install.sh source -d debian -v
```

### Package installs but command not found
```bash
# Check if /usr/bin is in PATH
echo $PATH

# Verify binary exists
ls -l /usr/bin/sonda

# Reload shell or run:
hash -r
```

### Desktop file not showing in applications menu
```bash
# Update desktop database
sudo update-desktop-database

# Update icon cache
sudo gtk-update-icon-cache /usr/share/pixmaps
```

## Creating a Repository (Optional)

To create your own APT repository:

```bash
# Install reprepro
sudo apt install reprepro

# Create repository structure
mkdir -p repo/conf

# Create distributions file
cat > repo/conf/distributions << EOF
Origin: Your Name
Label: Sonda Repository
Codename: stable
Architectures: all
Components: main
Description: Sonda package repository
EOF

# Add package to repository
reprepro -b repo includedeb stable dist/sonda_*/sonda_*.deb
```
