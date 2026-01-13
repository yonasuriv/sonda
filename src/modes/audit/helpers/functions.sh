#!/usr/bin/env bash
# Core audit functions (pass, fail, warn, skip, logging)

# Load dependencies (if not already loaded)
if [[ -z "$RED" ]]; then
    source "${BASH_SOURCE[0]%/*}/colors.sh"
fi
if [[ -z "$AUDIT_PASSED" ]]; then
    source "${BASH_SOURCE[0]%/*}/config.sh"
fi
# Load filter functions
if ! type should_show_console >/dev/null 2>&1; then
    source "${BASH_SOURCE[0]%/*}/filter.sh"
fi
# Load anonymization functions
if ! type anonymize_text >/dev/null 2>&1; then
    source "${BASH_SOURCE[0]%/*}/anonimizer.sh"
fi

# Logging functions (always log if enabled, respect LOG_MIN_LEVEL)
# Apply anonymization based on AUDIT_LOG_ANONYMIZE_AFTER_WRITE setting
log_output() {
    if [[ "$AUDIT_SAVE_LOGS" == true && -n "$AUDIT_LOG_FILE" ]]; then
        local text="$1"
        # Fast path: if anonymization is disabled, write directly
        if [[ "$AUDIT_LOG_ANONYMIZE" != "true" ]]; then
            echo "$text" >> "$AUDIT_LOG_FILE"
        # If anonymization is enabled and we should anonymize after write, write raw data
        elif [[ "$AUDIT_LOG_ANONYMIZE_AFTER_WRITE" == true ]]; then
            # Write raw data (will be anonymized later in bulk)
            echo "$text" >> "$AUDIT_LOG_FILE"
        else
            # Anonymize before writing (slower but safer)
            local anonymized_text=$(anonymize_text "$text" "log")
            echo "$anonymized_text" >> "$AUDIT_LOG_FILE"
        fi
    fi
}

log_detailed() {
    if [[ "$AUDIT_SAVE_LOGS" == true && -n "$AUDIT_DETAILED_LOG" ]]; then
        local text="$1"
        # Fast path: if anonymization is disabled, write directly
        if [[ "$AUDIT_LOG_ANONYMIZE" != "true" ]]; then
            echo "$text" >> "$AUDIT_DETAILED_LOG"
        # If anonymization is enabled and we should anonymize after write, write raw data
        elif [[ "$AUDIT_LOG_ANONYMIZE_AFTER_WRITE" == true ]]; then
            # Write raw data (will be anonymized later in bulk)
            echo "$text" >> "$AUDIT_DETAILED_LOG"
        else
            # Anonymize before writing (slower but safer)
            local anonymized_text=$(anonymize_text "$text" "log")
            echo "$anonymized_text" >> "$AUDIT_DETAILED_LOG"
        fi
    fi
}

# Test result functions with filtering
pass() {
    local message="$1"
    # Always log passes (logs should contain everything for analysis)
    log_output "✓ $message"
    # Console output respects CONSOLE_MIN_LEVEL
    if should_show_console "pass" 2>/dev/null; then
        # Fast path: skip anonymization if disabled
        if [[ "${AUDIT_CONSOLE_ANONYMIZE:-false}" == "true" ]]; then
            local anonymized_message=$(anonymize_text "$message" "console")
            echo -e "${GREEN}✓${NC} $anonymized_message"
        else
            echo -e "${GREEN}✓${NC} $message"
        fi
    fi
    ((AUDIT_PASSED++))
    # Update current phase counter if tracking
    if [[ -n "$AUDIT_CURRENT_PHASE" ]]; then
        ((AUDIT_PHASE_PASSED[$AUDIT_CURRENT_PHASE]++))
    fi
}

fail() {
    local message="$1"
    # Always log failures (they're critical)
    log_output "✗ $message"
    # Always show failures on console (they're critical)
    # Fast path: skip anonymization if disabled
    if [[ "${AUDIT_CONSOLE_ANONYMIZE:-false}" == "true" ]]; then
        local anonymized_message=$(anonymize_text "$message" "console")
        echo -e "${RED}✗${NC} $anonymized_message"
    else
        echo -e "${RED}✗${NC} $message"
    fi
    ((AUDIT_FAILED++))
    # Update current phase counter if tracking
    if [[ -n "$AUDIT_CURRENT_PHASE" ]]; then
        ((AUDIT_PHASE_FAILED[$AUDIT_CURRENT_PHASE]++))
    fi
}

warn() {
    local message="$1"
    # Always log warnings
    log_output "⚠ $message"
    # Console output respects CONSOLE_MIN_LEVEL
    if should_show_console "warn" 2>/dev/null; then
        # Fast path: skip anonymization if disabled
        if [[ "${AUDIT_CONSOLE_ANONYMIZE:-false}" == "true" ]]; then
            local anonymized_message=$(anonymize_text "$message" "console")
            echo -e "${YELLOW}⚠${NC} $anonymized_message"
        else
            echo -e "${YELLOW}⚠${NC} $message"
        fi
    fi
    ((AUDIT_WARNINGS++))
    # Update current phase counter if tracking
    if [[ -n "$AUDIT_CURRENT_PHASE" ]]; then
        ((AUDIT_PHASE_WARNINGS[$AUDIT_CURRENT_PHASE]++))
    fi
}

skip() {
    local message="$1"
    # Always log skips
    log_output "⊘ $message"
    # Skips are always shown on console (they indicate missing tools/data)
    # Fast path: skip anonymization if disabled
    if [[ "${AUDIT_CONSOLE_ANONYMIZE:-false}" == "true" ]]; then
        local anonymized_message=$(anonymize_text "$message" "console")
        echo -e "${CYAN}⊘${NC} $anonymized_message"
    else
        echo -e "${CYAN}⊘${NC} $message"
    fi
    ((AUDIT_SKIPPED++))
    # Update current phase counter if tracking
    if [[ -n "$AUDIT_CURRENT_PHASE" ]]; then
        ((AUDIT_PHASE_SKIPPED[$AUDIT_CURRENT_PHASE]++))
    fi
}

info() {
    local message="$1"
    # Always log info messages (logs should contain everything)
    log_output "ℹ $message"
    # Info is shown on console only if verbose mode is enabled
    # (info messages are typically only for verbose output)
    if [[ "$AUDIT_VERBOSE" == true ]]; then
        # Fast path: skip anonymization if disabled
        if [[ "${AUDIT_CONSOLE_ANONYMIZE:-false}" == "true" ]]; then
            local anonymized_message=$(anonymize_text "$message" "console")
            echo -e "${CYAN}ⓘ${NC} $anonymized_message"
        else
            echo -e "${CYAN}ⓘ${NC} $message"
        fi
    fi
}

# Helper function to get console limit for tail/head commands
# Returns the limit number, or empty string if no limit (0)
get_console_limit() {
    local max_findings=${AUDIT_CONSOLE_MAX_FINDINGS:-20}
    if [[ $max_findings -eq 0 ]]; then
        echo ""  # No limit - return empty
    else
        echo "$max_findings"
    fi
}

# Helper function to get log limit for tail/head commands
# Returns the limit number, or empty string if no limit (0)
get_log_limit() {
    local max_findings=${AUDIT_LOG_MAX_FINDINGS:-0}
    if [[ $max_findings -eq 0 ]]; then
        echo ""  # No limit - return empty
    else
        echo "$max_findings"
    fi
}

# Helper function to get details with appropriate limit
# Usage: get_details_with_limit "console" <command> or get_details_with_limit "log" <command>
# Example: HW_DETAILS=$(get_details_with_limit "console" "$SUDO_DMESG_BASE 2>/dev/null | grep -iE 'error'")
get_details_with_limit() {
    local output_type="$1"
    shift
    local command="$*"
    local max_findings
    
    if [[ "$output_type" == "console" ]]; then
        max_findings=${AUDIT_CONSOLE_MAX_FINDINGS:-20}
    elif [[ "$output_type" == "log" ]]; then
        max_findings=${AUDIT_LOG_MAX_FINDINGS:-0}
    else
        # Default to console
        max_findings=${AUDIT_CONSOLE_MAX_FINDINGS:-20}
    fi
    
    # Execute command and limit if needed
    if [[ $max_findings -eq 0 ]]; then
        eval "$command"
    else
        eval "$command" | tail -n "$max_findings"
    fi
}

# Helper function to limit output for console display (when you already have the data)
# Usage: echo "$DETAILS" | limit_for_console
limit_for_console() {
    local max_findings=${AUDIT_CONSOLE_MAX_FINDINGS:-20}
    if [[ $max_findings -eq 0 ]]; then
        cat  # No limit
    else
        tail -n "$max_findings"
    fi
}

# Helper function to limit output for log file (when you already have the data)
# Usage: echo "$DETAILS" | limit_for_log
limit_for_log() {
    local max_findings=${AUDIT_LOG_MAX_FINDINGS:-0}
    if [[ $max_findings -eq 0 ]]; then
        cat  # No limit
    else
        tail -n "$max_findings"
    fi
}

# Export functions for use in modules
export -f log_output log_detailed pass fail warn skip info
export -f get_console_limit get_log_limit get_details_with_limit limit_for_console limit_for_log
