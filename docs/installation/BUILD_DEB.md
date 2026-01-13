# Building Sonda Debian Package

## Prerequisites

Install build dependencies (minimal set - only what's needed to build):

```bash
sudo apt update
sudo apt install -y build-essential debhelper dh-python python3-all devscripts
```

## Building the Package

### Method 1: Using Makefile (Recommended)

```bash
# Build the package
make build

# Build and install
make install

# Clean build artifacts
make clean
```

### Method 2: Using dpkg-buildpackage

```bash
# Build the package
dpkg-buildpackage -us -uc -b

# The .deb file will be created in the parent directory
```

### Method 3: Using debuild (for signed packages)

```bash
# Build signed package (requires GPG setup)
debuild -us -uc
```

## Installation

### Install the .deb package:

```bash
# Install the package
sudo dpkg -i sonda_*.deb

# If dependencies are missing, install them:
sudo apt-get install -f
```

### Or use apt to install:

```bash
# After building, you can install with apt
sudo apt install ./sonda_*.deb
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
sudo apt install debhelper
```

### Missing dependencies during build
```bash
sudo apt install build-essential debhelper dh-python
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
reprepro -b repo includedeb stable sonda_*.deb
```
