#!/usr/bin/env bash
# Filtering functions for log and console output based on severity levels

# Check if a severity level should be shown
# min_level: "pass" = show all, "warn" = show warn/fail, "fail" = show only fail
should_show_level() {
    local level="$1"  # pass, warn, fail, skip
    local min_level="$2"  # pass, warn, fail
    
    # Skip is always shown (can't be filtered)
    if [[ "$level" == "skip" ]]; then
        return 0
    fi
    
    case "$min_level" in
        "pass")
            # Show everything including pass
            return 0
            ;;
        "warn")
            # Show warn and fail, hide pass
            case "$level" in
                "warn"|"fail") return 0 ;;
                "pass") return 1 ;;
                *) return 0 ;;  # Unknown levels, show them
            esac
            ;;
        "fail")
            # Show only fail
            case "$level" in
                "fail") return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *)
            # Unknown min_level, show everything
            return 0
            ;;
    esac
}

# Check if we should show this output (for console)
should_show_console() {
    local level="$1"
    should_show_level "$level" "${AUDIT_CONSOLE_MIN_LEVEL:-warn}"
}

# Check if we should log this output (for log files)
should_show_log() {
    local level="$1"
    should_show_level "$level" "${AUDIT_LOG_MIN_LEVEL:-pass}"
}

# Export functions
export -f should_show_level should_show_console should_show_log
