#!/usr/bin/env bash

# Boot Session Auditor Script
# Main entry point - loads modular components and runs phase-driven audits

# Core paths are already set by main sonda script
# INSTALLDIR, HOMEUSER, VERSION_FILE, ASSETS, LOGFILE_DIR, LOGFILE are exported
# MODES_DIR, AUDIT_MODE_DIR, SHARED_CORE_DIR are also exported

# Start timer
AUDIT_START_TIME=$(date +%s.%N)

# Use exported paths from sonda.conf (already exported by main script)
# All paths are now defined in sonda.conf
AUDIT_DIR="$AUDIT_MODE_DIR"
SCRIPT_DIR="$AUDIT_SCRIPT_DIR"
PROJECT_ROOT="$AUDIT_PROJECT_ROOT"
SRC_DIR="$AUDIT_SRC_DIR"

LIB="$AUDIT_LIB"
SHARED_CORE="$SONDA_SHARED_CORE"
MODULES="$AUDIT_MODULES"
CONFIG="$AUDIT_CONFIG"

# Load default configuration if it exists (before parsing arguments)
# This allows default.conf to set defaults that can be overridden by command line
# shellcheck disable=SC1091
if [[ -f "$AUDIT_DIR/default.conf" ]]; then
    # shellcheck source=src/modes/audit/default.conf
    source "$AUDIT_DIR/default.conf" 2>/dev/null || true
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --save-logs|--log)
            export AUDIT_SAVE_LOGS=true
            shift
            ;;
        --log-dir|-d)
            export AUDIT_LOG_DIR="$2"
            shift 2
            ;;
        -v|--verbose)
            export AUDIT_VERBOSE=true
            shift
            ;;
        -s|--silent)
            export AUDIT_VERBOSE=false
            shift
            ;;
        -t|--timestamp)
            export AUDIT_ADD_TIMESTAMP=true
            export AUDIT_LOG_TIMESTAMP=true
            export AUDIT_CONSOLE_TIMESTAMP=true
            shift
            ;;
        -nt|--no-timestamp)
            export AUDIT_ADD_TIMESTAMP=false
            export AUDIT_LOG_TIMESTAMP=false
            export AUDIT_CONSOLE_TIMESTAMP=false
            shift
            ;;
        -u|--user)
            export AUDIT_ADD_USER=true
            export AUDIT_LOG_USER=true
            export AUDIT_CONSOLE_USER=true
            shift
            ;;
        -a|--no-user)
            export AUDIT_ADD_USER=false
            export AUDIT_LOG_USER=false
            export AUDIT_CONSOLE_USER=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --save-logs, --log  Save detailed logs to ./logs directory"
            echo "  --log-dir, -d DIR   Specify custom log directory (default: ./logs)"
            echo "  -v, --verbose       Show detailed information on terminal (default: silent)"
            echo "  -s, --silent        Hide detailed info from terminal, not logs (default)"
            echo "  -t, --timestamp     Add timestamp to log filenames"
            echo "  -nt, --no-timestamp Remove timestamp from log filenames (default)"
            echo "  -u, --user          Add username to log filenames"
            echo "  -a, --no-user       Hide username from log filenames (default)"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Default behavior: -s -nt -a (silent output, no timestamp, no user)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Initialize core system
# Set project root before loading init so paths resolve correctly
export AUDIT_PROJECT_ROOT="$PROJECT_ROOT"

# Ensure default config values are set (command line args override default.conf)
# These are set in config.sh, but we ensure they're exported here
export AUDIT_SAVE_LOGS=${AUDIT_SAVE_LOGS:-false}
export AUDIT_LOG_DIR=${AUDIT_LOG_DIR:-./logs}
export AUDIT_VERBOSE=${AUDIT_VERBOSE:-false}
# Legacy compatibility - map old flags to new settings
export AUDIT_ADD_TIMESTAMP=${AUDIT_ADD_TIMESTAMP:-${AUDIT_LOG_TIMESTAMP:-false}}
export AUDIT_ADD_USER=${AUDIT_ADD_USER:-${AUDIT_LOG_USER:-false}}

# shellcheck disable=SC1091  # Dynamic source path
# Use AUDIT_LIB from sonda.conf (already exported)
AUDIT_INIT="$AUDIT_LIB/init.sh"
if [[ -f "$AUDIT_INIT" ]]; then
    source "$AUDIT_INIT"
else
    echo "Error: Cannot find init.sh at $AUDIT_INIT" >&2
    exit 1
fi

# Initialize logging
init_logging

# Print main header
echo ""
print_header "Boot Session Auditor"
# Note: info() function is loaded via init.sh, but we'll use echo here to be safe
if type info >/dev/null 2>&1; then
    info "Audit started at $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo "Audit started at $(date '+%Y-%m-%d %H:%M:%S')"
fi

# Check and request sudo
check_sudo_requirements
if [[ "$SUDO_NEEDED" == true ]]; then
    request_sudo
fi

# Load and execute all phase modules
# AUDIT_LIB_DIR is set by paths.sh (loaded via init.sh)
# AUDIT_CORE_DIR is an alias for AUDIT_LIB_DIR (backward compatibility)
# shellcheck disable=SC1091,SC2153  # Dynamic source path; AUDIT_LIB_DIR is set by init.sh via paths.sh
source "$AUDIT_LIB_DIR/loader.sh"

# Run all phases
load_all_phases

# Final summary (new format)
generate_summary

# Calculate and display audit duration
AUDIT_END_TIME=$(date +%s.%N)
# Calculate duration (handle both with and without bc)
if command -v bc >/dev/null 2>&1; then
    AUDIT_DURATION=$(echo "$AUDIT_END_TIME - $AUDIT_START_TIME" | bc -l 2>/dev/null || echo "0")
    AUDIT_DURATION_SECONDS=$(printf "%.2f" "$AUDIT_DURATION" 2>/dev/null || echo "0.00")
    
    # Format duration for display
    if (( $(echo "$AUDIT_DURATION < 60" | bc -l 2>/dev/null || echo 1) )); then
        AUDIT_DURATION_FORMATTED="${AUDIT_DURATION_SECONDS}s"
    elif (( $(echo "$AUDIT_DURATION < 3600" | bc -l 2>/dev/null || echo 0) )); then
        AUDIT_DURATION_MINUTES=$(echo "scale=0; $AUDIT_DURATION / 60" | bc -l 2>/dev/null || echo "0")
        AUDIT_DURATION_REMAINING=$(echo "scale=2; $AUDIT_DURATION - ($AUDIT_DURATION_MINUTES * 60)" | bc -l 2>/dev/null || echo "0")
        AUDIT_DURATION_REMAINING_SECONDS=$(printf "%.0f" "$AUDIT_DURATION_REMAINING" 2>/dev/null || echo "0")
        AUDIT_DURATION_FORMATTED="${AUDIT_DURATION_MINUTES}m ${AUDIT_DURATION_REMAINING_SECONDS}s"
    else
        AUDIT_DURATION_HOURS=$(echo "scale=0; $AUDIT_DURATION / 3600" | bc -l 2>/dev/null || echo "0")
        AUDIT_DURATION_REMAINING=$(echo "scale=2; $AUDIT_DURATION - ($AUDIT_DURATION_HOURS * 3600)" | bc -l 2>/dev/null || echo "0")
        AUDIT_DURATION_MINUTES=$(echo "scale=0; $AUDIT_DURATION_REMAINING / 60" | bc -l 2>/dev/null || echo "0")
        AUDIT_DURATION_REMAINING_SECONDS=$(echo "scale=2; $AUDIT_DURATION_REMAINING - ($AUDIT_DURATION_MINUTES * 60)" | bc -l 2>/dev/null || echo "0")
        AUDIT_DURATION_REMAINING_SECONDS=$(printf "%.0f" "$AUDIT_DURATION_REMAINING_SECONDS" 2>/dev/null || echo "0")
        AUDIT_DURATION_FORMATTED="${AUDIT_DURATION_HOURS}h ${AUDIT_DURATION_MINUTES}m ${AUDIT_DURATION_REMAINING_SECONDS}s"
    fi
else
    # Fallback: use integer arithmetic if bc is not available
    AUDIT_START_INT=${AUDIT_START_TIME%.*}
    AUDIT_END_INT=${AUDIT_END_TIME%.*}
    AUDIT_DURATION_INT=$((AUDIT_END_INT - AUDIT_START_INT))
    if [[ $AUDIT_DURATION_INT -lt 60 ]]; then
        AUDIT_DURATION_FORMATTED="${AUDIT_DURATION_INT}s"
        AUDIT_DURATION_SECONDS="${AUDIT_DURATION_INT}"
    elif [[ $AUDIT_DURATION_INT -lt 3600 ]]; then
        AUDIT_DURATION_MINUTES=$((AUDIT_DURATION_INT / 60))
        AUDIT_DURATION_REMAINING=$((AUDIT_DURATION_INT % 60))
        AUDIT_DURATION_FORMATTED="${AUDIT_DURATION_MINUTES}m ${AUDIT_DURATION_REMAINING}s"
        AUDIT_DURATION_SECONDS="${AUDIT_DURATION_INT}"
    else
        AUDIT_DURATION_HOURS=$((AUDIT_DURATION_INT / 3600))
        AUDIT_DURATION_REMAINING=$((AUDIT_DURATION_INT % 3600))
        AUDIT_DURATION_MINUTES=$((AUDIT_DURATION_REMAINING / 60))
        AUDIT_DURATION_REMAINING_SECONDS=$((AUDIT_DURATION_REMAINING % 60))
        AUDIT_DURATION_FORMATTED="${AUDIT_DURATION_HOURS}h ${AUDIT_DURATION_MINUTES}m ${AUDIT_DURATION_REMAINING_SECONDS}s"
        AUDIT_DURATION_SECONDS="${AUDIT_DURATION_INT}"
    fi
fi

# Display duration (colors are loaded via init.sh)
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Audit completed in: ${BOLD}${AUDIT_DURATION_FORMATTED}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
echo ""

# Log duration
if [[ "$AUDIT_SAVE_LOGS" == true ]]; then
    log_output "Audit duration: ${AUDIT_DURATION_FORMATTED} (${AUDIT_DURATION_SECONDS} seconds)"
    log_detailed "=== Audit Duration ==="
    # Try to format start/end times (GNU date format)
    START_TIME_FORMATTED=$(date -d "@${AUDIT_START_TIME%.*}" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "${AUDIT_START_TIME%.*}" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
    END_TIME_FORMATTED=$(date -d "@${AUDIT_END_TIME%.*}" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "${AUDIT_END_TIME%.*}" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
    log_detailed "Start time: ${START_TIME_FORMATTED}"
    log_detailed "End time: ${END_TIME_FORMATTED}"
    log_detailed "Duration: ${AUDIT_DURATION_FORMATTED} (${AUDIT_DURATION_SECONDS} seconds)"
fi

#################################################################################################
#                                                                                               #
# TEMPORAL: NEEDS TO BE ENHANCED BASED ON PHASES, SEVERITY, AND IMPACT (CURRENTLY NOT DONE)     #
#           REMEDIATIONS NEEDS TO BE DEFINED IN EACH OF THE TEST CASES, AS FOR summary.sh       #
#                                                                                               #
#################################################################################################

# Log summary to file
log_output ""
log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_output "  Audit Summary"
log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_output "Boot scope:      current boot (boot id=${AUDIT_BOOT_ID})"
log_output "Boot to GUI:     ${AUDIT_BOOT_TO_GUI}"
if [[ -n "$AUDIT_BOOT_TOTAL_TIME" ]]; then
    log_output "Total time:      ${AUDIT_BOOT_TOTAL_TIME}s"
fi
log_output "Phases run:      ${AUDIT_PHASE_COUNT}"
TOTAL_TESTS=$((AUDIT_SKIPPED + AUDIT_PASSED + AUDIT_FAILED + AUDIT_WARNINGS))
log_output "Tests:           ${TOTAL_TESTS}  (pass ${AUDIT_PASSED}, warn ${AUDIT_WARNINGS}, fail ${AUDIT_FAILED}, skip ${AUDIT_SKIPPED})"

if [[ "$AUDIT_SAVE_LOGS" == true ]]; then
    echo -e "${CYAN}Logs saved to:${NC}"
    echo -e "  Summary: ${AUDIT_LOG_FILE}"
    echo -e "  Detailed: ${AUDIT_DETAILED_LOG}"
    log_output ""
    log_output "Detailed logs saved to: $AUDIT_DETAILED_LOG"
fi

# Anonymize log files in bulk if configured to do so after writing
# This is faster than anonymizing each line individually
if [[ "$AUDIT_SAVE_LOGS" == true ]] && type anonymize_log_files >/dev/null 2>&1; then
    anonymize_log_files
fi

if [[ $AUDIT_FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Boot session audit completed - No critical issues found${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo
    if [[ $AUDIT_WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}Note:${NC} Some warnings were detected. Review the output above."
    fi
    echo
    exit 0
else
    echo -e "\n${RED}════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  ✗ Boot session audit found critical issues${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "  ${BOLD}Recommended actions:${NC}"
    echo -e "    1. Review the failed audits above"
    if [[ "$AUDIT_SAVE_LOGS" == true ]]; then
        echo -e "    2. Check detailed logs: $AUDIT_DETAILED_LOG"
    else
        echo -e "    2. Run with --save-logs to get detailed logs"
    fi
    echo -e "    3. Check specific services: systemctl status <service>"
    if [[ "$SUDO_AVAILABLE" == true ]]; then
        echo -e "    4. Review kernel messages: sudo dmesg -T | tail -50"
    else
        echo -e "    4. Review kernel messages: dmesg | tail -50 (may need sudo)"
    fi
    echo -e "    5. Check GNOME logs: journalctl --user -u org.gnome.Shell -b"
    echo
    exit 1
fi
