#!/usr/bin/env bash
# Layout and formatting functions

# Load dependencies (if not already loaded)
if [[ -z "$RED" ]]; then
    source "${BASH_SOURCE[0]%/*}/colors.sh"
fi
if ! type pass >/dev/null 2>&1; then
    source "${BASH_SOURCE[0]%/*}/functions.sh"
fi
if ! type get_phase_display_name >/dev/null 2>&1; then
    source "${BASH_SOURCE[0]%/*}/phases.sh"
fi
# Load anonymization functions
if ! type anonymize_text >/dev/null 2>&1; then
    source "${BASH_SOURCE[0]%/*}/anonimizer.sh"
fi

# Print section header
print_header() {
    local header="${1:-}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $header${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    log_output ""
    log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_output "  $header"
    log_output "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_output ""
}

# Print phase header (with phase number)
# If phase_num and phase_name are not provided, auto-detect from calling script's filename
print_phase_header() {
    local phase_num="${1:-}"
    local phase_name="${2:-}"
    
    # Auto-detect phase ID and name from calling script's filename if not provided
    if [[ -z "$phase_num" ]] || [[ -z "$phase_name" ]]; then
        # Get the calling script's filename
        local calling_script="${BASH_SOURCE[1]}"
        local script_basename=$(basename "$calling_script")
        
        # Extract phase ID from filename (first two digits)
        if [[ "$script_basename" =~ ^([0-9]{2})_ ]]; then
            phase_num="${BASH_REMATCH[1]}"
        fi
        
        # Get phase name from phases.sh registry
        if [[ -n "$phase_num" ]] && type get_phase_display_name >/dev/null 2>&1; then
            phase_name=$(get_phase_display_name "$phase_num")
        fi
        
        # Fallback if still not found
        if [[ -z "$phase_num" ]]; then
            phase_num="??"
        fi
        if [[ -z "$phase_name" ]]; then
            phase_name="Unknown Phase"
        fi
    fi
    
    # Set current phase for tracking
    export AUDIT_CURRENT_PHASE="$phase_num"
    
    # Initialize phase counters to 0 (these are tracked per-phase by pass/fail/warn/skip functions)
    AUDIT_PHASE_FAILED[$phase_num]=0
    AUDIT_PHASE_WARNINGS[$phase_num]=0
    AUDIT_PHASE_PASSED[$phase_num]=0
    AUDIT_PHASE_SKIPPED[$phase_num]=0
    
    print_header "Phase $phase_num: $phase_name"
    ((AUDIT_PHASE_COUNT++))
}

# Helper function to indent output lines
indent_output() {
    sed 's/^/  /'
}

# Helper function to conditionally show detailed output
# Respects AUDIT_VERBOSE and CONSOLE_MIN_LEVEL settings
show_details() {
    if [[ "$AUDIT_VERBOSE" == true ]]; then
        cat
    else
        cat >/dev/null
    fi
}

# Helper function to show details with indentation
# Respects AUDIT_VERBOSE and CONSOLE_MIN_LEVEL settings
# Applies anonymization if enabled for console output
show_indented_details() {
    if [[ "$AUDIT_VERBOSE" == true ]]; then
        # Fast path: if anonymization is disabled, just indent
        if [[ "${AUDIT_CONSOLE_ANONYMIZE:-false}" != "true" ]]; then
            indent_output
        else
            # Read input, anonymize if enabled, then indent
            while IFS= read -r line || [[ -n "$line" ]]; do
                local anonymized_line=$(anonymize_text "$line" "console")
                echo "$anonymized_line" | indent_output
            done
        fi
    else
        cat >/dev/null
    fi
}

# Export functions
export -f print_header print_phase_header indent_output show_details show_indented_details
