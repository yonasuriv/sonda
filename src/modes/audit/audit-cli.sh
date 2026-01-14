#!/usr/bin/env bash

# Boot and Security Auditor Script

# Start timer
AUDIT_START_TIME=$(date +%s.%N)

# Use exported paths from sonda.conf (already exported by main script)
# All paths are now defined in sonda.conf
AUDIT_DIR="${AUDIT_DIR:-}"
SCRIPT_DIR="${AUDIT_DIR:-}"
PROJECT_ROOT="${AUDIT_PROJECT_ROOT:-${INSTALL_DIR:-}}"
SRC_DIR="${SRC_DIR:-${INSTALL_DIR:-}/src}"

LIB="${AUDIT_LIB:-${AUDIT_HELPERS:-}}"
SHARED_CORE="${SONDA_SHARED_CORE:-${CORE_DIR:-}}"
MODULES="${AUDIT_MODULES:-}"
CONFIG="${AUDIT_CONFIG:-${AUDIT_SETTINGS:-}}"

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
        system|security)
            bash "$AUDIT_MODULES/security/init.sh"
            exit $?
            ;;
        boot)
            # Boot mode - will be handled after argument parsing
            shift
            ;;
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
            if type banner_logo_small &>/dev/null; then
                banner_logo_small
            fi
            if [[ -f "${PRINT_HELP:-}" ]]; then
                bash "$PRINT_HELP" audit
            else
                echo "Help system not available" >&2
            fi
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Handle boot mode if it was the first argument
# Note: This is a simplified version - full boot audit logic should be in boot/init.sh
if [[ "${1:-}" == "boot" ]] || [[ -z "${1:-}" ]]; then
    if [[ -f "$AUDIT_MODULES/boot/init.sh" ]]; then
        source "$AUDIT_MODULES/boot/init.sh"
    fi
fi

