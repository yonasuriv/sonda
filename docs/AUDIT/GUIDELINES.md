# Boot Session Auditor - Contribution Guidelines

This document provides a comprehensive guide for understanding and contributing to the Boot Session Auditor project. It's designed for contributors with no prior knowledge of the project.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Core Concepts](#core-concepts)
5. [How It Works](#how-it-works)
6. [Adding New Test Cases](#adding-new-test-cases)
7. [Creating New Phases](#creating-new-phases)
8. [Configuration System](#configuration-system)
9. [Output and Logging](#output-and-logging)
10. [Testing Your Changes](#testing-your-changes)
11. [Code Style and Best Practices](#code-style-and-best-practices)
12. [Common Tasks](#common-tasks)

## Project Overview

The Boot Session Auditor is a phase-driven Linux boot auditing tool that analyzes system logs from firmware initialization through to the graphical desktop session. It identifies errors, warnings, and performance issues across the entire boot chain.

### Key Features

- **Phase-Driven Architecture**: Follows the actual boot chain chronologically
- **13 Audit Phases**: From firmware to GUI, covering the complete boot process
- **Configurable Output**: Separate settings for console and log output
- **Performance Optimized**: Fast execution with optional anonymization
- **Modular Design**: Easy to extend with new phases and test cases

## Architecture

### High-Level Flow

```
audit.sh
  ├── Load default.conf (configuration)
  ├── Parse command-line arguments
  ├── Initialize core system (init.sh)
  │   ├── Load paths.sh
  │   ├── Load config.sh
  │   ├── Load colors.sh
  │   ├── Load commands.sh
  │   ├── Load functions.sh (pass/fail/warn/skip)
  │   ├── Load layout.sh (formatting)
  │   ├── Load filter.sh
  │   ├── Load phases.sh (phase registry)
  │   ├── Load loader.sh
  │   ├── Load summary.sh
  │   ├── Load sudo.sh
  │   └── Load anonimizer.sh
  ├── Request sudo (if needed)
  ├── Load all phase modules (loader.sh)
  │   ├── Phase 00: Context and Baseline
  │   ├── Phase 01: Firmware and Bootloader
  │   ├── Phase 02: Kernel and Hardware Bring-up
  │   ├── ... (all phases)
  │   └── Phase 12: Top Findings and Risk Summary
  ├── Generate summary (summary.sh)
  └── Anonymize logs (if enabled)
```

## Project Structure

```
boot-session-auditer/
├── audit.sh                          # Main entry point
├── README.md                          # User-facing documentation
├── GUIDELINES.md                      # This file - contribution guide
├── CHANGELOG.md                       # Version history
├── src/
│   └── audit/
│       ├── config/
│       │   └── default.conf           # Default configuration file
│       ├── core/                      # Core functionality (shared)
│       │   ├── init.sh                # Initialization and setup
│       │   ├── config.sh              # Configuration management
│       │   ├── paths.sh               # Path resolution
│       │   ├── colors.sh              # ANSI color codes
│       │   ├── commands.sh            # Common command variables
│       │   ├── functions.sh           # Core functions (pass/fail/warn/skip)
│       │   ├── layout.sh              # Output formatting
│       │   ├── filter.sh              # Output filtering
│       │   ├── phases.sh              # Phase registry
│       │   ├── loader.sh              # Module loader
│       │   ├── summary.sh             # Summary generation
│       │   ├── sudo.sh                # Sudo management
│       │   └── anonimizer.sh          # Anonymization functions
│       ├── modules/                   # Audit phase modules
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
│       └── docs/                      # Phase documentation
│           ├── README.md              # Phase overview
│           ├── 00.md                  # Phase 00 documentation
│           ├── 01.md                  # Phase 01 documentation
│           └── ... (one per phase)
└── logs/                              # Log output directory (created at runtime)
```

## Core Concepts

### Phases

A **phase** is a module that performs a set of related checks during a specific part of the boot process. Phases are numbered sequentially (00-12) and follow the boot chain chronologically:

- **Phase 00**: Context and baseline (system info, boot ID, timezone)
- **Phase 01**: Firmware and bootloader
- **Phase 02**: Kernel and hardware bring-up
- **Phase 03**: Initramfs and root filesystem handoff
- **Phase 04**: Systemd userspace (boot timing)
- **Phase 05**: Storage and filesystem integrity
- **Phase 06**: Network stack and connectivity
- **Phase 07**: Security controls and policy enforcement
- **Phase 08**: Display stack and graphical session
- **Phase 09**: User session and desktop services
- **Phase 10**: Resource pressure and system stability
- **Phase 11**: Current system posture snapshot
- **Phase 12**: Top findings and risk summary

### Test Cases

A **test case** is a single check within a phase. Each test case:
- Performs a specific check (e.g., "check for kernel errors")
- Reports a result using `pass()`, `fail()`, `warn()`, or `skip()`
- Optionally logs detailed information

### Result Types

- **`pass()`**: Test passed - everything is OK
- **`fail()`**: Test failed - critical issue found
- **`warn()`**: Warning - non-critical issue found
- **`skip()`**: Test skipped - tool/data unavailable

### Core Functions

All phase modules have access to these core functions (from `functions.sh`):

- **`pass "message"`** - Report a passing test
- **`fail "message"`** - Report a failing test (critical)
- **`warn "message"`** - Report a warning (non-critical)
- **`skip "message"`** - Report a skipped test
- **`info "message"`** - Informational message (verbose only)
- **`log_output "text"`** - Write to summary log
- **`log_detailed "text"`** - Write to detailed log
- **`show_indented_details`** - Show details with indentation (respects verbose mode)
- **`limit_for_console`** - Limit output for console display
- **`limit_for_log`** - Limit output for log files

## How It Works

### 1. Initialization (`init.sh`)

When `audit.sh` runs, it:
1. Loads `default.conf` for configuration
2. Parses command-line arguments (overrides config)
3. Sources `init.sh` which loads all core modules in order
4. Sets up logging directories
5. Initializes test counters

### 2. Phase Loading (`loader.sh`)

The loader:
1. Reads the phase registry from `phases.sh`
2. Dynamically loads each phase module in order
3. Each phase module is a bash script that gets sourced
4. Phases can access all core functions and variables

### 3. Phase Execution

Each phase module:
1. Calls `print_phase_header` (auto-detects phase from filename)
2. Performs test cases using core functions
3. Uses `log_output()` and `log_detailed()` for logging
4. Uses `limit_for_console()` and `limit_for_log()` for output limiting

### 4. Summary Generation (`summary.sh`)

After all phases run:
1. Collects statistics from all phases
2. Sorts failures by count
3. Generates formatted summary report
4. Displays highest impact findings

## Adding New Test Cases

### Step 1: Choose the Right Phase

Determine which phase your test case belongs to based on when it occurs in the boot process:

- **System info** → Phase 00
- **Hardware/kernel** → Phase 02
- **Storage** → Phase 05
- **Security** → Phase 07
- **Current state** → Phase 11

### Step 2: Write the Test Case

Open the appropriate phase module file and add your test case:

```bash
# Test case N: Description
if command -v tool_name >/dev/null 2>&1; then
    # Perform check
    RESULT=$(command_to_check 2>/dev/null)
    if [[ condition ]]; then
        pass "Success message"
    else
        fail "Failure message"
    fi
else
    skip "Tool not available"
fi
```

### Step 3: Use Core Functions

Always use the core functions for output:

```bash
# Good: Uses core functions
if [[ $ERRORS -eq 0 ]]; then
    pass "No errors found"
else
    fail "Found $ERRORS error(s)"
    # Show details with proper limiting
    ERROR_DETAILS=$(get_errors)
    ERROR_CONSOLE=$(echo "$ERROR_DETAILS" | limit_for_console)
    ERROR_LOG=$(echo "$ERROR_DETAILS" | limit_for_log)
    echo -e "\n${RED}Errors:${NC}" | show_indented_details
    echo "$ERROR_CONSOLE" | show_indented_details
    log_detailed "=== Errors ==="
    log_detailed "$ERROR_LOG"
fi
```

### Step 4: Handle Sudo Requirements

If your check needs sudo:

```bash
if [[ "$SUDO_AVAILABLE" == true ]]; then
    RESULT=$(sudo command 2>/dev/null)
    # ... check result
else
    RESULT=$(command 2>/dev/null)  # Try without sudo
    if [[ -z "$RESULT" ]]; then
        skip "Check requires sudo"
    else
        # ... check result (limited access)
    fi
fi
```

### Step 5: Update Documentation

Update the phase documentation file in `src/audit/docs/XX.md`:

```markdown
**Test Cases:**
1. Existing test case
2. Another test case
3. Your new test case description
```

## Creating New Phases

### Step 1: Create the Phase Module

Create a new file in `src/audit/modules/` following the naming pattern:

```
XX_description.sh
```

Where `XX` is a two-digit number (00-99) indicating the phase order.

### Step 2: Write the Phase Template

```bash
#!/usr/bin/env bash
# Phase XX: Description
# Purpose: What this phase checks

print_phase_header

# Test case 1: First check
if command -v tool >/dev/null 2>&1; then
    # Check logic
    if [[ condition ]]; then
        pass "Success message"
    else
        fail "Failure message"
    fi
else
    skip "Tool not available"
fi

# Test case 2: Second check
# ... more test cases ...

echo ""
```

### Step 3: Register the Phase

Add your phase to `src/audit/core/phases.sh`:

```bash
declare -A AUDIT_PHASES=(
    # ... existing phases ...
    ["XX"]="Description"
)
```

### Step 4: Create Documentation

Create `src/audit/docs/XX.md`:

```markdown
### Phase XX. Description

Purpose: what this phase checks.

* Key check 1
* Key check 2
* Key check 3

**Test Cases:**
1. Test case 1 description
2. Test case 2 description
3. Test case 3 description
```

### Step 5: Update Main README

Update `README.md` to include your new phase in the "Audit Phases" section.

## Configuration System

### Configuration File (`default.conf`)

The configuration file defines default behavior. Settings can be overridden by command-line arguments.

**Key Settings:**

```bash
# Output Control
AUDIT_VERBOSE=false                    # Console verbosity
AUDIT_CONSOLE_MIN_LEVEL="warn"         # Minimum severity for console
AUDIT_CONSOLE_MAX_FINDINGS=5           # Max findings per category (console)
AUDIT_LOG_MIN_LEVEL="pass"             # Minimum severity for logs
AUDIT_LOG_MAX_FINDINGS=0               # Max findings per category (logs)

# Logging
AUDIT_LOG_DIR="./logs"                 # Log directory
AUDIT_LOG_TIMESTAMP=true               # Add timestamp to log filenames
AUDIT_LOG_USER=false                   # Add username to log filenames

# Anonymization
AUDIT_CONSOLE_ANONYMIZE=false          # Anonymize console output
AUDIT_LOG_ANONYMIZE=true               # Anonymize log files
AUDIT_LOG_ANONYMIZE_AFTER_WRITE=true   # Anonymize after writing (faster)
```

### Command-Line Arguments

Command-line arguments override `default.conf`:

```bash
./audit.sh -v                    # Verbose mode
./audit.sh --save-logs           # Save logs
./audit.sh --log-dir /path/to/logs  # Custom log directory
```

### Accessing Configuration

In phase modules, configuration variables are available as environment variables:

```bash
if [[ "$AUDIT_VERBOSE" == true ]]; then
    # Show detailed output
fi

if [[ "$AUDIT_CONSOLE_MAX_FINDINGS" -gt 0 ]]; then
    # Limit output
fi
```

## Output and Logging

### Console Output

Console output respects:
- `AUDIT_VERBOSE`: Show detailed information
- `AUDIT_CONSOLE_MIN_LEVEL`: Minimum severity to show
- `AUDIT_CONSOLE_MAX_FINDINGS`: Maximum findings per category
- `AUDIT_CONSOLE_ANONYMIZE`: Anonymize output

### Log Files

When `--save-logs` is used, two files are created:
- **Summary log**: All test results
- **Detailed log**: Full details, command outputs, raw data

Logs respect:
- `AUDIT_LOG_MIN_LEVEL`: Minimum severity to log
- `AUDIT_LOG_MAX_FINDINGS`: Maximum findings per category
- `AUDIT_LOG_ANONYMIZE`: Anonymize logs

### Output Limiting

Use helper functions to limit output:

```bash
# Get limited output for console
CONSOLE_OUTPUT=$(command | limit_for_console)

# Get limited output for logs
LOG_OUTPUT=$(command | limit_for_log)

# Or use the combined function
OUTPUT=$(get_details_with_limit "console" "command")
```

## Testing Your Changes

### 1. Test Locally

Run the audit script to test your changes:

```bash
# Basic test
./audit.sh

# Verbose mode
./audit.sh -v

# With logs
./audit.sh --save-logs -v
```

### 2. Test Specific Phase

You can temporarily skip other phases by modifying `AUDIT_CONSOLE_SKIP_PHASES` in `default.conf`:

```bash
AUDIT_CONSOLE_SKIP_PHASES="01 02 03 04 05 06 07 08 09 10 11 12"
```

### 3. Check Output

Verify:
- Test cases are executed
- Results are reported correctly (pass/fail/warn/skip)
- Output is properly formatted
- Logs contain expected information
- No syntax errors

### 4. Test Edge Cases

Test with:
- Missing tools (should skip gracefully)
- No sudo access (should handle gracefully)
- Empty results (should not crash)
- Large outputs (should be limited correctly)

## Code Style and Best Practices

### 1. Use Core Functions

Always use core functions instead of `echo`:

```bash
# Good
pass "Check passed"
fail "Check failed"

# Bad
echo "✓ Check passed"
echo "✗ Check failed"
```

### 2. Handle Missing Tools

Always check if tools are available:

```bash
# Good
if command -v tool >/dev/null 2>&1; then
    # Use tool
else
    skip "Tool not available"
fi
```

### 3. Limit Output

Always limit output for console and logs:

```bash
# Good
DETAILS_CONSOLE=$(echo "$FULL_DETAILS" | limit_for_console)
DETAILS_LOG=$(echo "$FULL_DETAILS" | limit_for_log)

# Bad
echo "$FULL_DETAILS"  # Could be thousands of lines
```

### 4. Use Descriptive Variable Names

```bash
# Good
KERNEL_ERRORS=$(dmesg | grep -i error | wc -l)

# Bad
KE=$(dmesg | grep -i error | wc -l)
```

### 5. Log Detailed Information

Always log detailed information for debugging:

```bash
log_detailed "=== Section Title ==="
log_detailed "$DETAILED_OUTPUT"
```

### 6. Respect Verbose Mode

Use `show_indented_details` for verbose output:

```bash
if [[ "$AUDIT_VERBOSE" == true ]]; then
    echo -e "\n${CYAN}Details:${NC}" | show_indented_details
    echo "$DETAILS" | show_indented_details
fi
```

### 7. Handle Errors Gracefully

Always handle errors and edge cases:

```bash
# Good
RESULT=$(command 2>/dev/null || echo "")
if [[ -n "$RESULT" ]]; then
    # Process result
else
    skip "Unable to get result"
fi
```

### 8. Use Consistent Formatting

Follow the existing code style:
- 4 spaces for indentation
- Use `[[ ]]` for conditionals
- Quote variables: `"$VAR"`
- Use `> /dev/null 2>&1` for silent commands

## Common Tasks

### Adding a New Check to an Existing Phase

1. Open the phase module file
2. Add your test case at the end (before `echo ""`)
3. Use core functions (`pass`, `fail`, `warn`, `skip`)
4. Update the phase documentation
5. Test your changes

### Modifying Output Format

1. Check `layout.sh` for formatting functions
2. Modify the function if needed
3. Test with different verbosity levels

### Adding Configuration Options

1. Add default to `src/audit/config/default.conf`
2. Add fallback to `src/audit/core/config.sh`
3. Export the variable
4. Use in phase modules or core functions

### Debugging Issues

1. Run with `-v` for verbose output
2. Check logs in `./logs/` directory
3. Add `info()` calls for debugging
4. Check `summary.sh` for phase statistics

### Understanding Phase Flow

1. Read `src/audit/core/loader.sh` to see how phases are loaded
2. Read `src/audit/core/phases.sh` to see phase registry
3. Read a simple phase module (e.g., `00_context_and_baseline.sh`) as an example

## Getting Help

### Documentation Files

- `README.md` - User-facing documentation
- `GUIDELINES.md` - This file (contribution guide)
- `src/audit/docs/` - Phase-specific documentation
- `src/audit/README.md` - Technical documentation

### Code Examples

Look at existing phase modules for examples:
- Simple phase: `00_context_and_baseline.sh`
- Complex phase: `04_systemd_boot_and_critical_path.sh`
- Security phase: `07_security_controls_and_policy_enforcement.sh`

### Core Functions Reference

See `src/audit/core/functions.sh` for all available functions and their usage.

## Contributing Checklist

Before submitting your contribution:

- [ ] Code follows existing style and conventions
- [ ] All test cases use core functions (`pass`, `fail`, `warn`, `skip`)
- [ ] Output is properly limited for console and logs
- [ ] Missing tools are handled gracefully (skip)
- [ ] Sudo requirements are checked
- [ ] Documentation is updated
- [ ] Changes are tested locally
- [ ] No syntax errors (run `bash -n script.sh`)
- [ ] Logs are checked for proper formatting

## Next Steps

1. Read through an existing phase module to understand the structure
2. Try adding a simple test case to an existing phase
3. Test your changes thoroughly
4. Update documentation
5. Submit your contribution

Happy contributing! 🚀
