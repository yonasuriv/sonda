#!/bin/bash

# Sonda - Check Mode
# System information checking and reporting

# Core paths are already set by main sonda script
# INSTALL_DIR, HOMEUSER, VERSION_FILE, ASSETS, LOGFILE_DIR, LOGFILE are exported

# Check mode specific paths
# All paths are now defined in sonda.conf and exported by main script
set -a



# Source required files with error handling
# Map config variables to expected names
STYLE="${STYLE_FILE:-}"
LOGIC="${SCAN_LOGIC:-}"
UTILS="${SCAN_UTILS:-}"
LOGO="${SCAN_LOGO:-}"
LOGGER="${SCAN_LOGGER:-}"
BANNER="${SCAN_BANNER:-}"

if [[ -f "${STYLE:-}" ]]; then
    source "$STYLE" 2>/dev/null || log_warn "Failed to source style file"
else
    log_error "Style file not found: ${STYLE:-}"
    exit 1
fi

# Source utils first (contains pprint)
if [[ -f "${UTILS:-}" ]]; then
    source "$UTILS" 2>/dev/null || log_warn "Failed to source utils file"
fi

if [[ -f "${LOGIC:-}" ]]; then
    source "$LOGIC" 2>/dev/null || log_warn "Failed to source logic file"
else
    log_error "Logic file not found: ${LOGIC:-}"
    exit 1
fi

if [[ -f "${LOGO:-}" ]]; then
    source "$LOGO" 2>/dev/null || log_warn "Failed to source logo file"
fi

# Source config file if it exists (optional)
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE" 2>/dev/null || log_warn "Failed to source config file"
fi

# Source info modules (now directly in modules/)
for module in battery boot cpu devices disks gpu kernel memory network packages security; do
    if [[ -f "$SCAN_MODULES/$module.sh" ]]; then
        source "$SCAN_MODULES/$module.sh" 2>/dev/null || log_warn "Failed to source module: $module"
    elif [[ -f "$SCAN_MODULES/$module" ]]; then
        source "$SCAN_MODULES/$module" 2>/dev/null || log_warn "Failed to source module: $module"
    fi
done

# USAGE is no longer needed - help is handled by PRINT_HELP

set +a

# Variable to store the output modifier if --save is provided
SOUT=""
PRETTYP=""

# Function to print in yellow for sudo commands skipped
function print_sudo_skipped {
    echo -e "${LB}${YELLOW}[!] ${1} skipped as it requires elevated privileges (sudo).${RT}"
    log_warn "Sudo command skipped: $1"
}

# Safe command execution (replaces eval)
function safe_exec {
    local command="$1"
    
    # Allow pipes (|) and basic shell features, but prevent dangerous constructs
    # Block: command substitution with backticks, semicolons for command chaining, 
    # background processes (&), and dangerous variable expansion patterns
    # Note: Pipes (|) are explicitly allowed as they're needed for many commands
    if [[ "$command" =~ \` ]] || \
       [[ "$command" =~ \$\{.*\} ]] || \
       [[ "$command" =~ \;.*\; ]] || \
       [[ "$command" =~ \&\&.*\&\& ]] || \
       [[ "$command" =~ \|\|.*\|\| ]]; then
        log_error "Unsafe command detected: $command"
        echo "Error: Unsafe command detected" >&2
        return 1
    fi
    
    # Execute command - pipes are allowed
    eval "$command"
}

# Improved pprint function (replaces eval)
function pprint {
    local command="$1"
    if [[ -n "$PRETTYP" ]]; then
        # Run the command and strip ALL ANSI escape sequences completely
        # Handle both complete sequences (\e[ or \033[ or \x1b[) and partial ones (33[)
        if command -v perl &>/dev/null; then
            # Perl can handle binary escape sequences better
            # First remove complete escape sequences, then catch partial ones
            safe_exec "$command" 2>&1 | \
                perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g' | \
                perl -pe 's/\033\[[0-9;]*[a-zA-Z]//g' | \
                perl -pe 's/\x1b\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/33\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/33\[[0-9;]*m//g' | \
                sed 's/\[[0-9;]*m//g' | \
                sed 's/\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/33\[[0-9;]*//g'
        else
            # Use sed with comprehensive patterns to catch all ANSI escape sequences
            # Process in order: complete sequences first, then partial ones
            safe_exec "$command" 2>&1 | \
                sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/\033\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/\e\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/33\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/33\[[0-9;]*m//g' | \
                sed 's/\[[0-9;]*m//g' | \
                sed 's/\[[0-9;]*[a-zA-Z]//g' | \
                sed 's/33\[[0-9;]*//g' | \
                sed 's/^33\[//g' | \
                sed 's/33\[//g'
        fi
    else
        safe_exec "$command"
    fi
}

# Wrapper function to handle saving output if --save is present
function LOGRUN {
    local function_name="$1"
    
    if [[ -n "$SOUT" ]]; then
        # Create log file with header (append if file exists, otherwise create)
        if [[ ! -f "$LOGFILE" ]]; then
            {
                echo "=========================================="
                echo "Sonda System Information Log"
                echo "Generated: $(date '+%A, %B %d, %Y at %H:%M:%S %Z')"
                echo "Command: $function_name"
                echo "=========================================="
                echo ""
            } > "$LOGFILE"
        else
            {
                echo ""
                echo "--- Additional command: $function_name ---"
                echo ""
            } >> "$LOGFILE"
        fi
        
        # Run function and save output
        if type "$function_name" &>/dev/null; then
            "$function_name" | tee /dev/tty | sed 's/\x1b\[[0-9;]*m//g' >> "$LOGFILE"
        else
            log_error "Function not found: $function_name"
            echo "Error: Function '$function_name' not found" >&2
        fi
    else
        if type "$function_name" &>/dev/null; then
            "$function_name"
        else
            log_error "Function not found: $function_name"
            echo "Error: Function '$function_name' not found" >&2
            return 1
        fi
    fi
}



# Remember to update any changes below accordingly in the help manual under lib/man

# Parse flags first (they can appear anywhere and be combined)
VLEVEL=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--save)
            SOUT="enabled"
            log_info "Save mode enabled"
            shift
            ;;
        -nc|--no-color)
            PRETTYP="true"
            shift
            ;;
        -v|-vv|-vvv)
            # Count v's for verbosity
            VLEVEL="$1"
            log_info "Setting verbosity level: $VLEVEL"
            shift
            ;;
        -T)
            # Target flag - handle it but continue parsing flags after target
            if [[ $# -lt 2 ]]; then
                echo -e "${E} -T requires a target. Use ${CYAN}sonda --help${RT} to see available targets.${RT}" >&2
                exit 1
            fi
            TARGET="$2"
            shift 2
            # Continue parsing - flags can come after -T target
            ;;
        *)
            # Not a flag, break and process as command/target
            break
            ;;
    esac
done

# Check if TARGET was set during flag parsing
if [[ -n "${TARGET:-}" ]]; then
    # Process target that was set during flag parsing
    case "$TARGET" in
        pkgs|packages)
            log_info "Showing package information"
            LOGRUN "installed_packages"
            ;;
        cpu)
            log_info "Showing CPU information"
            LOGRUN "cpu_info"
            ;;
        gpu)
            log_info "Showing GPU information"
            LOGRUN "graphics_info"
            ;;
        disks)
            log_info "Showing disk information"
            LOGRUN "disk_storage_info"
            ;;
        memory|mem)
            log_info "Showing memory information"
            LOGRUN "memory_info"
            LOGRUN "detailed_memory_info"
            ;;
        kernel|k)
            log_info "Showing kernel information"
            LOGRUN "kernel_boot_params"
            LOGRUN "kernel_modules"
            ;;
        devices)
            log_info "Showing device information"
            LOGRUN "pci_devices"
            LOGRUN "usb_devices"
            ;;
        network|networks)
            log_info "Showing network information"
            LOGRUN "network_info"
            LOGRUN "network_connections"
            ;;
        battery)
            log_info "Showing battery information"
            LOGRUN "battery_info"
            ;;
        boot)
            log_info "Showing boot information"
            LOGRUN "boot_all"
            ;;
        security)
            log_info "Showing security information"
            LOGRUN "security_all"
            ;;
        all)
            log_info "Showing all information"
            LOGRUN "system_info"
            LOGRUN "complete_system_info"
            LOGRUN "kernel_boot_params" 
            LOGRUN "kernel_modules" 
            LOGRUN "battery_info" 
            LOGRUN "cpu_info" 
            LOGRUN "graphics_info" 
            LOGRUN "memory_info" 
            LOGRUN "detailed_memory_info" 
            LOGRUN "disk_storage_info" 
            LOGRUN "pci_devices" 
            LOGRUN "usb_devices" 
            LOGRUN "network_info" 
            LOGRUN "network_connections" 
            LOGRUN "installed_packages"
            LOGRUN "boot_all"
            LOGRUN "security_all"
            ;;
        *)
            echo -e "${E} Unknown target: $TARGET${RT}" >&2
            echo -e "${W} Use ${CYAN}sonda --help${RT} to see available targets.${RT}" >&2
            exit 1
            ;;
    esac
    # Exit after processing target (flags already processed)
    exit 0
fi

# Check if no arguments are provided (default to sys command)
if [[ $# -eq 0 ]]; then
    log_info "No arguments provided, showing default menu"
    if type banner_logo_small &>/dev/null; then
        banner_logo_small
    fi
    if [[ -f "$DEFAULT" ]]; then
        source "$DEFAULT"
    fi
    exit 0
fi

# Argument handling - New format matching lib/man
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        # Commands
        sys)
            log_info "Showing system information (sys)"
            LOGRUN "system_info"
            if [[ -f "$SYSINFO" ]]; then
                source "$SYSINFO"
            fi
            exit 0
            ;;
        
        net)
            log_info "Showing network information (net)"
            if [[ -f "$NETINFO" ]]; then
                if command -v python3 &>/dev/null; then
                    python3 "$NETINFO"
                elif command -v python &>/dev/null; then
                    python "$NETINFO"
                else
                    echo -e "${E} Python not found. Cannot show network information.${RT}" >&2
                    log_error "Python not found for network info"
                    exit 1
                fi
            else
                echo -e "${E} Network info module not found.${RT}" >&2
                log_error "Network info module not found: $NETINFO"
                exit 1
            fi
            exit 0
            ;;
        
        # Targets (require -T)
        -T)
            if [[ $# -lt 2 ]]; then
                echo -e "${E} -T requires a target. Use ${CYAN}sonda --help${RT} to see available targets.${RT}" >&2
                exit 1
            fi
            TARGET="$2"
            shift 2
            
            # Process target
            case "$TARGET" in
                pkgs|packages)
                    log_info "Showing package information"
                    LOGRUN "installed_packages"
                    ;;
                cpu)
                    log_info "Showing CPU information"
                    LOGRUN "cpu_info"
                    ;;
                gpu)
                    log_info "Showing GPU information"
                    LOGRUN "graphics_info"
                    ;;
                disks)
                    log_info "Showing disk information"
                    LOGRUN "disk_storage_info"
                    ;;
                memory|mem)
                    log_info "Showing memory information"
                    LOGRUN "memory_info"
                    LOGRUN "detailed_memory_info"
                    ;;
                kernel|k)
                    log_info "Showing kernel information"
                    LOGRUN "kernel_boot_params"
                    LOGRUN "kernel_modules"
                    ;;
                devices)
                    log_info "Showing device information"
                    LOGRUN "pci_devices"
                    LOGRUN "usb_devices"
                    ;;
                network|networks)
                    log_info "Showing network information"
                    LOGRUN "network_info"
                    LOGRUN "network_connections"
                    ;;
                battery)
                    log_info "Showing battery information"
                    LOGRUN "battery_info"
                    ;;
                boot)
                    log_info "Showing boot information"
                    LOGRUN "boot_all"
                    ;;
                security)
                    log_info "Showing security information"
                    LOGRUN "security_all"
                    ;;
                all)
                    log_info "Showing all information"
                    LOGRUN "system_info"
                    LOGRUN "complete_system_info"
                    LOGRUN "kernel_boot_params" 
                    LOGRUN "kernel_modules" 
                    LOGRUN "battery_info" 
                    LOGRUN "cpu_info" 
                    LOGRUN "graphics_info" 
                    LOGRUN "memory_info" 
                    LOGRUN "detailed_memory_info" 
                    LOGRUN "disk_storage_info" 
                    LOGRUN "pci_devices" 
                    LOGRUN "usb_devices" 
                    LOGRUN "network_info" 
                    LOGRUN "network_connections" 
                    LOGRUN "installed_packages"
                    LOGRUN "boot_all"
                    LOGRUN "security_all"
                    ;;
                *)
                    echo -e "${E} Unknown target: $TARGET${RT}" >&2
                    echo -e "${W} Use ${CYAN}sonda --help${RT} to see available targets.${RT}" >&2
                    exit 1
                    ;;
            esac
            continue
            ;;

        
        -h|--help)
            log_info "Showing scan mode help"
            if type banner_logo_small &>/dev/null; then
                banner_logo_small
            fi
            if [[ -f "${PRINT_HELP:-}" ]]; then
                bash "$PRINT_HELP" check
            else
                echo "Help system not available" >&2
            fi
            exit 0
            ;;
        
        *)
            echo -e "${E} ${RED}Unknown argument: $key${RT}" >&2
            echo -e "${W} Use ${CYAN}sonda --help${RT} to see available options.${RT}" >&2
            log_warn "Unknown argument: $key"
            exit 1
            ;;
    esac
    shift
done

# Output result based on whether --save was used
if [[ -n "$SOUT" ]]; then
    if [[ -f "$LOGFILE" ]]; then
        echo -e "${LB}${GREEN2}✔ System information gathered successfully.${RT}"
        echo -e "${DIM}   Log file saved to: ${CYAN}$LOGFILE${RT}${RT}"
        log_info "Log file created: $LOGFILE"
    else
        echo -e "${LB}${YELLOW}[!] Log file may not have been created.${RT}"
        log_warn "Log file not found after save operation: $LOGFILE"
    fi
fi

log_info "Sonda execution completed"
