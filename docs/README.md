# Sonda Documentation

This directory contains all documentation for the Sonda system information tool.

## Directory Structure

### 📦 Installation
- **README.md** - Main project documentation and overview
- **SETUP.sh** - Installation script documentation (if available)
- **INSTALL_DEB.md** - Debian package installation guide
- **BUILD_DEB.md** - Building Debian packages guide
- **README_DEB.md** - Debian package specific documentation

### 🔧 Development
- **DEVELOPMENT.md** - Code review and development guidelines
- **CHECKLIST.md** - Issue tracking checklist
- **TODO.md** - Development tasks and roadmap
- **TEST_RESULTS.md** - Test results and validation

### 🐛 Fixes
- **ARGUMENT_FIXES.md** - Command-line argument fixes
- **DEB_FIXES.md** - Debian package fixes
- **FLAGS_FIX.md** - Flag-related fixes
- **PRETTY_FIXES.md** - Output formatting fixes
- **UNBOUND_VARIABLES_FIX.md** - Variable initialization fixes
- **FIXES_APPLIED.md** - Summary of all applied fixes

### 📋 Packaging
- **DEBIAN_PACKAGE.md** - Debian packaging documentation

### 📝 Version & Changes
- **VERSION_CHANGES.md** - Version file location changes (v1.8.5)
- **CHANGELOG.md** - Complete version history and changelog

## Quick Links

- [Main README](../README.md) - Start here for general information
- [Installation Guide](installation/README.md) - How to install Sonda
- [Development Guide](development/DEVELOPMENT.md) - For contributors
- [Fixes Documentation](fixes/FIXES_APPLIED.md) - All bug fixes and improvements

## Version Information

Current version: **1.8.5**

Version file location: `/version` (root directory)

Version checking: The version is checked against the remote repository at:
`https://raw.githubusercontent.com/yonasuriv/sonda/refs/heads/main/version`

## Project Structure

```
sonda/
├── bin/              # Main executable
├── lib/              # Core libraries
├── modules/          # Information modules
├── assets/           # Art, icons, desktop files
├── debian/           # Debian packaging files
├── docs/             # Documentation (this directory)
└── version           # Version file (root)
```

## Contributing

See [DEVELOPMENT.md](development/DEVELOPMENT.md) for contribution guidelines.

## License

GPL-3.0+ (see LICENSE file in project root)
