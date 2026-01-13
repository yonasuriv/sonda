#!/bin/bash

# Sonda Logging System
# Logs to $HOME/.logs/sonda/

# Get user's home directory (handles sudo scenarios)
if [[ "$EUID" -eq 0 ]] && [[ -n "${SUDO_USER:-}" ]]; then
    LOG_USER_HOME=$(eval echo "~$SUDO_USER")
else
    LOG_USER_HOME="$HOME"
fi

# Log directory
LOG_DIR="$LOG_USER_HOME/.logs/sonda"
LOG_FILE="$LOG_DIR/sonda.log"
ERROR_LOG="$LOG_DIR/error.log"
DEBUG_LOG="$LOG_DIR/debug.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Log levels
LOG_LEVEL_ERROR=1
LOG_LEVEL_WARN=2
LOG_LEVEL_INFO=3
LOG_LEVEL_DEBUG=4

# Current log level (default: INFO)
CURRENT_LOG_LEVEL="${SONDA_LOG_LEVEL:-$LOG_LEVEL_INFO}"

# Function to get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to write to log file
write_log() {
    local level="$1"
    local message="$2"
    local log_file="$3"
    local timestamp=$(get_timestamp)
    
    # Only write if log level allows
    case "$level" in
        "ERROR")
            if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_ERROR ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null || true
            fi
            ;;
        "WARN")
            if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_WARN ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null || true
            fi
            ;;
        "INFO")
            if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null || true
            fi
            ;;
        "DEBUG")
            if [[ $CURRENT_LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then
                echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null || true
            fi
            ;;
    esac
}

# Log functions
log_error() {
    local message="$*"
    write_log "ERROR" "$message" "$LOG_FILE"
    write_log "ERROR" "$message" "$ERROR_LOG"
    echo "[ERROR] $message" >&2
}

log_warn() {
    local message="$*"
    write_log "WARN" "$message" "$LOG_FILE"
}

log_info() {
    local message="$*"
    write_log "INFO" "$message" "$LOG_FILE"
}

log_debug() {
    local message="$*"
    write_log "DEBUG" "$message" "$DEBUG_LOG"
}

# Function to log command execution
log_command() {
    local command="$*"
    log_debug "Executing: $command"
}

# Function to rotate logs (keep last 10 files, max 1MB each)
rotate_logs() {
    local log_file="$1"
    local max_size=1048576  # 1MB in bytes
    local max_files=10
    local size=0
    
    if [[ -f "$log_file" ]]; then
        # Try different stat commands for different systems
        if command -v stat &> /dev/null; then
            size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
        else
            # Fallback: use wc -c
            size=$(wc -c < "$log_file" 2>/dev/null || echo 0)
        fi
        
        # Convert to integer
        size=$((size + 0))
        
        if [[ $size -gt $max_size ]]; then
            # Rotate log file
            local rotated_file="${log_file}.$(date +%Y%m%d_%H%M%S)"
            mv "$log_file" "$rotated_file" 2>/dev/null || true
            
            # Keep only last max_files
            if command -v ls &> /dev/null; then
                ls -t "${log_file}".* 2>/dev/null | tail -n +$((max_files + 1)) | xargs rm -f 2>/dev/null || true
            fi
        fi
    fi
}

# Rotate logs on load
rotate_logs "$LOG_FILE"
rotate_logs "$ERROR_LOG"
rotate_logs "$DEBUG_LOG"

# Initialize logging
log_info "Sonda logging system initialized"
log_debug "Log directory: $LOG_DIR"
log_debug "Current log level: $CURRENT_LOG_LEVEL"
