#!/usr/bin/env bash
# Initialize audit system - loads all core components in correct order

# Set error handling (don't exit on error - we want to see all audit results)
set +e

# Load core components in order
source "${BASH_SOURCE[0]%/*}/paths.sh"
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/colors.sh"
source "${BASH_SOURCE[0]%/*}/commands.sh"
source "${BASH_SOURCE[0]%/*}/phases.sh"
source "${BASH_SOURCE[0]%/*}/filter.sh"
source "${BASH_SOURCE[0]%/*}/functions.sh"
source "${BASH_SOURCE[0]%/*}/layout.sh"
# Source sudo.sh - check common location first, then local
if [[ -f "${BASH_SOURCE[0]%/*}/sudo.sh" ]]; then
    source "${BASH_SOURCE[0]%/*}/sudo.sh"
elif [[ -n "${SHARED_LIB_DIR:-}" ]] && [[ -f "$SHARED_LIB_DIR/common/sudo.sh" ]]; then
    source "$SHARED_LIB_DIR/common/sudo.sh"
elif [[ -n "${INSTALLDIR:-}" ]] && [[ -f "$INSTALLDIR/lib/common/sudo.sh" ]]; then
    source "$INSTALLDIR/lib/common/sudo.sh"
fi
source "${BASH_SOURCE[0]%/*}/summary.sh"

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

# Export init function
export -f init_logging
