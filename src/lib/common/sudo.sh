#!/usr/bin/env bash
# Sudo handling and privilege management

# Load dependencies (if not already loaded)
if [[ -z "$RED" ]]; then
    source "${BASH_SOURCE[0]%/*}/colors.sh"
fi
if ! type log_output >/dev/null 2>&1; then
    source "${BASH_SOURCE[0]%/*}/functions.sh"
fi

# Sudo status
SUDO_NEEDED=false
SUDO_AVAILABLE=false
SUDO_KEEPALIVE_PID=""

# Check if sudo is needed and available
check_sudo_requirements() {
    # Check if sudo is available
    if command -v sudo >/dev/null 2>&1; then
        SUDO_AVAILABLE=true
    fi
    
    # We need sudo for:
    # - dmesg (kernel messages) - typically requires sudo for full access
    # - smartctl (disk health) - requires sudo for disk access
    # Check if these commands exist and would benefit from sudo
    if command -v dmesg >/dev/null 2>&1 || command -v smartctl >/dev/null 2>&1; then
        SUDO_NEEDED=true
    fi
    
    # Also check if we can access dmesg without sudo
    # If not, we definitely need sudo
    if ! dmesg >/dev/null 2>&1; then
        SUDO_NEEDED=true
    fi
}

# Request sudo access and keep it alive
request_sudo() {
    if [[ "$SUDO_NEEDED" == true && "$SUDO_AVAILABLE" == true ]]; then
        # Check if sudo is already available (no password needed)
        if sudo -n -v 2>/dev/null; then
            # Sudo is already authenticated, use it without prompting
            # Keep sudo alive by refreshing it periodically
            (
                while true; do
                    sleep 60
                    sudo -v 2>/dev/null || exit
                done
            ) &
            SUDO_KEEPALIVE_PID=$!
            echo -e "${GREEN}✓ Using existing sudo access${NC}\n"
            log_output "Using existing sudo access"
            return
        fi
        
        # Sudo not available, prompt user
        echo -e "${YELLOW}  This script can use sudo for enhanced accuracy."
        echo -e "${YELLOW}  Its not a requirement, but without it some checks may be incomplete or misleading.\n"
        echo -ne "${NC}  Proceed with sudo access? (Y/n): ${CYAN}"
        read -n 1 -s SUDO_RESPONSE
        if [[ "$SUDO_RESPONSE" == "n" ]]; then
            echo -e "\n${NC}${YELLOW}! Sudo access denied. Skipping high level checks...${NC}"
            log_output "! Sudo access denied. Skipping high level checks..."
            SUDO_AVAILABLE=false
            return
        fi
        
        # Validate and cache sudo credentials
        if sudo -v; then
            # Keep sudo alive by refreshing it periodically
            (
                while true; do
                    sleep 60
                    sudo -v 2>/dev/null || exit
                done
            ) &
            SUDO_KEEPALIVE_PID=$!
            echo -e "\n${NC}${GREEN}✓ Sudo access granted\n${NC}"
            log_output "Sudo access granted"
        else
            echo -e "\n${NC}${RED}✗ Failed to obtain sudo access${NC}"
            echo -e "${YELLOW}Some checks will be skipped or may show incomplete results${NC}\n"
            log_output "Failed to obtain sudo access - some checks may be incomplete"
            SUDO_AVAILABLE=false
        fi
    fi
}

# Cleanup function to kill sudo keepalive
cleanup_sudo() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    fi
}

# Export variables and functions
export SUDO_NEEDED SUDO_AVAILABLE SUDO_KEEPALIVE_PID
export -f check_sudo_requirements request_sudo cleanup_sudo
