#!/usr/bin/env bash
# Path resolution and directory management

# Get script directory (works when sourced or executed)
get_script_dir() {
    local SOURCE="${BASH_SOURCE[0]}"
    while [[ -h "$SOURCE" ]]; do
        local DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    echo "$(cd -P "$(dirname "$SOURCE")" && pwd)"
}

# Get project root directory
get_project_root() {
    # If INSTALL_DIR is set (from main sonda script), use it
    if [[ -n "${INSTALL_DIR:-}" && -d "$INSTALL_DIR" ]]; then
        echo "$INSTALL_DIR"
        return 0
    fi
    
    # If already set (e.g., from audit.sh), use it
    if [[ -n "${AUDIT_PROJECT_ROOT:-}" && -d "${AUDIT_PROJECT_ROOT:-}" ]]; then
        echo "$AUDIT_PROJECT_ROOT"
        return 0
    fi
    
    # Calculate from src/modes/audit/helpers/ location (go up 3 levels)
    local script_dir="$(get_script_dir)"
    local project_root="$(cd "$script_dir/../../../.." && pwd)"
    
    # Verify it's the project root by checking for cli.sh
    if [[ -f "$project_root/src/modes/audit/cli.sh" ]] || [[ -f "$project_root/src/audit/cli.sh" ]] || [[ -f "$project_root/audit.sh" ]]; then
        echo "$project_root"
        return 0
    fi
    
    # Fallback: try to find by looking for cli.sh
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/src/modes/audit/cli.sh" ]] || [[ -f "$current_dir/src/audit/cli.sh" ]] || [[ -f "$current_dir/audit.sh" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Last resort: use calculated path even if verification failed
    echo "$project_root"
}

# Initialize paths
# Use exported paths from sonda.conf if available (preferred)
# Otherwise calculate them (fallback for standalone execution)

AUDIT_SCRIPT_DIR="$(get_script_dir)"

# Use exported variables from sonda.conf if available
if [[ -n "${AUDIT_LIB:-}" ]]; then
    # All paths already set by sonda.conf, just ensure they're exported
    AUDIT_LIB_DIR="${AUDIT_LIB:-$AUDIT_MODE_LIB_DIR}"
    AUDIT_MODULES_DIR="${AUDIT_MODULES:-$AUDIT_MODE_MODULES_DIR}"
    AUDIT_DOCS_DIR="${AUDIT_DOCS:-$AUDIT_MODE_DOCS_DIR}"
    AUDIT_CONFIG_DIR="${AUDIT_DIR:-$AUDIT_MODE_DIR}"
    AUDIT_PROJECT_ROOT="${AUDIT_PROJECT_ROOT:-$INSTALL_DIR}"
    AUDIT_SRC_DIR="${AUDIT_SRC_DIR:-$INSTALL_DIR}"
else
    # Fallback: calculate paths if sonda.conf wasn't loaded
    if [[ -z "${AUDIT_PROJECT_ROOT:-}" ]]; then
        AUDIT_PROJECT_ROOT="$(get_project_root)"
    fi
    AUDIT_SRC_DIR="$AUDIT_PROJECT_ROOT/src"
    
    # Use AUDIT_MODE_DIR if available, otherwise calculate
    if [[ -n "${AUDIT_MODE_DIR:-}" ]]; then
        AUDIT_LIB_DIR="$AUDIT_MODE_DIR/helpers"
        AUDIT_MODULES_DIR="$AUDIT_MODE_DIR/modules"
        AUDIT_DOCS_DIR="$AUDIT_MODE_DIR/docs"
        AUDIT_CONFIG_DIR="$AUDIT_MODE_DIR"
    else
        # Calculate paths (check new structure first, then old)
        if [[ -d "$AUDIT_SRC_DIR/modes/audit/helpers" ]]; then
            AUDIT_LIB_DIR="$AUDIT_SRC_DIR/modes/audit/helpers"
            AUDIT_MODULES_DIR="$AUDIT_SRC_DIR/modes/audit/modules"
            AUDIT_DOCS_DIR="$AUDIT_SRC_DIR/modes/audit/docs"
            AUDIT_CONFIG_DIR="$AUDIT_SRC_DIR/modes/audit"
        elif [[ -d "$AUDIT_SRC_DIR/modes/audit/lib" ]]; then
            AUDIT_LIB_DIR="$AUDIT_SRC_DIR/modes/audit/lib"
            AUDIT_MODULES_DIR="$AUDIT_SRC_DIR/modes/audit/modules"
            AUDIT_DOCS_DIR="$AUDIT_SRC_DIR/modes/audit/docs"
            AUDIT_CONFIG_DIR="$AUDIT_SRC_DIR/modes/audit"
        elif [[ -d "$AUDIT_SRC_DIR/audit/lib" ]]; then
            AUDIT_LIB_DIR="$AUDIT_SRC_DIR/audit/lib"
            AUDIT_MODULES_DIR="$AUDIT_SRC_DIR/audit/modules"
            AUDIT_DOCS_DIR="$AUDIT_SRC_DIR/audit/docs"
            AUDIT_CONFIG_DIR="$AUDIT_SRC_DIR/audit"
        else
            # Fallback
            AUDIT_LIB_DIR="$AUDIT_SRC_DIR/modes/audit/helpers"
            AUDIT_MODULES_DIR="$AUDIT_SRC_DIR/modes/audit/modules"
            AUDIT_DOCS_DIR="$AUDIT_SRC_DIR/modes/audit/docs"
            AUDIT_CONFIG_DIR="$AUDIT_SRC_DIR/modes/audit"
        fi
    fi
fi

# Legacy alias for backward compatibility (lib was renamed from core)
AUDIT_CORE_DIR="$AUDIT_LIB_DIR"

# Export for use in other modules (only if not already exported)
if [[ -z "${AUDIT_LIB_DIR:-}" ]] || [[ "${AUDIT_LIB_DIR:-}" != "${AUDIT_LIB:-}" ]]; then
    export AUDIT_SCRIPT_DIR AUDIT_PROJECT_ROOT AUDIT_SRC_DIR
    export AUDIT_LIB_DIR AUDIT_CORE_DIR AUDIT_MODULES_DIR AUDIT_DOCS_DIR AUDIT_CONFIG_DIR
fi
