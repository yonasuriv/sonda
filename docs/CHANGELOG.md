# Changelog

All notable changes to Sonda will be documented in this file.

## [1.8.6] - 2026-01-12

### Added
- **Boot Information Module** (`modules/info/boot`):
  - Boot time analysis with systemd-analyze
  - Boot warnings and errors from journalctl
  - Boot mode detection (UEFI/Legacy BIOS)
  - Secure Boot status checking
  - Kernel errors and warnings from dmesg
- **Security Module** (`modules/info/security`):
  - Firewall status checking (ufw, nftables, iptables, firewalld)
  - SELinux/AppArmor status detection
  - SSH service status and port information
  - Disk encryption detection (LUKS/dm-crypt)
  - Security posture summary
- **Enhanced Network Status**:
  - VPN/protected/exposed detection in banner
  - Network status function in lib/logic
  - Integration with modules/base/banner
- **CPU Enhancements**:
  - CPU topology (sockets, cores, threads)
  - Frequency governor and min/max frequencies
  - Load averages (1/5/15 min)
  - Virtualization flags and hypervisor detection
  - Top CPU consuming processes
- **Disk Enhancements**:
  - Per-mount usage table with filesystem types
  - Encryption status detection (LUKS)
  - Inode usage monitoring
  - Filesystem and inode usage warnings
- **Network Enhancements**:
  - Network identity (primary IPs, interfaces, link state)
  - Default gateway and DNS server information
  - Active connections summary
- **Test Module Improvements**:
  - Enhanced boot and services checking
  - Improved firewall detection
  - Better error and warning reporting

### Changed
- Updated `bin/sonda` to source new boot and security modules
- Added `-T boot` and `-T security` targets
- Enhanced `-T all` to include boot and security information
- Improved network status detection in banner

### Documentation
- Updated help manual with new boot and security targets
- Enhanced module documentation

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
