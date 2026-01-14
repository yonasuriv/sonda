#!/bin/bash

# Sonda Master Configuration File
# This file defines all paths and configuration variables used across all modes
# Call load_sonda_config() function to load and export all variables

SONDA_CFG_NAME='echo "$(basename -- "$0")'

load_sonda_config() {
    # This function loads all configuration variables and automatically exports them
    # All variables defined here will be exported when the function is called
  
    # ============================================================================
    # BASE PATHS (set by main script before calling this function)
    # ============================================================================
    # These should be set by the main sonda script:
    # INSTALL_DIR - Installation directory
    # MODES_DIR - Modes directory ($INSTALL_DIR/modes)
    # SCAN_DIR - Check mode directory ($MODES_DIR/check)
    # AUDIT_MODE_DIR - Audit mode directory ($MODES_DIR/audit)
    # SHARED_LIB_DIR - Shared library directory ($INSTALL_DIR/lib)
    # SHARED_CORE_DIR - Shared core directory ($SHARED_LIB_DIR/core)

    SONDA_DIR="${INSTALL_DIR:-}"

    # ROOT LEVEL DIRECTORIES
    ASSETS_DIR="$SONDA_DIR/assets"
    DOCS_DIR="$SONDA_DIR/docs"
    SRC_DIR="$SONDA_DIR/src"
    
    # BINARY DIRECTORY
    BIN_DIR="$SONDA_DIR/bin"

    # SHARED DIRECTORIES
    # When running from source, lib is in src/lib, when installed it's in lib
    if [[ -d "$SONDA_DIR/src/lib" ]]; then
        # Running from source
        LIB_DIR="$SONDA_DIR/src/lib"
    else
        # Installed
        LIB_DIR="$SONDA_DIR/lib"
    fi
    
    CORE_DIR="$LIB_DIR/core"
    UTILS_DIR="$LIB_DIR/utils"
    COMMON_DIR="$LIB_DIR/common"
    
    # ============================================================================
    # CORE FILES
    # ============================================================================

    CFG_FILE="$CORE_DIR/config.sh"
    STYLE_FILE="$CORE_DIR/style.sh"
    VERSION_FILE="$SONDA_DIR/VERSION"
    #BANNER_FILE="$UTILS_DIR/banner.sh" > moved to style.sh
    #LOGGER_FILE="$UTILS_DIR/logger.sh" > not created yet

    # ============================================================================
    # UTILITIES FILES
    # ============================================================================
    PRINT_HELP="$UTILS_DIR/help.sh"
    BANNER_FILE="$UTILS_DIR/banner.sh"

    ACTION_CUSTOM="$COMMON_DIR/sysinfo_enhanced.sh"
    ACTION_SYSINFO="$COMMON_DIR/sysinfo_default.sh"
    ACTION_NETINFO="$COMMON_DIR/netinfo.sh"

    PROMPT_SUDO="$UTILS_DIR/sudo.sh"
    
    # ============================================================================
    # AUDIT MODE SPECIFIC
    # ============================================================================

    AUDIT_DIR="$SRC_DIR/modes/audit"
    AUDIT_HELPERS="$AUDIT_DIR/helpers"
    AUDIT_MODULES="$AUDIT_DIR/modules"

    AUDIT_CLI="$AUDIT_DIR/audit-cli.sh"
    AUDIT_SETTINGS="$AUDIT_DIR/audit.conf"
    
    # ============================================================================
    # SCAN MODE SPECIFIC
    # ============================================================================    
    
    SCAN_DIR="$SRC_DIR/modes/scan"
    SCAN_HELPERS="$SCAN_DIR/helpers"
    SCAN_MODULES="$SCAN_DIR/modules"
    
    SCAN_LOGIC="$SCAN_HELPERS/logic.sh"
    SCAN_UTILS="$SCAN_HELPERS/utils.sh"
    SCAN_LOGGER="$SCAN_HELPERS/logger.sh"

    SCAN_CLI="$SCAN_DIR/scan-cli.sh"
    SCAN_SETTINGS="$SCAN_DIR/scan.conf"
    
    # ============================================================================
    # SCAN MODE ALIASES (for backward compatibility)
    # ============================================================================
    
    # Map new variable names to old expected names for scan-cli.sh
    STYLE="$STYLE_FILE"
    LOGIC="$SCAN_LOGIC"
    LOGGER="$SCAN_LOGGER"
    MODULES="$SCAN_MODULES"
    CONFIG_FILE="$SCAN_SETTINGS"
    
    # Additional scan mode files (if they exist)
    LOGO="${SCAN_LOGO:-}"
    BANNER="${SCAN_BANNER:-}"
    DEFAULT="${SCAN_DEFAULT:-$COMMON_DIR/sysinfo_default.sh}"
    SYSINFO="${SCAN_SYSINFO:-$COMMON_DIR/sysinfo_default.sh}"
    NETINFO="${SCAN_NETINFO:-$COMMON_DIR/netinfo.py}"
    
    # Alias for ASSETS (used in style.sh)
    ASSETS="$ASSETS_DIR"
        
    # ============================================================================
    # AUDIT MODE PATHS
    # ============================================================================

    # Export all variables automatically using set -a
    # This ensures all variables defined above are exported
    set -a
    # All variables are now exported
    set +a
}

# Make function available (don't use export -f as it may not work in all shells)
# The function will be available after sourcing this file
