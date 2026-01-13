# Boot Session Auditor - Modular Architecture

## Overview

The boot session auditor has been refactored into a modular, phase-driven architecture that follows the actual boot chain sequence. All components are organized under `src/audit/` for easy expansion and maintenance.

## Directory Structure

```
src/audit/
├── core/              # Core shared components
│   ├── paths.sh       # Path resolution and directory management
│   ├── config.sh      # Configuration and default values
│   ├── colors.sh      # ANSI color definitions
│   ├── commands.sh    # Common command variable definitions
│   ├── functions.sh   # Core audit functions (pass, fail, warn, skip, logging)
│   ├── layout.sh      # Layout and formatting functions
│   ├── sudo.sh        # Sudo handling and privilege management
│   ├── loader.sh      # Module loader for phase modules
│   └── init.sh        # Initialization - loads all core components
├── modules/           # Phase modules (executed in order)
│   ├── 00_context_and_baseline.sh
│   ├── 01_firmware_and_bootloader.sh
│   ├── 02_kernel_and_hardware_bringup.sh
│   ├── 03_initramfs_and_rootfs.sh
│   ├── 04_systemd_boot_and_critical_path.sh
│   ├── 05_storage_and_filesystem_integrity.sh
│   ├── 06_network_stack_and_connectivity.sh
│   ├── 07_security_controls_and_policy_enforcement.sh
│   ├── 08_display_stack_and_graphical_session.sh
│   ├── 09_user_session_and_desktop_services.sh
│   ├── 10_resource_pressure_and_system_stability.sh
│   ├── 11_current_system_posture.sh
│   └── 12_top_findings_and_risk_summary.sh
└── docs/              # Phase documentation
    ├── README.md      # Architecture and phase ordering guide
    └── *.md           # Individual phase specifications
```

## Phase-Driven Architecture

The audit follows the actual boot chain sequence:

1. **Phase 00**: Audit context and baselines (host identity, time reference, log scope)
2. **Phase 01**: Firmware and bootloader (UEFI/BIOS, Secure Boot, bootloader timing)
3. **Phase 02**: Kernel early boot and hardware bring-up (hardware errors, kernel errors, module loads)
4. **Phase 03**: initramfs and root filesystem handoff (mount errors, fsck, swap)
5. **Phase 04**: systemd userspace - critical path to graphical.target (boot timing, failed services)
6. **Phase 05**: Storage and filesystem health (I/O errors, filesystem errors, SMART)
7. **Phase 06**: Network stack and connectivity (NetworkManager, DNS, DHCP, Wi-Fi)
8. **Phase 07**: Security controls and policy enforcement (SELinux, AppArmor, UFW, lockdown)
9. **Phase 08**: Display stack and graphical session start (display manager, compositor, GPU/DRM)
10. **Phase 09**: User session and desktop services (user services, GNOME Shell, portals)
11. **Phase 10**: Resource pressure and system stability (OOM, thermal, disk pressure)
12. **Phase 11**: Current system posture snapshot (resource usage, coredumps, system state)
13. **Phase 12**: Top findings and risk summary (aggregated summary)

## Core Components

### paths.sh
- Resolves project root and all directory paths
- Exports `AUDIT_PROJECT_ROOT`, `AUDIT_CORE_DIR`, `AUDIT_MODULES_DIR`, etc.

### config.sh
- Default configuration values (logging, verbosity, timestamps)
- Test counters (`AUDIT_PASSED`, `AUDIT_FAILED`, `AUDIT_WARNINGS`, `AUDIT_SKIPPED`)
- Phase counter (`AUDIT_PHASE_COUNT`)

### colors.sh
- ANSI color codes for terminal output
- Exports `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `NC`

### commands.sh
- Common command variables (e.g., `JOURNALCTL_BASE`, `DMESG_BASE`)
- Note: Error redirections (`2>/dev/null`) are added at call sites, not in variables

### functions.sh
- `pass()`, `fail()`, `warn()`, `skip()`, `info()` - Test result functions
- `log_output()`, `log_detailed()` - Logging functions
- All functions update counters and handle logging automatically

### layout.sh
- `print_header()`, `print_phase_header()` - Section headers
- `indent_output()`, `show_details()`, `show_indented_details()` - Output formatting

### sudo.sh
- `check_sudo_requirements()` - Detects if sudo is needed
- `request_sudo()` - Prompts for sudo and keeps session alive
- `cleanup_sudo()` - Cleans up sudo keepalive process

### loader.sh
- `load_phase_module()` - Loads a specific phase module
- `load_all_phases()` - Loads all phases in order

### init.sh
- Initializes all core components in correct order
- Sets error handling (`set +e`)
- Sets up cleanup trap

## Creating a New Phase Module

1. Create a new file in `modules/` following the naming pattern: `NN_description.sh`
2. Start with the phase header:
   ```bash
   #!/usr/bin/env bash
   # Phase NN: Description
   # Purpose: What this phase checks
   
   print_phase_header "NN" "Phase Name"
   ```

3. Add test cases using `pass()`, `fail()`, `warn()`, `skip()`, `info()`
4. Use `show_indented_details()` for verbose output
5. Use `log_detailed()` for detailed logging
6. End with `echo ""` for spacing

7. Update `loader.sh` to include the new phase number in `load_all_phases()`

## Usage

The main entry point is `audit.sh` at the project root. It:
1. Parses command-line arguments
2. Initializes the core system
3. Loads and executes all phase modules
4. Displays final summary

All command-line options remain the same:
- `--save-logs`, `--log` - Save logs
- `-v`, `--verbose` - Verbose output
- `-s`, `--silent` - Silent output (default)
- `-t`, `--timestamp` - Add timestamp to logs
- `-u`, `--user` - Add username to logs

## Benefits of Modular Architecture

1. **Maintainability**: Each phase is isolated and can be modified independently
2. **Reusability**: Core components are shared across all phases
3. **Testability**: Individual phases can be tested in isolation
4. **Extensibility**: New phases can be added without modifying existing code
5. **Clarity**: Phase-driven approach matches the actual boot sequence
6. **Documentation**: Each phase has corresponding documentation in `docs/`

## Migration Notes

- Boot analysis functionality from `lib/boot-analyzer.sh` has been fully migrated into Phase 04 (`04_systemd_boot_and_critical_path.sh`)
- All paths are resolved dynamically, so the script works from any location
- Core components check if dependencies are already loaded to avoid re-sourcing
- All modules are source-safe and won't exit the parent script
- Default configuration can be set in `src/audit/default.conf` and will be overridden by command-line arguments
