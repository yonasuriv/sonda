#!/usr/bin/env bash
# Phase 11: Current system posture snapshot
# Purpose: "Right now" state, separate from boot timeline

print_phase_header

# Test case 1: Current resource usage summary
info "Current system resource status:"

# CPU usage (top processes)
if command -v top >/dev/null 2>&1; then
    CPU_TOP=$(top -bn1 2>/dev/null | head -20)
    log_detailed "=== Top CPU Processes ==="
    log_detailed "$CPU_TOP"
    pass "CPU usage snapshot collected"
else
    skip "CPU usage snapshot (top not available)"
fi

# Memory usage (already checked in Phase 10, but log current state)
MEM_INFO=$(free -h 2>/dev/null)
if [[ -n "$MEM_INFO" ]]; then
    log_detailed "=== Current Memory Status ==="
    log_detailed "$MEM_INFO"
fi

# Test case 2: Open crashed coredumps
if command -v coredumpctl >/dev/null 2>&1; then
    COREDUMPS=$(coredumpctl list 2>/dev/null | wc -l)
    if [[ $COREDUMPS -gt 0 ]]; then
        warn "Found $COREDUMPS coredump(s) available"
        COREDUMP_LIST=$(coredumpctl list --no-pager 2>/dev/null | head -20)
        log_detailed "=== Available Coredumps ==="
        log_detailed "$COREDUMP_LIST"
    else
        pass "No coredumps found"
    fi
else
    skip "Coredump check (coredumpctl not available)"
fi

# Test case 3: System health summary
SYSTEM_HEALTH=$(systemctl is-system-running 2>/dev/null || echo "unknown")
if [[ "$SYSTEM_HEALTH" == "running" ]]; then
    pass "System state: running"
elif [[ "$SYSTEM_HEALTH" == "degraded" ]]; then
    warn "System state: degraded"
elif [[ "$SYSTEM_HEALTH" == "maintenance" ]]; then
    fail "System state: maintenance mode"
else
    skip "System state check (status: $SYSTEM_HEALTH)"
fi
log_detailed "=== System State ==="
log_detailed "State: $SYSTEM_HEALTH"

# Test case 4: Active network connections summary
if command -v ss >/dev/null 2>&1; then
    NET_CONNECTIONS=$(ss -tun 2>/dev/null | wc -l)
    if [[ $NET_CONNECTIONS -gt 0 ]]; then
        pass "Network connections active: $NET_CONNECTIONS"
        log_detailed "=== Network Connections ==="
        log_detailed "$(ss -tun 2>/dev/null | head -30)"
    else
        skip "Network connections (ss command failed)"
    fi
else
    skip "Network connections (ss not available)"
fi

# Test case 5: Package manager integrity (dpkg/apt)
if command -v dpkg >/dev/null 2>&1; then
    DPKG_AUDIT=$(dpkg --audit 2>/dev/null | wc -l || echo "0")
    if [[ $DPKG_AUDIT -eq 0 ]]; then
        pass "dpkg --audit: clean"
    else
        warn "dpkg --audit reports $DPKG_AUDIT issue(s)"
        DPKG_AUDIT_DETAILS=$(dpkg --audit 2>/dev/null)
        DPKG_AUDIT_CONSOLE=$(echo "$DPKG_AUDIT_DETAILS" | limit_for_console)
        DPKG_AUDIT_LOG=$(echo "$DPKG_AUDIT_DETAILS" | limit_for_log)
        echo -e "\n${YELLOW}dpkg audit issues:${NC}" | show_indented_details
        echo "$DPKG_AUDIT_CONSOLE" | show_indented_details
        log_detailed "=== dpkg Audit ==="
        log_detailed "$DPKG_AUDIT_LOG"
    fi
    
    # Check for non-ii package states
    DPKG_BAD_STATES=$(dpkg -l 2>/dev/null | awk 'NR>5 && $1 !~ /^ii$/ {print $0}' | wc -l || echo "0")
    if [[ $DPKG_BAD_STATES -eq 0 ]]; then
        pass "dpkg package states: all ii (installed)"
    else
        warn "dpkg has $DPKG_BAD_STATES package(s) with non-ii states"
        DPKG_BAD_STATES_DETAILS=$(dpkg -l 2>/dev/null | awk 'NR>5 && $1 !~ /^ii$/ {print $0}' | head -20)
        DPKG_BAD_STATES_CONSOLE=$(echo "$DPKG_BAD_STATES_DETAILS" | limit_for_console)
        DPKG_BAD_STATES_LOG=$(echo "$DPKG_BAD_STATES_DETAILS" | limit_for_log)
        echo -e "\n${YELLOW}dpkg non-ii states:${NC}" | show_indented_details
        echo "$DPKG_BAD_STATES_CONSOLE" | show_indented_details
        log_detailed "=== dpkg Non-ii States ==="
        log_detailed "$DPKG_BAD_STATES_LOG"
    fi
else
    skip "dpkg checks (dpkg not available)"
fi

# Test case 6: apt dependency check
if command -v apt-get >/dev/null 2>&1; then
    if apt-get -s check >/dev/null 2>&1; then
        pass "apt check simulation: OK"
    else
        warn "apt check simulation indicates dependency problems"
        APT_CHECK_OUTPUT=$(apt-get -s check 2>&1)
        APT_CHECK_CONSOLE=$(echo "$APT_CHECK_OUTPUT" | limit_for_console)
        APT_CHECK_LOG=$(echo "$APT_CHECK_OUTPUT" | limit_for_log)
        echo -e "\n${YELLOW}apt check issues:${NC}" | show_indented_details
        echo "$APT_CHECK_CONSOLE" | show_indented_details
        log_detailed "=== apt Check ==="
        log_detailed "$APT_CHECK_LOG"
    fi
else
    skip "apt checks (apt-get not available)"
fi

# Test case 7: snap status
if command -v snap >/dev/null 2>&1; then
    SNAP_COUNT=$(snap list 2>/dev/null | wc -l || echo "0")
    if [[ $SNAP_COUNT -gt 0 ]]; then
        pass "snap: present ($SNAP_COUNT snap(s) installed)"
        if [[ "$AUDIT_VERBOSE" == true ]]; then
            SNAP_LIST=$(snap list 2>/dev/null)
            log_detailed "=== snap Status ==="
            log_detailed "$SNAP_LIST"
        fi
    else
        skip "snap check (snap list failed)"
    fi
else
    skip "snap check (snap not installed)"
fi

# Test case 8: flatpak status
if command -v flatpak >/dev/null 2>&1; then
    FLATPAK_COUNT=$(flatpak list 2>/dev/null | wc -l || echo "0")
    if [[ $FLATPAK_COUNT -gt 0 ]]; then
        pass "flatpak: present ($FLATPAK_COUNT flatpak(s) installed)"
        if [[ "$AUDIT_VERBOSE" == true ]]; then
            FLATPAK_REMOTES=$(flatpak remotes 2>/dev/null)
            FLATPAK_LIST=$(flatpak list 2>/dev/null)
            log_detailed "=== flatpak Status ==="
            log_detailed "Remotes:"
            log_detailed "$FLATPAK_REMOTES"
            log_detailed "Installed:"
            log_detailed "$FLATPAK_LIST"
        fi
    else
        skip "flatpak check (flatpak list failed or no flatpaks installed)"
    fi
else
    skip "flatpak check (flatpak not installed)"
fi

echo ""
