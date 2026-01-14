# 7. Disk and Storage Information
function disk_storage_info {
    # df -h shows disk usage and mounted filesystems in a human-readable format.
    echo -e "${LB}${CYAN}[#] Disk and Storage Information ${BLUE}(df -h)${RT}${LB}"
    df -h

    # lsblk shows the block devices and their mount points.
    echo -e "${LB}${CYAN}[#] Block Devices ${BLUE}(lsblk)${RT}${LB}"
    pprint "lsblk"

    # fdisk -l shows detailed partition and disk information (requires sudo)

    if sudo -n true 2>/dev/null; then
        echo -e "${LB}${CYAN}[#] Partition and Disk Information ${BLUE}(fdisk -l)${RT}${LB}"
        pprint "sudo fdisk -l"
    else
        print_sudo_skipped "Partition and Disk Information (fdisk -l)"
    fi
}

# Per-mount usage table with filesystem type, encryption, and inodes
function disk_detailed_mounts {
    echo -e "${LB}${CYAN}[#] Per-Mount Usage Details${RT}${LB}"
    
    if command -v df >/dev/null 2>&1 && command -v lsblk >/dev/null 2>&1; then
        echo -e "${WHITE2}Mount Point | Filesystem | Type | Used | Available | Use% | Inodes Used%${RT}"
        echo -e "${DIM}----------------------------------------------------------------------------${RT}"
        
        # Get mount information
        df -hT | awk 'NR>1 {print $7, $1, $2, $3, $4, $5}' | while read -r mountpoint device fstype used avail pct; do
            # Skip special filesystems
            if [[ "$mountpoint" == "tmpfs" ]] || [[ "$mountpoint" == "devtmpfs" ]] || [[ "$mountpoint" == "sysfs" ]] || [[ "$mountpoint" == "proc" ]]; then
                continue
            fi
            
            # Get inode usage
            inode_pct=$(df -i "$mountpoint" 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A")
            
            # Check if encrypted (LUKS)
            is_encrypted=""
            if command -v lsblk >/dev/null 2>&1; then
                device_name=$(basename "$device")
                if lsblk -o TYPE,NAME 2>/dev/null | grep -q "crypt.*$device_name"; then
                    is_encrypted="${GREEN2}[ENCRYPTED]${RT}"
                fi
            fi
            
            # Color code based on usage
            pct_num=$(echo "$pct" | sed 's/%//')
            if [[ "$pct_num" -ge 90 ]]; then
                color="$RED2"
            elif [[ "$pct_num" -ge 75 ]]; then
                color="$YELLOW2"
            else
                color="$GREEN2"
            fi
            
            printf "%-15s | %-10s | %-8s | %-8s | %-8s | %s%5s%s | %s\n" \
                "$mountpoint" "$device" "$fstype" "$used" "$avail" "$color" "$pct" "$RT" "$inode_pct $is_encrypted"
        done
        echo ""
        
        # Show filesystems >= 90% full
        echo -e "${WHITE2}Filesystems >= 90% full:${RT}"
        df -h | awk 'NR>1 {gsub("%","",$5); if ($5+0>=90) print $6 " (" $5 "%)"}' | while read -r line; do
            if [[ -n "$line" ]]; then
                echo -e "  ${RED2}[!]${RT} $line"
            fi
        done
        
        # Show inodes >= 90% full
        echo -e "${WHITE2}Inodes >= 90% full:${RT}"
        df -i | awk 'NR>1 {gsub("%","",$5); if ($5+0>=90) print $6 " (" $5 "%)"}' | while read -r line; do
            if [[ -n "$line" ]]; then
                echo -e "  ${RED2}[!]${RT} $line"
            fi
        done
    else
        echo -e "${YELLOW}[!] df or lsblk not available${RT}"
    fi
}
