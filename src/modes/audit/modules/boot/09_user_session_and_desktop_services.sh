#!/usr/bin/env bash
# Phase 09: User session services and desktop environment stability
# Purpose: After login reliability

print_phase_header

# Test case 1: User systemd instance failures
USER_FAILED=$($SYSTEMCTL_USER_FAILED_BASE 2>/dev/null | wc -l)
if [[ $USER_FAILED -eq 0 ]]; then
    pass "No failed user session services"
else
    fail "Found $USER_FAILED failed user service(s)"
    USER_FAILED_LIST=$($SYSTEMCTL_USER_FAILED_BASE 2>/dev/null)
    echo -e "\n${RED}Failed user services:${NC}" | show_indented_details
    echo "$USER_FAILED_LIST" | show_indented_details
    log_detailed "=== Failed User Services ==="
    log_detailed "$USER_FAILED_LIST"
fi

# Test case 2: Desktop environment crashes
DE_CRASHES=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "(crash|segfault|SIGSEGV|SIGABRT|abort)" | wc -l)
if [[ $DE_CRASHES -eq 0 ]]; then
    pass "No desktop environment crashes detected"
else
    fail "Found $DE_CRASHES desktop environment crash(es)"
    DE_CRASH_DETAILS_FULL=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "(crash|segfault|SIGSEGV|SIGABRT|abort)")
    DE_CRASH_DETAILS_CONSOLE=$(echo "$DE_CRASH_DETAILS_FULL" | limit_for_console)
    DE_CRASH_DETAILS_LOG=$(echo "$DE_CRASH_DETAILS_FULL" | limit_for_log)
    echo -e "\n${RED}Desktop environment crashes:${NC}" | show_indented_details
    echo "$DE_CRASH_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Desktop Environment Crashes ==="
    log_detailed "$DE_CRASH_DETAILS_LOG"
fi

# Test case 3: GNOME Shell extension status
if command -v gnome-extensions >/dev/null 2>&1; then
    GNOME_EXT_TOTAL=$(gnome-extensions list 2>/dev/null | wc -l || echo "0")
    GNOME_EXT_ENABLED=$(gnome-extensions list --enabled 2>/dev/null | wc -l || echo "0")
    if [[ $GNOME_EXT_TOTAL -gt 0 ]]; then
        pass "GNOME extensions: total=$GNOME_EXT_TOTAL, enabled=$GNOME_EXT_ENABLED"
        log_detailed "=== GNOME Extensions ==="
        log_detailed "Total: $GNOME_EXT_TOTAL"
        log_detailed "Enabled: $GNOME_EXT_ENABLED"
        if [[ "$AUDIT_VERBOSE" == true ]]; then
            GNOME_EXT_LIST=$(gnome-extensions list 2>/dev/null)
            GNOME_EXT_ENABLED_LIST=$(gnome-extensions list --enabled 2>/dev/null)
            GNOME_EXT_DISABLED_LIST=$(gnome-extensions list --disabled 2>/dev/null)
            log_detailed "All extensions:"
            log_detailed "$GNOME_EXT_LIST"
            log_detailed "Enabled:"
            log_detailed "$GNOME_EXT_ENABLED_LIST"
            log_detailed "Disabled:"
            log_detailed "$GNOME_EXT_DISABLED_LIST"
        fi
    else
        skip "GNOME extensions check (no extensions found)"
    fi
else
    skip "GNOME extensions check (gnome-extensions CLI not found)"
fi

# Test case 3b: GNOME Shell extension crashes
GNOME_EXT_CRASHES=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "gnome-shell.*extension.*crash|extension.*error" | wc -l)
if [[ $GNOME_EXT_CRASHES -eq 0 ]]; then
    pass "No GNOME Shell extension crashes detected"
else
    warn "Found $GNOME_EXT_CRASHES GNOME Shell extension crash(es)"
    GNOME_EXT_DETAILS_FULL=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "gnome-shell.*extension.*crash|extension.*error")
    GNOME_EXT_DETAILS_CONSOLE=$(echo "$GNOME_EXT_DETAILS_FULL" | limit_for_console)
    GNOME_EXT_DETAILS_LOG=$(echo "$GNOME_EXT_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}GNOME Shell extension crashes:${NC}" | show_indented_details
    echo "$GNOME_EXT_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== GNOME Shell Extension Crashes ==="
    log_detailed "$GNOME_EXT_DETAILS_LOG"
fi

# Test case 4: Portal service issues (xdg-desktop-portal)
PORTAL_ERRORS=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "portal.*(error|fail|crash)" | wc -l)
if [[ $PORTAL_ERRORS -eq 0 ]]; then
    pass "No portal service errors"
else
    warn "Found $PORTAL_ERRORS portal service error(s)"
    PORTAL_DETAILS_FULL=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "portal.*(error|fail|crash)")
    PORTAL_DETAILS_CONSOLE=$(echo "$PORTAL_DETAILS_FULL" | limit_for_console)
    PORTAL_DETAILS_LOG=$(echo "$PORTAL_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}Portal service errors:${NC}" | show_indented_details
    echo "$PORTAL_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Portal Service Errors ==="
    log_detailed "$PORTAL_DETAILS_LOG"
fi

# Test case 5: Keyring issues
KEYRING_ERRORS=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "keyring.*(error|fail|unlock)" | wc -l)
if [[ $KEYRING_ERRORS -eq 0 ]]; then
    pass "No keyring errors"
else
    warn "Found $KEYRING_ERRORS keyring error(s)"
    KEYRING_DETAILS_FULL=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "keyring.*(error|fail|unlock)")
    KEYRING_DETAILS_CONSOLE=$(echo "$KEYRING_DETAILS_FULL" | limit_for_console)
    KEYRING_DETAILS_LOG=$(echo "$KEYRING_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}Keyring errors:${NC}" | show_indented_details
    echo "$KEYRING_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Keyring Errors ==="
    log_detailed "$KEYRING_DETAILS_LOG"
fi

# Test case 6: DBus failures
DBUS_ERRORS=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "dbus.*(error|fail|rejected)" | wc -l)
if [[ $DBUS_ERRORS -eq 0 ]]; then
    pass "No DBus errors"
else
    warn "Found $DBUS_ERRORS DBus error(s)"
    DBUS_DETAILS_FULL=$($JOURNALCTL_USER_BASE 2>/dev/null | grep -iE "dbus.*(error|fail|rejected)")
    DBUS_DETAILS_CONSOLE=$(echo "$DBUS_DETAILS_FULL" | limit_for_console)
    DBUS_DETAILS_LOG=$(echo "$DBUS_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}DBus errors:${NC}" | show_indented_details
    echo "$DBUS_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== DBus Errors ==="
    log_detailed "$DBUS_DETAILS_LOG"
fi

echo ""
