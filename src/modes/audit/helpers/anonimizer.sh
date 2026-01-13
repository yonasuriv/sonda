#!/usr/bin/env bash
# Anonymization functions - replace sensitive information with dummy values
# Reads configuration from default.conf and applies to both console and log output

# Load dependencies (if not already loaded)
if [[ -z "$AUDIT_DUMMY_IP" ]]; then
    source "${BASH_SOURCE[0]%/*}/config.sh"
fi

# Initialize real values (only once, cached)
# NOTE: This function should ONLY be called when anonymization is actually enabled
# to avoid expensive operations (hostname, whoami, curl, dig) when not needed
_init_anonymization() {
    # Only initialize if not already done
    if [[ -n "${_ANON_INITIALIZED:-}" ]]; then
        return 0
    fi
    
    # Get real values (these are fast operations)
    REAL_HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
    REAL_USER=$(whoami 2>/dev/null || echo "unknown")
    REAL_HOME="${HOME:-/home/$REAL_USER/}"
    
    # Get external IP (with timeout and multiple fallbacks)
    # This is the expensive operation - only do it if IP anonymization is enabled
    EXTERNAL_IP=""
    if [[ "${AUDIT_ANONYMIZE_IP:-false}" == "true" ]]; then
        if command -v curl >/dev/null 2>&1; then
            EXTERNAL_IP=$(curl -fsS --max-time 2 https://api.ipify.org 2>/dev/null || \
                          curl -fsS --max-time 2 https://ifconfig.me/ip 2>/dev/null || \
                          curl -fsS --max-time 2 https://icanhazip.com 2>/dev/null || \
                          echo "")
        fi
        if [[ -z "$EXTERNAL_IP" ]] && command -v dig >/dev/null 2>&1; then
            EXTERNAL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || echo "")
        fi
    fi
    
    # Get dummy values from config (with defaults)
    DUMMY_IP="${AUDIT_DUMMY_IP:-153.242.117.210}"
    DUMMY_HOST="${AUDIT_DUMMY_HOST:-lizard.local}"
    DUMMY_USER="${AUDIT_DUMMY_USER:-lizard}"
    DUMMY_HOME="/home/${DUMMY_USER}/"
    
    # Export variables so they're available in subshells
    export REAL_HOSTNAME REAL_USER REAL_HOME
    export EXTERNAL_IP
    export DUMMY_IP DUMMY_HOST DUMMY_USER DUMMY_HOME
    
    # Mark as initialized
    _ANON_INITIALIZED=true
    export _ANON_INITIALIZED
}

# Anonymize text based on configuration settings
# Usage: anonymized_text=$(anonymize_text "$text" "console"|"log")
anonymize_text() {
    local text="$1"
    local output_type="${2:-log}"  # "console" or "log"
    
    # Check if anonymization is enabled for this output type FIRST (before any expensive operations)
    local anonymize_enabled=false
    if [[ "$output_type" == "console" ]]; then
        anonymize_enabled="${AUDIT_CONSOLE_ANONYMIZE:-false}"
        # If silent mode is enabled, disable console anonymization (no console output to anonymize)
        if [[ "${AUDIT_VERBOSE:-false}" == false ]]; then
            anonymize_enabled=false
        fi
    else
        anonymize_enabled="${AUDIT_LOG_ANONYMIZE:-false}"
    fi
    
    # If anonymization is disabled, return original text immediately (no initialization needed)
    if [[ "$anonymize_enabled" != "true" ]]; then
        echo "$text"
        return 0
    fi
    
    # Only initialize if anonymization is actually enabled
    _init_anonymization
    
    local result="$text"
    
    # Anonymize IP address
    if [[ "$AUDIT_ANONYMIZE_IP" == "true" ]] && [[ -n "$EXTERNAL_IP" ]]; then
        result=$(echo "$result" | sed "s#${EXTERNAL_IP}#${DUMMY_IP}#g")
        # Also anonymize local IP patterns (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
        result=$(echo "$result" | sed -E "s#192\.168\.[0-9]+\.[0-9]+#${DUMMY_IP}#g")
        result=$(echo "$result" | sed -E "s#10\.[0-9]+\.[0-9]+\.[0-9]+#${DUMMY_IP}#g")
        result=$(echo "$result" | sed -E "s#172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+#${DUMMY_IP}#g")
    fi
    
    # Anonymize hostname
    if [[ "$AUDIT_ANONYMIZE_HOST" == "true" ]] && [[ -n "$REAL_HOSTNAME" ]] && [[ "$REAL_HOSTNAME" != "unknown" ]]; then
        result=$(echo "$result" | sed "s#${REAL_HOSTNAME}#${DUMMY_HOST}#g")
        # Also handle FQDN variations
        if [[ "$REAL_HOSTNAME" != "${REAL_HOSTNAME%%.*}" ]]; then
            result=$(echo "$result" | sed "s#${REAL_HOSTNAME%%.*}#${DUMMY_HOST%%.*}#g")
        fi
    fi
    
    # Anonymize username
    if [[ "$AUDIT_ANONYMIZE_USER" == "true" ]] && [[ -n "$REAL_USER" ]] && [[ "$REAL_USER" != "unknown" ]]; then
        result=$(echo "$result" | sed "s#${REAL_USER}#${DUMMY_USER}#g")
    fi
    
    # Anonymize home directory
    if [[ "$AUDIT_ANONYMIZE_USER" == "true" ]] && [[ -n "$REAL_HOME" ]]; then
        # Escape slashes in paths for sed
        result=$(echo "$result" | sed "s#${REAL_HOME}#${DUMMY_HOME}#g")
        # Also handle variations like ~
        if [[ "$REAL_HOME" == "$HOME" ]]; then
            result=$(echo "$result" | sed "s#~#${DUMMY_HOME}#g")
        fi
    fi
    
    echo "$result"
}

# Anonymize console output (wrapper for echo)
# Usage: echo_anon "text" (automatically applies console anonymization settings)
echo_anon() {
    local text="$1"
    local anonymized=$(anonymize_text "$text" "console")
    echo "$anonymized"
}

# Anonymize log files in bulk (after writing)
# This is faster than anonymizing each line individually
# Usage: anonymize_log_files
anonymize_log_files() {
    # Only proceed if anonymization is enabled and we're using after-write mode
    if [[ "$AUDIT_LOG_ANONYMIZE" != "true" ]] || [[ "$AUDIT_LOG_ANONYMIZE_AFTER_WRITE" != "true" ]]; then
        return 0
    fi
    
    # Initialize anonymization values if needed
    if [[ -z "${_ANON_INITIALIZED:-}" ]]; then
        _init_anonymization
    fi
    
    # Anonymize main log file
    if [[ -n "$AUDIT_LOG_FILE" ]] && [[ -f "$AUDIT_LOG_FILE" ]]; then
        # Create temporary file for anonymized content
        local temp_file="${AUDIT_LOG_FILE}.tmp"
        
        # Anonymize the file
        if [[ "$AUDIT_ANONYMIZE_IP" == "true" ]] && [[ -n "$EXTERNAL_IP" ]]; then
            sed -i "s#${EXTERNAL_IP}#${DUMMY_IP}#g" "$AUDIT_LOG_FILE"
            # Also anonymize local IP patterns
            sed -i -E "s#192\.168\.[0-9]+\.[0-9]+#${DUMMY_IP}#g" "$AUDIT_LOG_FILE"
            sed -i -E "s#10\.[0-9]+\.[0-9]+\.[0-9]+#${DUMMY_IP}#g" "$AUDIT_LOG_FILE"
            sed -i -E "s#172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+#${DUMMY_IP}#g" "$AUDIT_LOG_FILE"
        fi
        
        if [[ "$AUDIT_ANONYMIZE_HOST" == "true" ]] && [[ -n "$REAL_HOSTNAME" ]] && [[ "$REAL_HOSTNAME" != "unknown" ]]; then
            sed -i "s#${REAL_HOSTNAME}#${DUMMY_HOST}#g" "$AUDIT_LOG_FILE"
            if [[ "$REAL_HOSTNAME" != "${REAL_HOSTNAME%%.*}" ]]; then
                sed -i "s#${REAL_HOSTNAME%%.*}#${DUMMY_HOST%%.*}#g" "$AUDIT_LOG_FILE"
            fi
        fi
        
        if [[ "$AUDIT_ANONYMIZE_USER" == "true" ]] && [[ -n "$REAL_USER" ]] && [[ "$REAL_USER" != "unknown" ]]; then
            sed -i "s#${REAL_USER}#${DUMMY_USER}#g" "$AUDIT_LOG_FILE"
            if [[ -n "$REAL_HOME" ]]; then
                sed -i "s#${REAL_HOME}#${DUMMY_HOME}#g" "$AUDIT_LOG_FILE"
                if [[ "$REAL_HOME" == "$HOME" ]]; then
                    sed -i "s#~#${DUMMY_HOME}#g" "$AUDIT_LOG_FILE"
                fi
            fi
        fi
    fi
    
    # Anonymize detailed log file
    if [[ -n "$AUDIT_DETAILED_LOG" ]] && [[ -f "$AUDIT_DETAILED_LOG" ]]; then
        # Anonymize the file
        if [[ "$AUDIT_ANONYMIZE_IP" == "true" ]] && [[ -n "$EXTERNAL_IP" ]]; then
            sed -i "s#${EXTERNAL_IP}#${DUMMY_IP}#g" "$AUDIT_DETAILED_LOG"
            # Also anonymize local IP patterns
            sed -i -E "s#192\.168\.[0-9]+\.[0-9]+#${DUMMY_IP}#g" "$AUDIT_DETAILED_LOG"
            sed -i -E "s#10\.[0-9]+\.[0-9]+\.[0-9]+#${DUMMY_IP}#g" "$AUDIT_DETAILED_LOG"
            sed -i -E "s#172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+#${DUMMY_IP}#g" "$AUDIT_DETAILED_LOG"
        fi
        
        if [[ "$AUDIT_ANONYMIZE_HOST" == "true" ]] && [[ -n "$REAL_HOSTNAME" ]] && [[ "$REAL_HOSTNAME" != "unknown" ]]; then
            sed -i "s#${REAL_HOSTNAME}#${DUMMY_HOST}#g" "$AUDIT_DETAILED_LOG"
            if [[ "$REAL_HOSTNAME" != "${REAL_HOSTNAME%%.*}" ]]; then
                sed -i "s#${REAL_HOSTNAME%%.*}#${DUMMY_HOST%%.*}#g" "$AUDIT_DETAILED_LOG"
            fi
        fi
        
        if [[ "$AUDIT_ANONYMIZE_USER" == "true" ]] && [[ -n "$REAL_USER" ]] && [[ "$REAL_USER" != "unknown" ]]; then
            sed -i "s#${REAL_USER}#${DUMMY_USER}#g" "$AUDIT_DETAILED_LOG"
            if [[ -n "$REAL_HOME" ]]; then
                sed -i "s#${REAL_HOME}#${DUMMY_HOME}#g" "$AUDIT_DETAILED_LOG"
                if [[ "$REAL_HOME" == "$HOME" ]]; then
                    sed -i "s#~#${DUMMY_HOME}#g" "$AUDIT_DETAILED_LOG"
                fi
            fi
        fi
    fi
}

# Export functions for use in modules
export -f _init_anonymization anonymize_text echo_anon anonymize_log_files
