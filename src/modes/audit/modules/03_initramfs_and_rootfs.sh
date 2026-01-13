#!/usr/bin/env bash
# Phase 03: initramfs and root filesystem handoff
# Purpose: Storage and mount correctness

print_phase_header

# Test case 1: initramfs warnings/failures
INITRAMFS_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "initramfs|dracut|mkinitcpio" | grep -iE "error|fail|warn" | wc -l)
if [[ $INITRAMFS_ERRORS -eq 0 ]]; then
    pass "No initramfs errors detected"
else
    warn "Found $INITRAMFS_ERRORS initramfs error(s)"
    INITRAMFS_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "initramfs|dracut|mkinitcpio" | grep -iE "error|fail|warn" | tail -20)
    echo -e "\n${YELLOW}initramfs errors:${NC}" | show_indented_details
    echo "$INITRAMFS_DETAILS" | show_indented_details
    log_detailed "=== initramfs Errors ==="
    log_detailed "$INITRAMFS_DETAILS"
fi

# Test case 2: Cryptsetup/LUKS issues
CRYPTSETUP_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "cryptsetup|luks" | grep -iE "error|fail" | wc -l)
if [[ $CRYPTSETUP_ERRORS -eq 0 ]]; then
    pass "No cryptsetup/LUKS errors"
else
    fail "Found $CRYPTSETUP_ERRORS cryptsetup/LUKS error(s)"
    CRYPTSETUP_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "cryptsetup|luks" | grep -iE "error|fail" | tail -20)
    echo -e "\n${RED}Cryptsetup/LUKS errors:${NC}" | show_indented_details
    echo "$CRYPTSETUP_DETAILS" | show_indented_details
    log_detailed "=== Cryptsetup/LUKS Errors ==="
    log_detailed "$CRYPTSETUP_DETAILS"
fi

# Test case 3: Root mount errors
ROOT_MOUNT_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "mount.*root|root.*mount|/.*mount.*fail" | wc -l)
if [[ $ROOT_MOUNT_ERRORS -eq 0 ]]; then
    pass "No root mount errors"
else
    fail "Found $ROOT_MOUNT_ERRORS root mount error(s)"
    ROOT_MOUNT_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "mount.*root|root.*mount|/.*mount.*fail" | tail -20)
    echo -e "\n${RED}Root mount errors:${NC}" | show_indented_details
    echo "$ROOT_MOUNT_DETAILS" | show_indented_details
    log_detailed "=== Root Mount Errors ==="
    log_detailed "$ROOT_MOUNT_DETAILS"
fi

# Test case 4: Filesystem check (fsck) results
FSCK_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "fsck|filesystem.*check" | grep -iE "error|fail|corrupt" | wc -l)
if [[ $FSCK_ERRORS -eq 0 ]]; then
    pass "No filesystem check errors"
else
    fail "Found $FSCK_ERRORS filesystem check error(s)"
    FSCK_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "fsck|filesystem.*check" | grep -iE "error|fail|corrupt" | tail -20)
    echo -e "\n${RED}Filesystem check errors:${NC}" | show_indented_details
    echo "$FSCK_DETAILS" | show_indented_details
    log_detailed "=== Filesystem Check Errors ==="
    log_detailed "$FSCK_DETAILS"
fi

# Test case 5: Read-only remount events
RO_REMOUNT=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "remount.*read-only|read-only.*remount|remount.*ro" | wc -l)
if [[ $RO_REMOUNT -eq 0 ]]; then
    pass "No read-only remount events"
else
    fail "Found $RO_REMOUNT read-only remount event(s) (filesystem corruption likely)"
    RO_REMOUNT_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "remount.*read-only|read-only.*remount|remount.*ro" | tail -20)
    echo -e "\n${RED}Read-only remount events:${NC}" | show_indented_details
    echo "$RO_REMOUNT_DETAILS" | show_indented_details
    log_detailed "=== Read-only Remount Events ==="
    log_detailed "$RO_REMOUNT_DETAILS"
fi

# Test case 6: Swap activation issues
SWAP_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "swap.*fail|swap.*error|swapon.*fail" | wc -l)
if [[ $SWAP_ERRORS -eq 0 ]]; then
    pass "No swap activation errors"
else
    warn "Found $SWAP_ERRORS swap activation error(s)"
    SWAP_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "swap.*fail|swap.*error|swapon.*fail" | tail -20)
    echo -e "\n${YELLOW}Swap activation errors:${NC}" | show_indented_details
    echo "$SWAP_DETAILS" | show_indented_details
    log_detailed "=== Swap Activation Errors ==="
    log_detailed "$SWAP_DETAILS"
fi

echo ""
