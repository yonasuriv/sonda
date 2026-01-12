# Changelog

All notable changes to Sonda will be documented in this file.

## [1.8.5] - 2026-01-12

### Changed
- **Version file location**: Moved from `lib/version/current` to root `version` file
- **Version checking**: Updated all references to use root `version` file
- **Remote version URL**: Updated to `https://raw.githubusercontent.com/yonasuriv/sonda/refs/heads/main/version`
- **Documentation**: Organized all documentation into categorized folders
- **Update messages**: Improved update availability messages

### Fixed
- All version file references updated across the codebase
- Debian package build process updated for new version file location
- Makefile updated to read from root version file

### Documentation
- Created organized documentation structure:
  - `docs/installation/` - Installation guides
  - `docs/development/` - Development documentation
  - `docs/fixes/` - Bug fixes and improvements
  - `docs/packaging/` - Packaging documentation
- Added comprehensive README.md in docs directory
- Created CHANGELOG.md

## [1.8.4] - Previous Version

### Changed
- Directory structure reorganization:
  - `static/` → `assets/`
  - `modules/core/` → `modules/base/`
  - `lib/includes/*` → `lib/*`
- Removed duplicate update functions from `lib/version/check`
- Active update implementation consolidated in `bin/sonda`

### Fixed
- All path references updated after directory reorganization
- Unbound variable errors fixed
- Color stripping improvements for `--pretty` flag

## [1.8.2] - Earlier Version

### Added
- Debian package support
- Logging system
- Update functionality
- Comprehensive error handling
