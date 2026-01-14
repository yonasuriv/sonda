#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

banner_logo_small() {
    local version_text="SONDA v$(cat ${VERSION_FILE:-VERSION} 2>/dev/null || echo "unknown")"
    if command -v lolcat >/dev/null 2>&1; then
        echo -e "${LB}    $version_text" | lolcat 2>/dev/null || echo -e "${LB}${CYAN}    $version_text${RT}"
    else
        echo -e "${LB}${CYAN}    $version_text${RT}"
    fi
}

banner_logo_big() {
    local assets_dir="${ASSETS_DIR:-${ASSETS:-}}"
    if command -v lolcat >/dev/null 2>&1; then
        if [[ -n "$assets_dir" ]] && [[ -f "$assets_dir/art/sonda_sysnet_1" ]]; then
            bash "$assets_dir/art/sonda_sysnet_1" | lolcat 2>/dev/null || bash "$assets_dir/art/sonda_sysnet_1"
        fi
    else
        if [[ -n "$assets_dir" ]] && [[ -f "$assets_dir/art/sonda_sysnet_1" ]]; then
            bash "$assets_dir/art/sonda_sysnet_1"
        fi
    fi
}

banner_terminal() {
    # Use enhanced network status if get_network_status function is available
    if command -v curl >/dev/null 2>&1 && type get_network_status >/dev/null 2>&1; then
        net_status=$(get_network_status)
    else
        net_status=$(ping -c 1 1.1.1.1 > /dev/null 2>&1 && echo -e "${NKBRGREEN}[NETWORK CONNECTED]${RT}" || echo -e "${NKBRRED}[NO INTERNET]${RT}")
    fi

    # Get number of packages available to be upgraded
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | wc -l)

    # Get number of security updates available
    SECURITY_UPDATES=$(apt-get -s upgrade 2>/dev/null | grep "^Inst" | grep -i security | wc -l)

    # Format upgradable packages with singular/plural
    if [ "$UPGRADABLE" -gt 1 ]; then
        upgradable_formatted="$UPGRADABLE packages"
    elif [ "$UPGRADABLE" -eq 1 ]; then
        upgradable_formatted="$UPGRADABLE package"
    else
        upgradable_formatted="no packages"
    fi

    # Format security updates with singular/plural
    if [ "$SECURITY_UPDATES" -gt 1 ]; then
        security_updates_formatted="$SECURITY_UPDATES security updates"
    elif [ "$SECURITY_UPDATES" -eq 1 ]; then
        security_updates_formatted="$SECURITY_UPDATES security update"
    else
        security_updates_formatted="no security updates"
    fi

    # Calculate uptime if not already set
    if [[ -z "${uptime_days:-}" ]]; then
        uptime_seconds=$(awk '{print $1}' /proc/uptime 2>/dev/null || echo "0")
        uptime_days=$(awk -v seconds="$uptime_seconds" 'BEGIN {print int(seconds/86400)}' 2>/dev/null || echo "0")
    fi

    # REBOOT
    if [[ "${uptime_days:-0}" -ge 6 ]]; then
        restart_recommended=$(echo -e "${RED2}[RESTART RECOMMENDED]${RT}")
    elif [[ "${uptime_days:-0}" -gt 3 ]]; then
        restart_recommended=$(echo -e "${YELLOW2}[RESTART RECOMMENDED]${RT}")
    else
        restart_recommended=""
    fi

    # Calculate DAYS if not already set (for update recommendation)
    if [[ -z "${DAYS:-}" ]]; then
        # Try to get LAST_UPDATE_DATE from apt history
        LAST_UPDATE_DATE=$(grep -E "Start-Date:" /var/log/apt/history.log 2>/dev/null | tail -1 | sed 's/Start-Date: //' || echo "Unavailable")
        
        if [[ -n "${LAST_UPDATE_DATE:-}" ]] && [[ "$LAST_UPDATE_DATE" != "Unavailable" ]]; then
            CURRENT_TIMESTAMP=$(date +%s)
            LAST_UPDATE_TIMESTAMP=$(date -d "$LAST_UPDATE_DATE" +%s 2>/dev/null || echo "0")
            if [[ "$LAST_UPDATE_TIMESTAMP" != "0" ]] && [[ "$LAST_UPDATE_TIMESTAMP" =~ ^[0-9]+$ ]]; then
                TIME_DIFF=$((CURRENT_TIMESTAMP - LAST_UPDATE_TIMESTAMP))
                DAYS=$((TIME_DIFF / 86400))
            else
                DAYS=0
            fi
        else
            DAYS=0
        fi
    fi

    # UPDATE
    if [[ "${DAYS:-0}" -ge 15 ]]; then
        update_recommended=$(echo -e "${RED2}[UPDATE RECOMMENDED] ${RT}")
    elif [[ "${DAYS:-0}" -ge 5 ]] && [[ "${DAYS:-0}" -le 14 ]]; then
        update_recommended=$(echo -e "${YELLOW2}[UPDATE RECOMMENDED] ${RT}")
    else
        update_recommended=""
    fi

    # Calculate total updates (upgradable + security)
    total_pkg_update_count=$(($UPGRADABLE + $SECURITY_UPDATES))

    if [[ "$total_pkg_update_count" -eq 0 ]]; then
        sys_status="${NKBRBLUE}[SYSTEM UP TO DATE]${RT}${RT}"
    else
        sys_status="${NKBRCYAN}[UPDATE AVAILABLE]${RT}${DIM} ($upgradable_formatted, $security_updates_formatted) ${DIM}${RT}"
    fi 

    #####################################################################################
    #
    # Final Banner
    #
    #####################################################################################

    local version_text="[DATA SONDA $(cat ${VERSION_FILE:-VERSION} 2>/dev/null || echo "unknown")]"
    if command -v lolcat >/dev/null 2>&1; then
        printf "${LB}$(echo -e "$version_text" | lolcat -f 2>/dev/null || echo -e "${CYAN}$version_text${RT}")" && echo -e " $net_status $sys_status $restart_recommended $update_recommended${LB}"
    else
        printf "${LB}${CYAN}$version_text${RT}" && echo -e " $net_status $sys_status $restart_recommended $update_recommended${LB}"
    fi
}

# Export functions so they can be called individually
export -f banner_logo_small
export -f banner_logo_big
export -f banner_terminal
