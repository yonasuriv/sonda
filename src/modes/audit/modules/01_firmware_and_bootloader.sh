#!/usr/bin/env bash
# Phase 01: Firmware and bootloader
# Purpose: Pre-kernel delays and platform anomalies

print_phase_header

# Test case 1: Secure Boot state
if [[ -f /sys/firmware/efi/efivars/SecureBoot-* ]]; then
    SECURE_BOOT=$(cat /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | od -An -tu1 | awk '{print $NF}')
    if [[ "$SECURE_BOOT" == "1" ]]; then
        pass "Secure Boot: Enabled"
        log_detailed "=== Secure Boot ==="
        log_detailed "Status: Enabled"
    else
        warn "Secure Boot: Disabled"
        log_detailed "=== Secure Boot ==="
        log_detailed "Status: Disabled"
    fi
else
    skip "Secure Boot check (not UEFI or not available)"
fi

# Test case 2: Bootloader timing (from systemd-analyze)
if command -v systemd-analyze >/dev/null 2>&1; then
    BOOTLOADER_TIME=$(systemd-analyze 2>/dev/null | grep -oP 'loader\) \K[0-9.]+' || echo "")
    if [[ -n "$BOOTLOADER_TIME" ]]; then
        BOOTLOADER_TIME_NUM=$(echo "$BOOTLOADER_TIME" | awk '{print $1}')
        if (( $(echo "$BOOTLOADER_TIME_NUM < 2" | bc -l 2>/dev/null || echo 0) )); then
            pass "Bootloader time acceptable: ${BOOTLOADER_TIME}s"
        elif (( $(echo "$BOOTLOADER_TIME_NUM < 5" | bc -l 2>/dev/null || echo 0) )); then
            warn "Bootloader time moderate: ${BOOTLOADER_TIME}s"
        else
            fail "Bootloader time slow: ${BOOTLOADER_TIME}s"
        fi
        log_detailed "=== Bootloader Timing ==="
        log_detailed "Time: ${BOOTLOADER_TIME}s"
    else
        skip "Bootloader timing (value not available)"
    fi
else
    skip "Bootloader timing (systemd-analyze not available)"
fi

# Test case 3: Firmware timing
if command -v systemd-analyze >/dev/null 2>&1; then
    FIRMWARE_TIME=$(systemd-analyze 2>/dev/null | grep -oP 'firmware\) \K[0-9.]+' || echo "")
    if [[ -n "$FIRMWARE_TIME" ]]; then
        FIRMWARE_TIME_NUM=$(echo "$FIRMWARE_TIME" | awk '{print $1}')
        if (( $(echo "$FIRMWARE_TIME_NUM < 5" | bc -l 2>/dev/null || echo 0) )); then
            pass "Firmware time acceptable: ${FIRMWARE_TIME}s"
        elif (( $(echo "$FIRMWARE_TIME_NUM < 12" | bc -l 2>/dev/null || echo 0) )); then
            warn "Firmware time moderate: ${FIRMWARE_TIME}s"
        else
            fail "Firmware time slow: ${FIRMWARE_TIME}s"
        fi
        log_detailed "=== Firmware Timing ==="
        log_detailed "Time: ${FIRMWARE_TIME}s"
    else
        skip "Firmware timing (value not available)"
    fi
else
    skip "Firmware timing (systemd-analyze not available)"
fi

# Test case 4: Bootloader errors (GRUB/systemd-boot)
BOOTLOADER_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(grub|systemd-boot|bootloader).*(error|fail)" | wc -l)
if [[ $BOOTLOADER_ERRORS -eq 0 ]]; then
    pass "No bootloader errors detected"
else
    fail "Found $BOOTLOADER_ERRORS bootloader error(s)"
    BOOTLOADER_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(grub|systemd-boot|bootloader).*(error|fail)" | tail -20)
    echo -e "\n${RED}Bootloader errors:${NC}" | show_indented_details
    echo "$BOOTLOADER_DETAILS" | show_indented_details
    log_detailed "=== Bootloader Errors ==="
    log_detailed "$BOOTLOADER_DETAILS"
fi

echo ""
