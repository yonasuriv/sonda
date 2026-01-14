#!/bin/bash

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

# Load core components in order
source "$AUDIT_HELPERS/paths.sh"
source "$AUDIT_HELPERS/config.sh"
source "$AUDIT_HELPERS/commands.sh"
source "$AUDIT_HELPERS/phases.sh"
source "$AUDIT_HELPERS/filter.sh"
source "$AUDIT_HELPERS/functions.sh"
source "$AUDIT_HELPERS/layout.sh"

# Source sudo.sh - check common location first, then local
if [[ -f "${PROMPT_SUDO:-}" ]]; then
    source "$PROMPT_SUDO"
elif [[ -f "$UTILS_DIR/sudo.sh" ]]; then
    source "$UTILS_DIR/sudo.sh"
elif [[ -f "$AUDIT_HELPERS/sudo.sh" ]]; then
    source "$AUDIT_HELPERS/sudo.sh"
fi
source "$AUDIT_HELPERS/summary.sh"

# Initialize logging if requested
init_logging() {
    if [[ "$AUDIT_SAVE_LOGS" == true ]]; then
        mkdir -p "$AUDIT_LOG_DIR"
        
        # Build log filename based on LOG settings (not console settings)
        LOG_BASENAME="boot_audit"
        if [[ "${AUDIT_LOG_TIMESTAMP:-$AUDIT_ADD_TIMESTAMP}" == true ]]; then
            LOG_BASENAME="${LOG_BASENAME}_${AUDIT_TIMESTAMP}"
        fi
        if [[ "${AUDIT_LOG_USER:-$AUDIT_ADD_USER}" == true ]]; then
            LOG_BASENAME="${LOG_BASENAME}_$(whoami)"
        fi
        
        AUDIT_LOG_FILE="$AUDIT_LOG_DIR/${LOG_BASENAME}.log"
        AUDIT_DETAILED_LOG="$AUDIT_LOG_DIR/${LOG_BASENAME}_detailed.log"
        touch "$AUDIT_LOG_FILE" "$AUDIT_DETAILED_LOG"
        echo "=== Boot Session Audit - $(date) ===" > "$AUDIT_LOG_FILE"
        echo "=== Detailed Boot Session Audit - $(date) ===" > "$AUDIT_DETAILED_LOG"
        if [[ "${AUDIT_LOG_USER:-$AUDIT_ADD_USER}" == true ]]; then
            echo "User: $(whoami)" >> "$AUDIT_LOG_FILE"
            echo "User: $(whoami)" >> "$AUDIT_DETAILED_LOG"
        fi
        
        export AUDIT_LOG_FILE AUDIT_DETAILED_LOG
    fi
}

# Set trap to cleanup on exit
trap cleanup_sudo EXIT

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
# Use AUDIT_LIB from sonda.conf (preferred) or AUDIT_LIB_DIR from paths.sh (fallback)
AUDIT_LOADER="${AUDIT_HELPERS}/loader.sh"
# shellcheck disable=SC1091,SC2153  # Dynamic source path
if [[ -f "$AUDIT_LOADER" ]]; then
    source "$AUDIT_LOADER"
else
    echo "Error: Cannot find loader.sh at $AUDIT_LOADER" >&2
    exit 1
fi

# Set boot modules directory for phase loading
BOOT_MODULES_DIR="${AUDIT_MODULES}/boot"
export AUDIT_MODULES="$BOOT_MODULES_DIR"

# Initialize AUDIT_CURRENT_PHASE to avoid unbound variable errors
export AUDIT_CURRENT_PHASE=""

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
