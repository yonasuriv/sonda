# Changelog

All notable changes to Sonda will be documented in this file.

## [2.0.1] - 2026-01-14

### Fixed
- **Help System Routing**: Fixed help command routing issues
  - `sonda --help` now correctly shows main help
  - `sonda help check` and `sonda help scan` now correctly show check/scan help
  - `sonda help audit` now correctly shows audit help
  - Added "scan" as alias for "check" in help system
  - Separated `help` command from `-h|--help` flags for proper topic routing
- **Audit Boot Mode**: Fixed critical issues preventing audit boot from running
  - Fixed `check_sudo_requirements` and `cleanup_sudo` function not found errors
  - Updated `PROMPT_SUDO` path from `$COMMON_DIR/sudo.sh` to `$UTILS_DIR/sudo.sh`
  - Added fallback sourcing for `sudo.sh` in boot init script
  - Fixed phase module loading by setting `AUDIT_MODULES` to boot modules directory
  - Fixed unbound variable errors for `AUDIT_CURRENT_PHASE` using `${AUDIT_CURRENT_PHASE:-}` pattern
  - Fixed loader path to use `$AUDIT_HELPERS/loader.sh` instead of `$AUDIT_LIB/loader.sh`
- **Banner Functions**: Fixed banner display issues
  - All three help commands now show appropriate banners/logos
  - Main help shows big logo (`logo_sonda_sysnet`)
  - Mode-specific help shows small banner (`banner_logo_small`)
  - Added banner to audit mode help display

### Changed
- **Help System**: Improved help command handling
  - `help` is now a standalone command that accepts topic arguments
  - Help topics: main, audit, check/scan, utils
  - Each mode's `--help` flag shows mode-specific help with appropriate banner
- **Sudo Helper Location**: Moved `sudo.sh` reference from `$COMMON_DIR` to `$UTILS_DIR` in config

## [2.0.0] - 2026-01-13

### Major Changes
- **Complete Architecture Refactoring**: Introduced modular mode system with separate `check` and `audit` modes
- **Centralized Configuration**: Created `sonda.conf` as single source of truth for all paths and variables
- **Mode System**: Implemented `-C` (check) and `-A` (audit) flags for explicit mode selection
- **Path Management**: All paths now use variables from centralized config, no hardcoded paths

### Added
- **Audit Mode**: Complete boot session auditor with phase-driven analysis
  - 13 audit phases covering firmware to desktop session
  - Comprehensive error, warning, and failure tracking
  - Detailed logging and anonymization support
  - Security posture analysis
- **Check Mode Enhancements**:
  - All targets working: cpu, gpu, disks, memory, kernel, devices, network, battery, boot, security, packages, all
  - Flag combinations: `-s`, `--save`, `-nc`, `--no-color`, `-v`, `-vv`, `-vvv`
  - Flags can appear before or after `-T target`
- **Configuration System**:
  - `load_sonda_config()` function automatically exports all variables
  - Shared core files in `src/lib/core/`
  - Mode-specific helpers in `src/modes/{check,audit}/helpers/`
- **Security Module**:
  - Firewall status (UFW, nftables, iptables, firewalld)
  - SELinux/AppArmor detection
  - SSH service status
  - Disk encryption detection
  - Security posture summary

### Fixed
- **Unbound Variable Errors**: Fixed all unbound variable issues across all modules
  - `layout.sh`: Fixed `print_header()` and `print_phase_header()` parameters
  - `anonimizer.sh`: Fixed `_ANON_INITIALIZED` and `AUDIT_DUMMY_IP` checks
  - `config.sh`: Fixed `AUDIT_PROJECT_ROOT` checks
  - `paths.sh`: Fixed all `AUDIT_PROJECT_ROOT` checks
- **Syntax Errors**: Fixed all `wc -l` parsing errors
  - Security module: nftables, iptables, ip6tables, AppArmor
  - Audit kernel module: hardware errors, kernel errors, warnings, module failures
  - Audit security module: NFT_RULES, IPT_RULES
- **Module Errors**: Fixed unbound `$key` variable in multiple modules
  - kernel, memory, devices, packages modules
- **Flag Parsing**: Fixed flag parsing to handle flags before/after `-T target`
- **Path Resolution**: Fixed audit mode `sudo.sh` path resolution

### Changed
- **Directory Structure**:
  - `src/modes/check/` - Check mode (formerly main script)
  - `src/modes/audit/` - Audit mode (new)
  - `src/lib/core/` - Shared core configuration
  - `src/lib/common/` - Shared common utilities
- **Help System**: Mode-specific help messages (`-C --help`, `-A --help`)
- **Installation**: Updated Debian package to include audit mode and set proper permissions

### Documentation
- Updated all documentation to reflect new architecture
- Added comprehensive testing documentation
- Updated installation guides
- Created audit mode documentation

## [1.8.7] - 2026-01-13

### Fixed
- Security module syntax errors
- Flag parsing improvements
- Complete argument testing and verification

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
