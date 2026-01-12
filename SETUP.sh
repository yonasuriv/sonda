#!/bin/bash

# Sonda Installation/Uninstallation Script
# Version: 1.9.0
# Created by @yonasuriv
# Modified for professional installation/uninstallation

# Enable strict error handling
set -euo pipefail

# Script version
SCRIPT_VERSION="1.9.0"
SCRIPT_NAME="Sonda Setup Script"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if terminal supports colors
if [[ -t 1 ]] && command -v tput &> /dev/null; then
    COLOR_SUPPORT=1
else
    COLOR_SUPPORT=0
fi

# Source color definitions if available
if [[ -f "$SCRIPT_DIR/lib/includes/style" ]]; then
    # Temporarily disable error handling for sourcing
    set +e
    source "$SCRIPT_DIR/lib/includes/style" 2>/dev/null
    set -e
fi

# Ensure color variables are set (with or without style file)
LB="${LB:-\n}"
RT="${RT:-\033[0m}"
RED="${RED:-\033[0;31m}"
GREEN="${GREEN:-\033[0;32m}"
YELLOW="${YELLOW:-\033[0;33m}"
BLUE="${BLUE:-\033[0;34m}"
CYAN="${CYAN:-\033[0;36m}"
BOLD="${BOLD:-\033[1m}"
DIM="${DIM:-\033[2m}"
NKBRRED="${NKBRRED:-\033[91m}"
NKBRGREEN="${NKBRGREEN:-\033[92m}"
NKYELLOW="${NKYELLOW:-\033[93m}"
I="${I:-[*]}"
E="${E:-${NKBRRED} [E] ${RT}}"
W="${W:-${NKYELLOW} [!] ${RT}}"
S="${S:-${NKBRGREEN} [✔] ${RT}}"

# Disable colors if terminal doesn't support them
if [[ $COLOR_SUPPORT -eq 0 ]]; then
    LB="\n"
    RT=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    BOLD=""
    DIM=""
    NKBRRED=""
    NKBRGREEN=""
    NKYELLOW=""
    I=" [*] "
    E=" [E] "
    W=" [!] "
    S=" [✔] "
fi

# Define variables
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/sonda}"
REPO_URL="https://github.com/yonasuriv/sonda"
USR_SHARE="/usr/share"
USR_BIN="/usr/bin"
BIN_NAME="sonda"
LOCAL_BIN_NAME="sonda"
DESKTOP_FILE="static/shortcuts/sonda.desktop"
ICON_FILE="static/icons/sonda.png"
REQUIREMENTS_FILE="requirements.txt"

# Track installed components for rollback
INSTALLED_COMPONENTS=()

# Function to print error and exit
fail() {
    local message="${1:-Process failed}"
    echo -e "${LB}${E} ${RED}${message}${RT}" >&2
    cleanup_on_failure
    exit 1
}

# Function to cleanup on installation failure
cleanup_on_failure() {
    if [[ ${#INSTALLED_COMPONENTS[@]} -gt 0 ]]; then
        echo -e "${LB}${W} Cleaning up partial installation...${RT}"
        for component in "${INSTALLED_COMPONENTS[@]}"; do
            case "$component" in
                "binary")
                    sudo rm -f "$USR_BIN/$BIN_NAME" 2>/dev/null || true
                    ;;
                "desktop")
                    sudo rm -f "/usr/share/applications/sonda.desktop" 2>/dev/null || true
                    ;;
                "symlink")
                    sudo rm -f "$USR_SHARE/sonda" 2>/dev/null || true
                    ;;
                "directory")
                    sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true
                    ;;
            esac
        done
    fi
}

# Function to check required system dependencies
check_required_dependencies() {
    local missing_deps=()
    local deps=("curl" "git" "python3")
    local all_present=true
    
    echo -e "${I} Checking pre-requisites...${RT}"
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
            all_present=false
        fi
    done
    
    if [[ $all_present == true ]]; then
        echo -e " |  ${GREEN}✓${RT} All required pre-requistes met."
        echo -e " | "
        return 0
    else
        echo -e " |  ${RED}${E}${RT} Missing required dependencies: ${missing_deps[*]}"
        echo -e " | "
        echo -e "${E} Please install missing dependencies and try again:${RT}"
        echo -e "   ${CYAN}sudo apt update && sudo apt install -y ${missing_deps[*]}${RT}"
        return 1
    fi
}

# Function to check Python package manager
check_python_package_manager() {
    if command -v pip3 &> /dev/null; then
        echo "pip3"
        return 0
    elif python3 -m pip --version &> /dev/null 2>&1; then
        echo "python3 -m pip"
        return 0
    else
        return 1
    fi
}

# Function to check sudo access
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        # Running as root, check for SUDO_USER
        if [[ -z "${SUDO_USER:-}" ]]; then
            echo -e "${E} Do not run this script directly as root. Use sudo instead.${RT}" >&2
            exit 1
        fi
        return 0
    fi
    
    # Check if user can use sudo
    if ! sudo -n true 2>/dev/null; then
        echo -ne "${W} This script requires sudo privileges. Please enter the "
        if ! sudo -v; then
            echo -e "${LB}${E} Operation cancelled.${RT}"
            exit 1
        fi
        echo ""  # New line after password entry
    fi
}

# Function to get target user and home
get_target_user() {
    if [[ $EUID -eq 0 ]]; then
        echo "${SUDO_USER:-root}"
    else
        echo "$USER"
    fi
}

# Function to display version
show_version() {
    echo -e "\n${BLUE}${BOLD}${SCRIPT_NAME} ${SCRIPT_VERSION}${RT}"
    echo -e "${DIM}Version: ${SCRIPT_VERSION}${RT}${LB}"
}

# Function to display usage/help
show_usage() {
    show_version
    echo -e "${CYAN}Usage:${RT}"
    echo -e "  ${BOLD}./SETUP.sh${RT} ${GREEN}-i${RT} | ${GREEN}--install${RT}     Install Sonda"
    echo -e "  ${BOLD}./SETUP.sh${RT} ${GREEN}-u${RT} | ${GREEN}--uninstall${RT}   Uninstall Sonda"
    echo -e "  ${BOLD}./SETUP.sh${RT} ${GREEN}-v${RT} | ${GREEN}--version${RT}     Show version"
    echo -e "  ${BOLD}./SETUP.sh${RT} ${GREEN}-h${RT} | ${GREEN}--help${RT}        Show this help"
    echo ""
    echo -e "${CYAN}Examples:${RT}"
    echo -e "  sudo ./SETUP.sh --install"
    echo -e "  sudo ./SETUP.sh -u"
    echo ""
}

# Function to prompt for confirmation
install_prompt() {
    local action="${1:-install}"

    if [[ $action == "install" ]]; then
        action="${NKGREEN}install${RT}"
    else
        action="${NKRED}uninstall${RT}"
    fi
    
    echo -ne "${W} You are about to ${action} sonda$. Continue? [Y/n]: "
    
    local answer
    read -r answer
    
    # Clear the prompt line
    echo -ne "\033[A\033[K"
    
    # Default to yes if empty
    if [[ -z "$answer" ]]; then
        answer="y"
    fi
    
    # Check response
    if [[ ! "$answer" =~ ^[yY]$ ]]; then
        echo -e "${E} ${action^} cancelled.${RT}"
        exit 0
    fi
}

# Function to safely add sudoers entry
add_sudoers_entry() {
    local username="$1"
    local entry="$username ALL=(ALL) NOPASSWD: /usr/bin/apt update"
    local sudoers_backup="/etc/sudoers.sonda.backup"
    
    # Check if entry already exists
    if sudo grep -qF "$entry" /etc/sudoers 2>/dev/null; then
        return 0
    fi
    
    # Create backup
    if [[ ! -f "$sudoers_backup" ]]; then
        sudo cp /etc/sudoers "$sudoers_backup" || {
            echo -e "${W} Could not create sudoers backup. Skipping sudoers modification.${RT}"
            return 1
        }
    fi
    
    # Validate entry format
    if ! echo "$entry" | sudo visudo -c -f - &>/dev/null; then
        echo -e "${W} Invalid sudoers entry format. Skipping.${RT}"
        return 1
    fi
    
    # Add entry using visudo
    echo "$entry" | sudo EDITOR='tee -a' visudo &>/dev/null || {
        echo -e "${W} Failed to add sudoers entry.${RT}"
        # Restore backup if modification failed
        if [[ -f "$sudoers_backup" ]]; then
            sudo cp "$sudoers_backup" /etc/sudoers
        fi
        return 1
    }
    
    # Validate final sudoers file
    if ! sudo visudo -c &>/dev/null; then
        echo -e "${E} Sudoers file validation failed. Restoring backup.${RT}"
        sudo cp "$sudoers_backup" /etc/sudoers
        return 1
    fi
    
    return 0
}

# Function to install Python dependencies
install_python_deps() {
    local pip_cmd
    local requirements_file="$SCRIPT_DIR/$REQUIREMENTS_FILE"
    
    # Check if requirements file exists
    if [[ ! -f "$requirements_file" ]]; then
        echo -e "${I} Installing Python dependencies...${RT}"
        echo -e " |  ${YELLOW}⚠${RT} Requirements file not found, skipping"
        echo -e " | "
        return 0
    fi
    
    # Check for Python package manager
    if ! pip_cmd=$(check_python_package_manager); then
        echo -e "${I} Installing Python dependencies...${RT}"
        echo -e " |  ${YELLOW}⚠${RT} Python package manager (pip3) not found"
        echo -e " |  ${DIM}Installing pip3...${RT}"
        
        # Try to install pip3
        if command -v apt &> /dev/null; then
            if sudo apt install -y python3-pip &>/dev/null; then
                pip_cmd="pip3"
                echo -e " |  ${GREEN}✓${RT} pip3 installed successfully"
            else
                echo -e " |  ${RED}✗${RT} Failed to install pip3"
                echo -e " |  ${DIM}You can install Python dependencies manually later:${RT}"
                echo -e " |  ${DIM}  pip3 install -r $requirements_file${RT}"
                echo -e " | "
                return 1
            fi
        else
            echo -e " |  ${RED}✗${RT} Cannot install pip3 automatically"
            echo -e " |  ${DIM}Please install pip3 manually and run:${RT}"
            echo -e " |  ${DIM}  pip3 install -r $requirements_file${RT}"
            echo -e " | "
            return 1
        fi
    fi
    
    echo -e "${I} Installing Python dependencies...${RT}"
    echo -e " |  ${DIM}Using: $pip_cmd${RT}"
    echo -e " |  ${GREEN}✓${RT} All python dependencies are installed."
    
    # Install dependencies quietly, capture errors
    local install_output
    local install_status
    
    install_output=$($pip_cmd install -q -r "$requirements_file" 2>&1)
    install_status=$?
    
    if [[ $install_status -eq 0 ]]; then
        echo -e " |  ${GREEN}✓${RT} Python dependencies installed successfully"
        echo -e " | "
        return 0
    else
        # Check if there are actual errors (not just warnings)
        if echo "$install_output" | grep -qiE "(error|failed|cannot)"; then
            echo -e " |  ${YELLOW}⚠${RT} Some Python dependencies failed to install"
            echo -e " |  ${DIM}You can install them manually later:${RT}"
            echo -e " |  ${DIM}  $pip_cmd install -r $requirements_file${RT}"
        else
            echo -e " |  ${GREEN}✓${RT} Python dependencies installed (with warnings)"
        fi
        echo -e " | "
        return 0  # Don't fail installation if Python deps fail
    fi
}

# Function to install optional system dependencies
install_system_deps() {
    local optional_deps=("lolcat" "inxi" "pciutils")
    local missing_optional=()
    local installed_count=0
    
    echo -e "${I} Installing optional system dependencies...${RT}"
    
    # Check if apt is available
    if ! command -v apt &> /dev/null; then
        echo -e " |  ${YELLOW}⚠${RT} apt not found, skipping optional dependencies"
        echo -e " | "
        return 0
    fi
    
    # Check which dependencies are already installed
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_optional+=("$dep")
        fi
    done
    
    if [[ ${#missing_optional[@]} -eq 0 ]]; then
        echo -e " |  ${GREEN}✓${RT} All optional dependencies already installed"
        echo -e " | "
        return 0
    fi
    
    echo -e " |  ${DIM}Installing: ${missing_optional[*]}${RT}"
    
    # Install missing dependencies
    if sudo apt install -y "${missing_optional[@]}" &>/dev/null; then
        echo -e " |  ${GREEN}✓${RT} Optional dependencies installed successfully"
        echo -e " | "
        return 0
    else
        echo -e " |  ${YELLOW}⚠${RT} Some optional dependencies may not be available"
        echo -e " |  ${DIM}This will not affect core functionality${RT}"
        echo -e " | "
        return 0  # Don't fail if optional deps fail
    fi
}

# Function to handle installation
install_sonda() {
    local target_user
    local target_home
    
    show_version
    
    # Check sudo first (needed for dependency installation)
    check_sudo
    
    # Check required dependencies
    if ! check_required_dependencies; then
        fail "Missing required dependencies"
    fi
    
    # Get target user
    target_user=$(get_target_user)
    target_home=$(getent passwd "$target_user" | cut -d: -f6)
    
    if [[ -z "$target_home" ]]; then
        fail "Could not determine home directory for user: $target_user"
    fi
    
    INSTALL_DIR="$target_home/.local/share/sonda"
    
    # Prompt for confirmation
    install_prompt "install"
    
    echo -e "${I}  Starting installation process...${RT}"
    echo -e " | "
    
    # Install optional system dependencies
    install_system_deps
    
    # Install Python dependencies
    install_python_deps
    
    # Create installation directory
    echo -e "${I} Creating installation directory...${RT}"
    if sudo -u "$target_user" mkdir -p "$INSTALL_DIR"; then
        INSTALLED_COMPONENTS+=("directory")
        echo -e " |  ${GREEN}✓${RT} Directory created: $INSTALL_DIR"
    else
        fail "Failed to create installation directory"
    fi
    echo -e " | "
    
    # Copy files
    echo -e "${I} Copying files to installation directory...${RT}"
    if [[ ! -d "$SCRIPT_DIR" ]]; then
        fail "Script directory not found: $SCRIPT_DIR"
    fi
    
    # Use rsync if available for better copying, otherwise use cp
    if command -v rsync &> /dev/null; then
        if sudo -u "$target_user" rsync -aq --exclude='.git' "$SCRIPT_DIR/" "$INSTALL_DIR/" 2>/dev/null; then
            echo -e " |  ${GREEN}✓${RT} Files copied successfully"
        elif sudo -u "$target_user" cp -r "$SCRIPT_DIR/"* "$INSTALL_DIR/" 2>/dev/null; then
            echo -e " |  ${GREEN}✓${RT} Files copied successfully"
        else
            fail "Failed to copy files"
        fi
    else
        if sudo -u "$target_user" cp -r "$SCRIPT_DIR/"* "$INSTALL_DIR/" 2>/dev/null; then
            echo -e " |  ${GREEN}✓${RT} Files copied successfully"
        else
            fail "Failed to copy files"
        fi
    fi
    echo -e " | "
    
    # Set permissions
    echo -e "${I} Setting permissions...${RT}"
    if sudo chown -R "$target_user:$target_user" "$INSTALL_DIR" && \
       sudo chmod 755 "$INSTALL_DIR" && \
       sudo find "$INSTALL_DIR" -type f -exec chmod 644 {} \; 2>/dev/null && \
       sudo find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null && \
       sudo find "$INSTALL_DIR/bin" -type f -exec chmod +x {} \; 2>/dev/null; then
        echo -e " |  ${GREEN}✓${RT} Permissions set successfully"
    else
        fail "Failed to set permissions"
    fi
    echo -e " | "
    
    # Create symlink in /usr/share
    echo -e "${I} Creating symbolic link in /usr/share...${RT}"
    if [[ "$INSTALL_DIR" == "$USR_SHARE/sonda" ]]; then
        fail "Cannot create symlink to same directory"
    fi
    
    # Remove existing symlink if it exists
    sudo rm -f "$USR_SHARE/sonda" 2>/dev/null || true
    if sudo ln -sf "$INSTALL_DIR" "$USR_SHARE/sonda"; then
        INSTALLED_COMPONENTS+=("symlink")
        echo -e " |  ${GREEN}✓${RT} Symbolic link created"
        # Remove any symlinks inside install directory
        find "$INSTALL_DIR" -maxdepth 1 -type l -exec rm -f {} \; 2>/dev/null || true
    else
        fail "Failed to create symlink"
    fi
    echo -e " | "
    
    # Link binary
    echo -e "${I} Linking binary...${RT}"
    if [[ ! -f "$INSTALL_DIR/bin/$LOCAL_BIN_NAME" ]]; then
        fail "Binary file not found: $INSTALL_DIR/bin/$LOCAL_BIN_NAME"
    fi
    
    sudo rm -f "$USR_BIN/$BIN_NAME" 2>/dev/null || true
    if sudo ln -sf "$INSTALL_DIR/bin/$LOCAL_BIN_NAME" "$USR_BIN/$BIN_NAME" && \
       sudo chmod +x "$USR_BIN/$BIN_NAME"; then
        INSTALLED_COMPONENTS+=("binary")
        echo -e " |  ${GREEN}✓${RT} Binary linked successfully"
    else
        fail "Failed to create binary symlink"
    fi
    echo -e " | "
    
    # Install desktop file
    echo -e "${I} Installing .desktop file...${RT}"
    if [[ ! -f "$INSTALL_DIR/$DESKTOP_FILE" ]]; then
        echo -e " |  ${YELLOW}⚠${RT} Desktop file not found, skipping"
    else
        sudo mkdir -p "/usr/share/applications" 2>/dev/null || true
        if sudo cp -f "$INSTALL_DIR/$DESKTOP_FILE" "/usr/share/applications/"; then
            INSTALLED_COMPONENTS+=("desktop")
            echo -e " |  ${GREEN}✓${RT} Desktop file installed"
        else
            echo -e " |  ${YELLOW}⚠${RT} Failed to install desktop file"
        fi
    fi
    echo -e " | "
    
    # Set icon permissions
    echo -e "${I} Setting icon file permissions...${RT}"
    if [[ -f "$INSTALL_DIR/$ICON_FILE" ]]; then
        if sudo chmod 644 "$INSTALL_DIR/$ICON_FILE" 2>/dev/null; then
            echo -e " |  ${GREEN}✓${RT} Icon permissions set"
        else
            echo -e " |  ${YELLOW}⚠${RT} Failed to set icon permissions"
        fi
    else
        echo -e " |  ${YELLOW}⚠${RT} Icon file not found, skipping"
    fi
    echo -e " | "
    
    # Setup shell (sudoers entry)
    echo -e "${I} Setting up the Shell...${RT}"
    if add_sudoers_entry "$target_user"; then
        echo -e " |  ${GREEN}✓${RT} Sudoers entry added successfully"
    else
        echo -e " |  ${YELLOW}⚠${RT} Sudoers entry skipped or already exists"
    fi
    echo -e " | "
    
    # Success message
    echo -e "${LB}${S} ${GREEN}Installation success.${RT}${LB}"
    echo -e "${DIM}You can now run 'sonda' from anywhere in your terminal.${RT}${LB}"
}

# Function to handle uninstallation
uninstall_sonda() {
    local target_user
    local target_home
    
    show_version
    
    # Check sudo
    check_sudo
    
    # Get target user
    target_user=$(get_target_user)
    target_home=$(getent passwd "$target_user" | cut -d: -f6)
    
    if [[ -z "$target_home" ]]; then
        target_home="$HOME"
    fi
    
    INSTALL_DIR="$target_home/.local/share/sonda"
    
    # Prompt for confirmation
    install_prompt "uninstall"
    
    echo -e "${LB}  +  Starting uninstallation process...${RT}"
    echo -e " | "
    
    # Remove binary symlink
    echo -e "${I} Removing binary symlink...${RT}"
    if [[ -L "$USR_BIN/$BIN_NAME" ]] || [[ -f "$USR_BIN/$BIN_NAME" ]]; then
        sudo rm -f "$USR_BIN/$BIN_NAME" || echo -e "${W} Could not remove binary symlink.${RT}"
    fi
    echo -e " | "
    
    # Remove desktop file
    echo -e "${I} Removing .desktop file...${RT}"
    if [[ -f "/usr/share/applications/sonda.desktop" ]]; then
        sudo rm -f "/usr/share/applications/sonda.desktop" || echo -e "${W} Could not remove desktop file.${RT}"
    fi
    echo -e " | "
    
    # Remove symlink from /usr/share
    echo -e "${I} Removing symbolic link from /usr/share...${RT}"
    if [[ -L "$USR_SHARE/sonda" ]]; then
        sudo rm -f "$USR_SHARE/sonda" || echo -e "${W} Could not remove symlink.${RT}"
    fi
    echo -e " | "
    
    # Remove installation directory
    echo -e "${I} Removing installation directory...${RT}"
    if [[ -d "$INSTALL_DIR" ]]; then
        sudo rm -rf "$INSTALL_DIR" || echo -e "${W} Could not remove installation directory.${RT}"
    fi
    echo -e " | "
    
    # Note: We don't remove sudoers entry automatically for safety
    # User can remove it manually if needed
    
    echo -e "${LB}${S} ${GREEN}Uninstallation complete.${RT}${LB}"
    echo -e "${DIM}Note: Sudoers entry (if added) was not removed for safety.${RT}"
    echo -e "${DIM}You can remove it manually if needed.${RT}${LB}"
}

# Main argument parsing
main() {
    case "${1:-}" in
        --install|-i)
            install_sonda
            ;;
        --uninstall|-u)
            uninstall_sonda
            ;;
        --version|-v)
            show_version
            exit 0
            ;;
        --help|-h|"")
            show_usage
            if [[ -z "${1:-}" ]]; then
                exit 1
            fi
            exit 0
            ;;
        *)
            echo -e "${E} ${RED}Invalid argument: ${1:-none}${RT}"
            echo -e "${E} ${RED}Use -h or --help for usage information${RT}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
