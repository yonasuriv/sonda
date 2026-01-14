#!/usr/bin/env bash
# Phase 05: Storage and filesystem health (post-mount)
# Purpose: I/O errors, filesystem errors, SMART health

print_phase_header

# Test case 1: I/O errors (blk_update_request, nvme timeouts)
IO_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "blk_update_request|i/o error|nvme.*timeout|disk.*timeout" | wc -l)
if [[ $IO_ERRORS -eq 0 ]]; then
    pass "No I/O errors detected"
else
    fail "Found $IO_ERRORS I/O error(s)"
    IO_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "blk_update_request|i/o error|nvme.*timeout|disk.*timeout")
    IO_DETAILS_CONSOLE=$(echo "$IO_DETAILS_FULL" | limit_for_console)
    IO_DETAILS_LOG=$(echo "$IO_DETAILS_FULL" | limit_for_log)
    echo -e "\n${RED}I/O errors:${NC}" | show_indented_details
    echo "$IO_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== I/O Errors ==="
    log_detailed "$IO_DETAILS_LOG"
fi

# Test case 2: Filesystem errors (EXT4/BTRFS/XFS)
FS_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(ext4|btrfs|xfs|filesystem).*(error|fail|corrupt|warning)" | wc -l)
if [[ $FS_ERRORS -eq 0 ]]; then
    pass "No filesystem errors detected"
else
    fail "Found $FS_ERRORS filesystem error(s)"
    FS_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(ext4|btrfs|xfs|filesystem).*(error|fail|corrupt|warning)")
    FS_DETAILS_CONSOLE=$(echo "$FS_DETAILS_FULL" | limit_for_console)
    FS_DETAILS_LOG=$(echo "$FS_DETAILS_FULL" | limit_for_log)
    echo -e "\n${RED}Filesystem errors:${NC}" | show_indented_details
    echo "$FS_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Filesystem Errors ==="
    log_detailed "$FS_DETAILS_LOG"
fi

# Test case 3: Disk health (SMART/NVMe)
if command -v smartctl >/dev/null 2>&1; then
    DISK_HEALTH_ISSUES=0
    DISK_CHECKED=0
    for disk in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [[ -b "$disk" ]]; then
            ((DISK_CHECKED++))
            if [[ "$SUDO_AVAILABLE" == true ]]; then
                SMART_STATUS=$(sudo smartctl -H "$disk" 2>/dev/null | grep -i "test result" || echo "")
                if echo "$SMART_STATUS" | grep -qi "passed"; then
                    pass "Disk health OK: $disk"
                else
                    warn "Disk health issue: $disk"
                    ((DISK_HEALTH_ISSUES++))
                    log_detailed "=== SMART Status for $disk ==="
                    log_detailed "$(sudo smartctl -a "$disk" 2>/dev/null)"
                fi
            else
                SMART_STATUS=$(smartctl -H "$disk" 2>/dev/null | grep -i "test result" || echo "")
                if echo "$SMART_STATUS" | grep -qi "passed"; then
                    pass "Disk health OK: $disk"
                elif [[ -n "$SMART_STATUS" ]]; then
                    warn "Disk health issue: $disk"
                    ((DISK_HEALTH_ISSUES++))
                    log_detailed "=== SMART Status for $disk ==="
                    log_detailed "$(smartctl -a "$disk" 2>/dev/null)"
                else
                    skip "Disk health check for $disk (sudo may be required)"
                fi
            fi
        fi
    done
    if [[ $DISK_CHECKED -eq 0 ]]; then
        skip "Disk health check (no disk devices found)"
    fi
else
    skip "Disk health check (smartctl not available - install smartmontools)"
fi

# Test case 4: Disk usage (filesystems >= 90% full)
DISK_USAGE_ISSUES=$(df -hP 2>/dev/null | awk 'NR>1 {gsub("%","",$5); if ($5+0>=90) print $0}' | wc -l)
if [[ $DISK_USAGE_ISSUES -eq 0 ]]; then
    pass "Disk usage: no filesystem >= 90% full"
else
    warn "Found $DISK_USAGE_ISSUES filesystem(s) >= 90% full"
    DISK_USAGE_DETAILS=$(df -hP 2>/dev/null | awk 'NR>1 {gsub("%","",$5); if ($5+0>=90) print $0}')
    DISK_USAGE_CONSOLE=$(echo "$DISK_USAGE_DETAILS" | limit_for_console)
    DISK_USAGE_LOG=$(echo "$DISK_USAGE_DETAILS" | limit_for_log)
    echo -e "\n${YELLOW}Filesystems >= 90% full:${NC}" | show_indented_details
    echo "$DISK_USAGE_CONSOLE" | show_indented_details
    log_detailed "=== Disk Usage (>= 90%) ==="
    log_detailed "$DISK_USAGE_LOG"
fi

# Test case 5: Current read-only mounts
if command -v findmnt >/dev/null 2>&1; then
    RO_MOUNTS=$(findmnt -rn -o TARGET,OPTIONS 2>/dev/null | awk '$2 ~ /(^|,)ro(,|$)/ {print $0}' | wc -l || echo "0")
    if [[ $RO_MOUNTS -eq 0 ]]; then
        pass "Read-only mounts: none detected"
    else
        warn "Found $RO_MOUNTS read-only mount(s) (may indicate filesystem issues)"
        RO_MOUNTS_DETAILS=$(findmnt -rn -o TARGET,OPTIONS 2>/dev/null | awk '$2 ~ /(^|,)ro(,|$)/ {print $0}')
        RO_MOUNTS_CONSOLE=$(echo "$RO_MOUNTS_DETAILS" | limit_for_console)
        RO_MOUNTS_LOG=$(echo "$RO_MOUNTS_DETAILS" | limit_for_log)
        echo -e "\n${YELLOW}Read-only mounts:${NC}" | show_indented_details
        echo "$RO_MOUNTS_CONSOLE" | show_indented_details
        log_detailed "=== Read-only Mounts ==="
        log_detailed "$RO_MOUNTS_LOG"
    fi
else
    skip "Read-only mounts check (findmnt not available)"
fi

echo ""
