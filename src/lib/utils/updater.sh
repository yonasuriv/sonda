#!/bin/bash

# Check local version only (local)

get_version() {
    local local_version
    if [[ -f "${VERSION_FILE:-}" ]]; then
        local_version=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '\n\r ' || echo "unknown")
        echo -e "${S} ${BLUE}Sonda version${RT} ${GREEN}$local_version${RT}"
        log_info "Version: $local_version"
        return 0
    else
        echo -e "${E} Local version file not found.${RT}" >&2
        log_error "Local version file not found: ${VERSION_FILE:-<unset>}"
        return 1
    fi
}

# Enhanced version checking function
get_update() {
    local local_version
    local remote_version
    
    log_info "Checking for updates (check-only mode)"
    
    # Get local version
    if [[ -f "$VERSION_FILE" ]]; then
        local_version=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '\n\r ' || echo "unknown")
    else
        echo -e "${E} Local version file not found.${RT}" >&2
        log_error "Local version file not found: $VERSION_FILE"
        return 1
    fi
    
    # Get remote version
    if ! command -v curl &> /dev/null; then
        echo -e "${E} curl not found. Cannot check remote version.${RT}" >&2
        log_error "curl not found"
        return 1
    fi
    
    remote_version=$(curl -s --connect-timeout 5 --max-time 10 \
        "https://raw.githubusercontent.com/yonasuriv/sonda/refs/heads/main/VERSION" \
        2>/dev/null | tr -d '\n\r ' || echo "")
    
    if [[ -z "$remote_version" ]]; then
        echo -e "${E} Failed to retrieve remote version. Check your internet connection.${RT}" >&2
        log_error "Failed to retrieve remote version"
        return 1
    fi
    
    # Compare versions
    if [[ "$local_version" == "$remote_version" ]]; then
        echo -e "${S} ${BLUE}Sonda version${RT} $local_version ${GREEN}(running the latest version)${RT}"
        log_info "Version check: up to date ($local_version)"
        return 0
    else
        echo -e "${W} There is a new version disponible: ${GREEN2}$remote_version${RT} (upgradable from ${YELLOW2}$local_version${RT})\n"
        echo -e "    Run ${CYAN}sonda --upgrade${RT} to get the latest version.${RT}"
        log_info "Version check: update available ($local_version -> $remote_version)"
        return 2
    fi
}

# Enhanced upgrade function
perform_upgrade() {
    local local_version
    local remote_version
    local update_status=0
    
    log_info "Starting upgrade process"
    
    # Get local version
    if [[ -f "$VERSION_FILE" ]]; then
        local_version=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '\n\r ' || echo "unknown")
    else
        echo -e "${E} Local version file not found.${RT}"
        log_error "Local version file not found"
        return 1
    fi
    
    echo -e "${LB}  +  Checking for updates...${RT}"
    echo -e ""
    echo -e "  ${DIM}Current version: $local_version${RT}"
    
    # Get remote version
    if ! command -v curl &> /dev/null; then
        echo -e "  |  ${RED}✗${RT} curl not found"
        echo -e "${E} curl not found. Cannot check for updates.${RT}"
        log_error "curl not found"
        return 1
    fi
    
    remote_version=$(curl -s --connect-timeout 5 --max-time 10 \
        "https://raw.githubusercontent.com/yonasuriv/sonda/refs/heads/main/VERSION" \
        2>/dev/null | tr -d '\n\r ' || echo "")
    
    if [[ -z "$remote_version" ]]; then
        echo -e "${E} Failed to retrieve remote version.${RT}"
        log_error "Failed to retrieve remote version"
        return 1
    fi
    
    echo -e "     ${DIM}Remote version: $remote_version${RT}"
    echo -e ""
    
    # Compare versions
    if [[ "$local_version" == "$remote_version" ]]; then
        echo -e "${LB}${S} ${GREEN}Already up to date. You are running the latest version ($local_version)${RT}${LB}"
        log_info "Update check: already up to date"
        return 0
    fi
    
    # Update available
    echo -e "  |  ${YELLOW}⚠${RT} Update available: $local_version → $remote_version"
    echo -e "  | "
    echo -e "  +  Updating Sonda...${RT}"
    
    # Check if it's a git repository
    if [[ ! -d "$INSTALL_DIR/.git" ]]; then
        echo -e "  |  ${RED}✗${RT} Installation directory is not a git repository"
        echo -e "  |  ${DIM}Please reinstall using: sudo ./SETUP.sh --install${RT}"
        echo -e "${E} Cannot update: not a git repository${RT}"
        log_error "Update failed: not a git repository"
        return 1
    fi
    
    # Check for git command
    if ! command -v git &> /dev/null; then
        echo -e "  |  ${RED}✗${RT} git not found"
        echo -e "${E} git not found. Cannot update.${RT}"
        log_error "git not found"
        return 1
    fi
    
    echo -e "  |  ${DIM}Using git to update...${RT}"
    
    # Configure git safe directory
    git config --global --add safe.directory "$INSTALL_DIR" 2>/dev/null || true
    
    # Change to installation directory
    cd "$INSTALL_DIR" || {
        echo -e "${E} Cannot access installation directory${RT}"
        log_error "Cannot access installation directory: $INSTALL_DIR"
        return 1
    }
    
    # Fetch and pull updates
    if git fetch origin main &>/dev/null; then
        if git pull origin main &>/dev/null; then
            # Verify update
            local new_version
            if [[ -f "$VERSION_FILE" ]]; then
                new_version=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '\n\r ' || echo "unknown")
            else
                new_version="unknown"
            fi
            
            if [[ "$new_version" != "$local_version" ]]; then
                echo -e "  |  ${GREEN}✓${RT} Updated successfully: $local_version → $new_version"
                echo -e "${LB}${S} ${GREEN}Update complete!${RT}${LB}"
                log_info "Update successful: $local_version -> $new_version"
                return 0
            else
                echo -e "  |  ${YELLOW}⚠${RT} Update completed but version unchanged"
                echo -e "${LB}${S} ${GREEN}Update complete${RT}${LB}"
                log_info "Update completed (version unchanged)"
                return 0
            fi
        else
            echo -e "  |  ${RED}✗${RT} Git pull failed"
            echo -e "${E} Update failed. Please try again later.${RT}"
            log_error "Git pull failed"
            return 1
        fi
    else
        echo -e "  |  ${RED}✗${RT} Git fetch failed"
        echo -e "${E} Update failed. Check your internet connection.${RT}"
        log_error "Git fetch failed"
        return 1
    fi
}