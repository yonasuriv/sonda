# Boot Session Auditor

A comprehensive, phase-driven boot session auditing tool for Linux systems. Scans system logs from boot to graphical session, identifying errors, warnings, and performance issues across the entire boot chain.

## Overview

The Boot Session Auditor performs a chronological analysis of your system's boot process, from firmware initialization through to the graphical desktop session. It's designed to help diagnose boot issues, performance problems, and system stability concerns by examining logs, systemd services, hardware errors, and more.

### Key Features

- **Phase-Driven Architecture**: Follows the actual boot chain from firmware to GUI
- **Comprehensive Coverage**: 13 audit phases covering the entire boot process
- **Configurable Output**: Separate settings for console and log output
- **Performance Optimized**: Fast execution with optional anonymization
- **Detailed Logging**: Optional detailed logs with timestamp and user information
- **Anonymization Support**: Replace sensitive data (hostname, IPs, usernames) with dummy values
- **Flexible Filtering**: Control what's shown based on severity levels and maximum findings

## Quick Start

### Basic Usage

```bash
# Run audit (silent mode, no logs)
./audit.sh

# Run with verbose output
./audit.sh -v

# Save detailed logs
./audit.sh --save-logs

# Verbose output with logs
./audit.sh -v --save-logs
```

### Command-Line Options

```
Usage: ./audit.sh [OPTIONS]

Options:
  --save-logs, --log  Save detailed logs to ./logs directory
  --log-dir, -d DIR   Specify custom log directory (default: ./logs)
  -v, --verbose       Show detailed information on terminal
  -s, --silent        Hide detailed info from terminal, not logs (default)
  -t, --timestamp     Add timestamp to log filenames
  -nt, --no-timestamp Remove timestamp from log filenames (default)
  -u, --user          Add username to log filenames
  -a, --no-user       Hide username from log filenames (default)
  --help, -h          Show this help message
```

## Architecture

### Project Structure

```
boot-session-auditer/
├── audit.sh                          # Main entry point
├── src/
│   └── audit/
│       ├── config/
│       │   ├── default.conf          # Default configuration
│       │   └── rules.sh              # Filter rules (future)
│       ├── core/                     # Core functionality
│       │   ├── init.sh               # Initialization
│       │   ├── config.sh             # Configuration management
│       │   ├── paths.sh              # Path resolution
│       │   ├── colors.sh             # ANSI color codes
│       │   ├── commands.sh           # Common command variables
│       │   ├── functions.sh          # Core functions (pass/fail/warn/skip)
│       │   ├── layout.sh             # Output formatting
│       │   ├── filter.sh              # Output filtering
│       │   ├── phases.sh             # Phase registry
│       │   ├── loader.sh              # Module loader
│       │   ├── summary.sh             # Summary generation
│       │   ├── sudo.sh               # Sudo management
│       │   └── anonimizer.sh         # Anonymization functions
│       ├── modules/                  # Audit phase modules
│       │   ├── 00_context_and_baseline.sh
│       │   ├── 01_firmware_and_bootloader.sh
│       │   ├── 02_kernel_and_hardware_bringup.sh
│       │   ├── 03_initramfs_and_rootfs.sh
│       │   ├── 04_systemd_boot_and_critical_path.sh
│       │   ├── 05_storage_and_filesystem_integrity.sh
│       │   ├── 06_network_stack_and_connectivity.sh
│       │   ├── 07_security_controls_and_policy_enforcement.sh
│       │   ├── 08_display_stack_and_graphical_session.sh
│       │   ├── 09_user_session_and_desktop_services.sh
│       │   ├── 10_resource_pressure_and_system_stability.sh
│       │   ├── 11_current_system_posture.sh
│       │   └── 12_top_findings_and_risk_summary.sh
│       └── docs/                     # Phase documentation
└── logs/                             # Log output directory
```

### Audit Phases

The audit follows the boot chain chronologically:

1. **Phase 00: Audit Context and Baselines** - Hostname, OS, kernel, init system, desktop, GPU, storage, boot ID, uptime, timezone, journal status
2. **Phase 01: Firmware and Bootloader** - Secure Boot, firmware/bootloader timing, errors
3. **Phase 02: Kernel and Hardware Bring-up** - Hardware errors, kernel errors/warnings, module failures, GPU init, ACPI issues, kernel taint, udev rules verification
4. **Phase 03: Initramfs and Root Filesystem Handoff** - Initramfs errors, cryptsetup/LUKS, root mount, fsck, read-only remounts, swap
5. **Phase 04: Systemd Userspace** - Boot timing analysis, slow services, failed units, boot-to-GUI time
6. **Phase 05: Storage and Filesystem Integrity** - I/O errors, filesystem errors, SMART health, disk usage monitoring (>=90%)
7. **Phase 06: Network Stack and Connectivity** - Network manager errors, DNS issues, DHCP, link flaps, Wi-Fi auth failures
8. **Phase 07: Security Controls and Policy Enforcement** - SELinux, AppArmor, UFW/firewalld/nftables/iptables firewall, kernel lockdown, seccomp
9. **Phase 08: Display Stack and Graphical Session Start** - Display manager, compositor crashes, GPU/DRM errors, monitor issues, Wayland/X11 errors
10. **Phase 09: User Session and Desktop Services** - User service failures, desktop crashes, GNOME extension status and crashes, portal services, keyring, DBus
11. **Phase 10: Resource Pressure and System Stability** - OOM events, memory pressure, thermal throttling, ACPI issues, disk/inode usage, load average
12. **Phase 11: Current System Posture Snapshot** - Current resource usage, coredumps, system health, network connections, package manager integrity (dpkg, apt, snap, flatpak)
13. **Phase 12: Top Findings and Risk Summary** - Aggregated findings and recommendations

## Configuration

### Configuration File

Edit `src/audit/config/default.conf` to customize default behavior. Settings can be overridden by command-line arguments.

### Key Configuration Options

#### Output Control

```bash
# Console verbosity (true = show details, false = summary only)
AUDIT_VERBOSE=false

# Minimum severity to show (pass, warn, fail)
AUDIT_CONSOLE_MIN_LEVEL="warn"  # Console: show warnings and failures
AUDIT_LOG_MIN_LEVEL="pass"      # Logs: show everything

# Maximum findings per category (0 = no limit)
AUDIT_CONSOLE_MAX_FINDINGS=5    # Console: limit to 5 per category
AUDIT_LOG_MAX_FINDINGS=0        # Logs: no limit

# Skip specific phases (space-separated phase IDs)
AUDIT_CONSOLE_SKIP_PHASES=""    # e.g., "07 11" to skip phases 7 and 11
AUDIT_LOG_SKIP_PHASES=""
```

#### Logging

```bash
# Log directory
AUDIT_LOG_DIR="./logs"

# Timestamp in filenames
AUDIT_LOG_TIMESTAMP=true
AUDIT_CONSOLE_TIMESTAMP=false

# Username in filenames
AUDIT_LOG_USER=false
AUDIT_CONSOLE_USER=false
```

#### Anonymization

```bash
# Master switches - must be true for anonymization to work
AUDIT_CONSOLE_ANONYMIZE=false   # Anonymize console output
AUDIT_LOG_ANONYMIZE=true        # Anonymize log files

# What to anonymize (only if above is true)
AUDIT_ANONYMIZE_IP=true         # Replace IP addresses
AUDIT_ANONYMIZE_HOST=true       # Replace hostname
AUDIT_ANONYMIZE_USER=true       # Replace username and home directory

# Dummy values
AUDIT_DUMMY_IP="153.242.117.210"
AUDIT_DUMMY_HOST="lizard.local"
AUDIT_DUMMY_USER="lizard"

# Performance: anonymize after writing (faster) or before writing (safer)
AUDIT_LOG_ANONYMIZE_AFTER_WRITE=true  # true = faster, false = safer
```

**Performance Note**: When `AUDIT_CONSOLE_ANONYMIZE=false` and `AUDIT_LOG_ANONYMIZE=false`, anonymization code is completely bypassed for maximum performance.

## Usage Examples

### Basic Audit

```bash
# Quick audit (silent, no logs)
./audit.sh
```

### Verbose Output

```bash
# Show detailed information on terminal
./audit.sh -v
```

### Save Logs

```bash
# Save detailed logs with timestamp
./audit.sh --save-logs

# Custom log directory
./audit.sh --save-logs --log-dir /tmp/audit-logs
```

### Combined Options

```bash
# Verbose output with logs, timestamp, and username
./audit.sh -v --save-logs -t -u
```

### Anonymized Output

```bash
# Enable anonymization in default.conf first, then:
./audit.sh --save-logs -v
```

## Output Format

### Console Output

The console shows a summary by default, with detailed information available in verbose mode (`-v`):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Phase 04: Systemd Userspace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Boot analysis successful
⚠ Total boot time slow: 61.9s
✓ Graphical target time acceptable: 4.9s
⚠ Found 3 service(s) that failed to start
```

### Summary Report

At the end, a comprehensive summary is displayed:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Audit Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Boot scope:      current boot (boot id=abc123)
Boot to GUI:     ✓ Success
Total time:      61.923s (firmware 20.285s, loader 3.147s, kernel 33.479s, userspace 5.009s)
Phases run:      13
Tests:           45 (pass 30, warn 10, fail 3, skip 2)

Failures by phase (sorted by count):
  04 Systemd Userspace...                     3 fail, 5 warn
  02 Kernel and Hardware Bring-up...          2 fail, 8 warn
  ...

Highest Impact Findings:
  ...
```

### Log Files

When `--save-logs` is used, two files are created:

- **Summary log**: `boot_audit_YYYYMMDD_HHMMSS.log` - Summary of all test results
- **Detailed log**: `boot_audit_YYYYMMDD_HHMMSS_detailed.log` - Full details, command outputs, and raw data

## Requirements

- **Bash 4.0+** (for associative arrays)
- **systemd** (for boot analysis and journal access)
- **journalctl** (for log access)
- **Optional**: `sudo` (for enhanced accuracy - some checks require root)
- **Optional**: `smartctl` (for disk health checks)
- **Optional**: `ufw` (for firewall status checks)

## Performance

The auditor is optimized for speed:

- **Fast Path**: When anonymization is disabled, all anonymization code is bypassed
- **Bulk Processing**: Log anonymization can be done after writing (faster) or before writing (safer)
- **Efficient Filtering**: Output filtering happens early to avoid unnecessary processing
- **Cached Initialization**: Expensive operations (like IP lookup) are cached and only run when needed

### Performance Tips

1. **Disable anonymization** if not needed: Set `AUDIT_CONSOLE_ANONYMIZE=false` and `AUDIT_LOG_ANONYMIZE=false`
2. **Use after-write anonymization**: Set `AUDIT_LOG_ANONYMIZE_AFTER_WRITE=true` for faster log processing
3. **Limit console output**: Set `AUDIT_CONSOLE_MAX_FINDINGS=5` to reduce terminal output
4. **Skip phases**: Use `AUDIT_CONSOLE_SKIP_PHASES` to skip phases you don't need

## Troubleshooting

### Sudo Prompts

The script will prompt for sudo if needed. If you already have sudo access, it will detect and use it automatically.

### Missing Commands

Some checks may be skipped if required commands are not installed:
- `smartctl` → Disk health checks skipped
- `ufw` → Firewall checks skipped
- `getenforce` → SELinux checks skipped

### Slow Performance

If the audit is slow:

1. Check if anonymization is enabled unnecessarily
2. Verify `AUDIT_LOG_ANONYMIZE_AFTER_WRITE=true` for faster log processing
3. Reduce `AUDIT_CONSOLE_MAX_FINDINGS` to limit output
4. Skip unnecessary phases with `AUDIT_CONSOLE_SKIP_PHASES`

### Log Files Not Created

- Ensure `--save-logs` flag is used
- Check write permissions in the log directory
- Verify `AUDIT_SAVE_LOGS=true` in configuration

## Development

### Adding New Audit Phases

1. Create a new module file in `src/audit/modules/` following the naming pattern: `XX_description.sh`
2. Register the phase in `src/audit/core/phases.sh`
3. Use the core functions: `pass()`, `fail()`, `warn()`, `skip()`, `info()`
4. Call `print_phase_header` at the start (auto-detects phase from filename)

### Core Functions

- `pass "message"` - Test passed
- `fail "message"` - Test failed (critical)
- `warn "message"` - Warning (non-critical issue)
- `skip "message"` - Test skipped (tool/data unavailable)
- `info "message"` - Informational message (verbose only)
- `log_output "text"` - Write to summary log
- `log_detailed "text"` - Write to detailed log
- `show_indented_details` - Show details with indentation (respects verbose mode)

### Module Template

```bash
#!/usr/bin/env bash
# Phase XX: Description
# Purpose: What this phase checks

print_phase_header

# Test case 1: Description
if command -v tool >/dev/null 2>&1; then
    # Check logic here
    if [[ condition ]]; then
        pass "Success message"
    else
        fail "Failure message"
    fi
else
    skip "Tool not available"
fi

echo ""
```

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

## Support

For issues, questions, or contributions, please [add your support channels here].
