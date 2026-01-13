#!/bin/bash

# Boot Information Module
# Captures boot time, warnings, errors, and failed services

function boot_info {
    echo -e "${LB}${CYAN}[#] Boot Time Analysis ${BLUE}(systemd-analyze)${RT}${LB}"
    
    if command -v systemd-analyze >/dev/null 2>&1; then
        # Boot time summary
        echo -e "${WHITE2}Boot Time:${RT}"
        pprint "systemd-analyze time 2>/dev/null || echo 'systemd-analyze not available'"
        echo ""
        
        # Critical chain (slowest services)
        echo -e "${WHITE2}Critical Chain (Slowest Services):${RT}"
        pprint "systemd-analyze critical-chain 2>/dev/null | head -n 20 || echo 'Not available'"
        echo ""
        
        # Top services by boot time
        echo -e "${WHITE2}Top Services by Boot Time:${RT}"
        pprint "systemd-analyze blame 2>/dev/null | head -n 15 || echo 'Not available'"
    else
        echo -e "${YELLOW}[!] systemd-analyze not available${RT}"
    fi
}

function boot_warnings_errors {
    echo -e "${LB}${CYAN}[#] Boot Warnings and Errors ${BLUE}(journalctl)${RT}${LB}"
    
    if command -v journalctl >/dev/null 2>&1; then
        # Failed systemd units
        failed_count=$(systemctl --failed --no-legend 2>/dev/null | wc -l || echo "0")
        if [[ "$failed_count" -gt 0 ]]; then
            echo -e "${RED2}[!] Failed Systemd Units: $failed_count${RT}"
            pprint "systemctl --failed --no-pager 2>/dev/null | head -n 20"
            echo ""
        else
            echo -e "${GREEN2}[+] Failed Systemd Units: 0${RT}"
            echo ""
        fi
        
        # Boot errors (this boot)
        echo -e "${WHITE2}Boot Errors (This Boot):${RT}"
        pprint "journalctl -b -p err..alert --no-pager -o short-precise 2>/dev/null | head -n 20 || echo 'No errors found'"
        echo ""
        
        # Boot warnings (this boot)
        echo -e "${WHITE2}Boot Warnings (This Boot):${RT}"
        pprint "journalctl -b -p warning --no-pager -o short-precise 2>/dev/null | head -n 20 || echo 'No warnings found'"
        echo ""
        
        # Kernel errors from dmesg
        if command -v dmesg >/dev/null 2>&1; then
            echo -e "${WHITE2}Kernel Errors (dmesg):${RT}"
            pprint "dmesg -T --level=err,crit,alert,emerg 2>/dev/null | head -n 15 || echo 'No kernel errors found'"
            echo ""
            
            echo -e "${WHITE2}Kernel Warnings (dmesg):${RT}"
            pprint "dmesg -T --level=warn 2>/dev/null | head -n 15 || echo 'No kernel warnings found'"
        fi
    else
        echo -e "${YELLOW}[!] journalctl not available${RT}"
    fi
}

function boot_mode_info {
    echo -e "${LB}${CYAN}[#] Boot Mode Information${RT}${LB}"
    
    # Check if UEFI or Legacy
    if [[ -d /sys/firmware/efi ]]; then
        boot_mode="UEFI"
        echo -e "${GREEN2}[+] Boot Mode: UEFI${RT}"
    else
        boot_mode="Legacy BIOS"
        echo -e "${YELLOW2}[!] Boot Mode: Legacy BIOS${RT}"
    fi
    
    # Check Secure Boot status
    if [[ -f /sys/firmware/efi/efivars/SecureBoot-* ]]; then
        secure_boot=$(cat /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | od -An -t u1 | awk '{print $NF}')
        if [[ "$secure_boot" == "1" ]]; then
            echo -e "${GREEN2}[+] Secure Boot: Enabled${RT}"
        else
            echo -e "${YELLOW2}[!] Secure Boot: Disabled${RT}"
        fi
    else
        echo -e "${DIM}Secure Boot: Not available (Legacy BIOS or not accessible)${RT}"
    fi
    
    # Last boot time
    if command -v who >/dev/null 2>&1; then
        last_boot=$(who -b 2>/dev/null | awk '{print $3, $4}' || echo "Unknown")
        echo -e "${WHITE2}Last Boot Time:${RT} $last_boot"
    fi
}

# Main function - displays all boot information
function boot_all {
    boot_mode_info
    echo ""
    boot_info
    echo ""
    boot_warnings_errors
}
