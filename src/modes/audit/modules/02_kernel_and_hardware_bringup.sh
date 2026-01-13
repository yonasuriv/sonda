#!/usr/bin/env bash
# Phase 02: Kernel early boot and hardware bring-up
# Purpose: Hardware errors before userspace hides them

print_phase_header

# Test case 1: Hardware errors (MCE, AER, PCIe, NVMe, IOMMU)
if [[ "$SUDO_AVAILABLE" == true ]]; then
    HARDWARE_ERRORS=$($SUDO_DMESG_BASE 2>/dev/null | grep -iE "(mce|aer|pcie|nvme|iommu|machine check|hardware error|uncorrectable|corrected error)" | wc -l 2>/dev/null || echo "0")
    HARDWARE_ERRORS=$(echo "$HARDWARE_ERRORS" | tr -d '[:space:]')
    if [[ -n "$HARDWARE_ERRORS" ]] && [[ "$HARDWARE_ERRORS" =~ ^[0-9]+$ ]] && [[ $HARDWARE_ERRORS -eq 0 ]]; then
        pass "No hardware errors detected"
    else
        fail "Found $HARDWARE_ERRORS hardware error(s)"
        # Get full details for logs, then limit for console display
        HW_DETAILS_FULL=$($SUDO_DMESG_BASE 2>/dev/null | grep -iE "(mce|aer|pcie|nvme|iommu|machine check|hardware error|uncorrectable|corrected error)")
        HW_DETAILS_CONSOLE=$(echo "$HW_DETAILS_FULL" | limit_for_console)
        HW_DETAILS_LOG=$(echo "$HW_DETAILS_FULL" | limit_for_log)
        echo -e "\n${RED}Hardware errors:${NC}" | show_indented_details
        echo "$HW_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== Hardware Errors ==="
        log_detailed "$HW_DETAILS_LOG"
    fi
else
    HARDWARE_ERRORS=$($DMESG_BASE 2>/dev/null | grep -iE "(mce|aer|pcie|nvme|iommu|machine check|hardware error|uncorrectable|corrected error)" | wc -l 2>/dev/null || echo "0")
    HARDWARE_ERRORS=$(echo "$HARDWARE_ERRORS" | tr -d '[:space:]')
    if [[ -n "$HARDWARE_ERRORS" ]] && [[ "$HARDWARE_ERRORS" =~ ^[0-9]+$ ]] && [[ $HARDWARE_ERRORS -eq 0 ]]; then
        skip "Hardware error check (sudo required for complete dmesg access)"
    else
        fail "Found $HARDWARE_ERRORS hardware error(s) (limited access)"
        HW_DETAILS_FULL=$($DMESG_BASE 2>/dev/null | grep -iE "(mce|aer|pcie|nvme|iommu|machine check|hardware error|uncorrectable|corrected error)")
        HW_DETAILS_CONSOLE=$(echo "$HW_DETAILS_FULL" | limit_for_console)
        HW_DETAILS_LOG=$(echo "$HW_DETAILS_FULL" | limit_for_log)
        echo -e "\n${RED}Hardware errors:${NC}" | show_indented_details
        echo "$HW_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== Hardware Errors (Limited Access) ==="
        log_detailed "$HW_DETAILS_LOG"
    fi
fi

# Test case 2: Kernel errors
if [[ "$SUDO_AVAILABLE" == true ]]; then
    KERNEL_ERRORS=$($SUDO_DMESG_ERR 2>/dev/null | wc -l 2>/dev/null || echo "0")
    KERNEL_ERRORS=$(echo "$KERNEL_ERRORS" | tr -d '[:space:]')
    if [[ -n "$KERNEL_ERRORS" ]] && [[ "$KERNEL_ERRORS" =~ ^[0-9]+$ ]] && [[ $KERNEL_ERRORS -eq 0 ]]; then
        pass "No kernel errors"
    else
        fail "Found $KERNEL_ERRORS kernel error(s)"
        KERNEL_DETAILS_FULL=$($SUDO_DMESG_ERR 2>/dev/null)
        KERNEL_DETAILS_CONSOLE=$(echo "$KERNEL_DETAILS_FULL" | limit_for_console)
        KERNEL_DETAILS_LOG=$(echo "$KERNEL_DETAILS_FULL" | limit_for_log)
        echo -e "\n${RED}Kernel errors:${NC}" | show_indented_details
        echo "$KERNEL_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== Kernel Errors ==="
        log_detailed "$KERNEL_DETAILS_LOG"
    fi
else
    KERNEL_ERRORS=$($DMESG_ERR 2>/dev/null | wc -l 2>/dev/null || echo "0")
    KERNEL_ERRORS=$(echo "$KERNEL_ERRORS" | tr -d '[:space:]')
    if [[ -n "$KERNEL_ERRORS" ]] && [[ "$KERNEL_ERRORS" =~ ^[0-9]+$ ]] && [[ $KERNEL_ERRORS -eq 0 ]]; then
        skip "Kernel error check (sudo required for full access)"
    else
        fail "Found $KERNEL_ERRORS kernel error(s) (limited access)"
        KERNEL_DETAILS_FULL=$($DMESG_ERR 2>/dev/null)
        KERNEL_DETAILS_CONSOLE=$(echo "$KERNEL_DETAILS_FULL" | limit_for_console)
        KERNEL_DETAILS_LOG=$(echo "$KERNEL_DETAILS_FULL" | limit_for_log)
        echo -e "\n${RED}Kernel errors:${NC}" | show_indented_details
        echo "$KERNEL_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== Kernel Errors (Limited Access) ==="
        log_detailed "$KERNEL_DETAILS_LOG"
    fi
fi

# Test case 3: Kernel warnings
if [[ "$SUDO_AVAILABLE" == true ]]; then
    KERNEL_WARNINGS=$($SUDO_DMESG_WARN 2>/dev/null | wc -l 2>/dev/null || echo "0")
    KERNEL_WARNINGS=$(echo "$KERNEL_WARNINGS" | tr -d '[:space:]')
    if [[ -n "$KERNEL_WARNINGS" ]] && [[ "$KERNEL_WARNINGS" =~ ^[0-9]+$ ]] && [[ $KERNEL_WARNINGS -eq 0 ]]; then
        pass "No kernel warnings"
    else
        warn "Found $KERNEL_WARNINGS kernel warning(s)"
        KERNEL_WARN_DETAILS_FULL=$($SUDO_DMESG_WARN 2>/dev/null)
        KERNEL_WARN_DETAILS_CONSOLE=$(echo "$KERNEL_WARN_DETAILS_FULL" | limit_for_console)
        KERNEL_WARN_DETAILS_LOG=$(echo "$KERNEL_WARN_DETAILS_FULL" | limit_for_log)
        echo -e "\n${YELLOW}Kernel warnings:${NC}" | show_indented_details
        echo "$KERNEL_WARN_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== Kernel Warnings ==="
        log_detailed "$KERNEL_WARN_DETAILS_LOG"
    fi
else
    skip "Kernel warnings check (sudo required for full access)"
fi

# Test case 4: Kernel module load failures
MODULE_FAILURES=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "modprobe.*fail|insmod.*fail|module.*fail.*load" | wc -l 2>/dev/null || echo "0")
MODULE_FAILURES=$(echo "$MODULE_FAILURES" | tr -d '[:space:]')
if [[ -n "$MODULE_FAILURES" ]] && [[ "$MODULE_FAILURES" =~ ^[0-9]+$ ]] && [[ $MODULE_FAILURES -eq 0 ]]; then
    pass "No kernel module load failures"
else
    fail "Found $MODULE_FAILURES kernel module load failure(s)"
    MODULE_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "modprobe.*fail|insmod.*fail|module.*fail.*load")
    MODULE_DETAILS_CONSOLE=$(echo "$MODULE_DETAILS_FULL" | limit_for_console)
    MODULE_DETAILS_LOG=$(echo "$MODULE_DETAILS_FULL" | limit_for_log)
    echo -e "\n${RED}Module load failures:${NC}" | show_indented_details
    echo "$MODULE_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Module Load Failures ==="
    log_detailed "$MODULE_DETAILS_LOG"
fi

# Test case 5: GPU driver initialization
if [[ "$SUDO_AVAILABLE" == true ]]; then
    GPU_INIT_ERRORS=$($SUDO_DMESG_BASE 2>/dev/null | grep -iE "(gpu|drm|radeon|nvidia|intel|amdgpu).*(init|probe|fail|error)" | wc -l 2>/dev/null || echo "0")
    GPU_INIT_ERRORS=$(echo "$GPU_INIT_ERRORS" | tr -d '[:space:]')
    if [[ -n "$GPU_INIT_ERRORS" ]] && [[ "$GPU_INIT_ERRORS" =~ ^[0-9]+$ ]] && [[ $GPU_INIT_ERRORS -eq 0 ]]; then
        pass "GPU driver initialization successful"
    else
        fail "Found $GPU_INIT_ERRORS GPU driver initialization issue(s)"
        GPU_INIT_DETAILS_FULL=$($SUDO_DMESG_BASE 2>/dev/null | grep -iE "(gpu|drm|radeon|nvidia|intel|amdgpu).*(init|probe|fail|error)")
        GPU_INIT_DETAILS_CONSOLE=$(echo "$GPU_INIT_DETAILS_FULL" | limit_for_console)
        GPU_INIT_DETAILS_LOG=$(echo "$GPU_INIT_DETAILS_FULL" | limit_for_log)
        echo -e "\n${RED}GPU driver init issues:${NC}" | show_indented_details
        echo "$GPU_INIT_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== GPU Driver Init Issues ==="
        log_detailed "$GPU_INIT_DETAILS_LOG"
    fi
else
    skip "GPU driver init check (sudo required)"
fi

# Test case 6: ACPI/Firmware issues
ACPI_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "acpi.*error|firmware.*bug|acpi.*fail" | wc -l 2>/dev/null || echo "0")
ACPI_ERRORS=$(echo "$ACPI_ERRORS" | tr -d '[:space:]')
if [[ -n "$ACPI_ERRORS" ]] && [[ "$ACPI_ERRORS" =~ ^[0-9]+$ ]] && [[ $ACPI_ERRORS -eq 0 ]]; then
    pass "No ACPI/firmware errors detected"
else
    warn "Found $ACPI_ERRORS ACPI/firmware error(s)"
    ACPI_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "acpi.*error|firmware.*bug|acpi.*fail")
    ACPI_DETAILS_CONSOLE=$(echo "$ACPI_DETAILS_FULL" | limit_for_console)
    ACPI_DETAILS_LOG=$(echo "$ACPI_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}ACPI/Firmware errors:${NC}" | show_indented_details
    echo "$ACPI_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== ACPI/Firmware Errors ==="
    log_detailed "$ACPI_DETAILS_LOG"
fi

# Test case 7: Kernel taint status
if [[ -r /proc/sys/kernel/tainted ]]; then
    TAINT_VALUE=$(cat /proc/sys/kernel/tainted 2>/dev/null || echo "0")
    if [[ "$TAINT_VALUE" == "0" ]]; then
        pass "Kernel taint: 0 (clean)"
    else
        warn "Kernel tainted: $TAINT_VALUE (non-zero - indicates unsupported modules or hardware issues)"
        log_detailed "=== Kernel Taint ==="
        log_detailed "Taint value: $TAINT_VALUE"
        log_detailed "Note: Non-zero taint indicates kernel loaded unsupported modules or encountered hardware issues"
    fi
else
    skip "Kernel taint check (/proc/sys/kernel/tainted not readable)"
fi

# Test case 8: udev rules verification
if command -v udevadm >/dev/null 2>&1; then
    if udevadm help 2>/dev/null | grep -q "verify"; then
        UDEV_VERIFY_OUTPUT=$(udevadm verify /etc/udev/rules.d 2>&1)
        UDEV_VERIFY_RC=$?
        if [[ $UDEV_VERIFY_RC -eq 0 ]]; then
            pass "udev rules verification: OK"
        else
            warn "udev rules verification found issues in /etc/udev/rules.d"
            UDEV_VERIFY_CONSOLE=$(echo "$UDEV_VERIFY_OUTPUT" | limit_for_console)
            UDEV_VERIFY_LOG=$(echo "$UDEV_VERIFY_OUTPUT" | limit_for_log)
            echo -e "\n${YELLOW}udev rules issues:${NC}" | show_indented_details
            echo "$UDEV_VERIFY_CONSOLE" | show_indented_details
            log_detailed "=== udev Rules Verification ==="
            log_detailed "$UDEV_VERIFY_LOG"
        fi
    else
        skip "udev rules verification (unsupported on this udevadm build)"
    fi
    
    # Check for udev errors in journal
    UDEV_JOURNAL_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "udev|systemd-udevd" | grep -iE "error|fail" | wc -l 2>/dev/null || echo "0")
    UDEV_JOURNAL_ERRORS=$(echo "$UDEV_JOURNAL_ERRORS" | tr -d '[:space:]')
    if [[ -n "$UDEV_JOURNAL_ERRORS" ]] && [[ "$UDEV_JOURNAL_ERRORS" =~ ^[0-9]+$ ]] && [[ $UDEV_JOURNAL_ERRORS -eq 0 ]]; then
        pass "No udev errors in journal"
    else
        warn "Found $UDEV_JOURNAL_ERRORS udev error(s) in journal"
        UDEV_JOURNAL_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "udev|systemd-udevd" | grep -iE "error|fail")
        UDEV_JOURNAL_DETAILS_CONSOLE=$(echo "$UDEV_JOURNAL_DETAILS_FULL" | limit_for_console)
        UDEV_JOURNAL_DETAILS_LOG=$(echo "$UDEV_JOURNAL_DETAILS_FULL" | limit_for_log)
        echo -e "\n${YELLOW}udev journal errors:${NC}" | show_indented_details
        echo "$UDEV_JOURNAL_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== udev Journal Errors ==="
        log_detailed "$UDEV_JOURNAL_DETAILS_LOG"
    fi
else
    skip "udev checks (udevadm not found)"
fi

echo ""
