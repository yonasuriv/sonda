#!/usr/bin/env bash
# Phase 10: Resource pressure and stability signals
# Purpose: Catch "silent killers" that explain random crashes

print_phase_header

# Test case 1: OOM (Out of Memory) events
OOM_EVENTS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "out of memory|oom|killed process" | wc -l)
if [[ $OOM_EVENTS -eq 0 ]]; then
    pass "No out-of-memory events"
else
    fail "Found $OOM_EVENTS out-of-memory event(s)"
    OOM_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "out of memory|oom|killed process")
    OOM_DETAILS_CONSOLE=$(echo "$OOM_DETAILS_FULL" | limit_for_console)
    OOM_DETAILS_LOG=$(echo "$OOM_DETAILS_FULL" | limit_for_log)
    echo -e "\n${RED}OOM events:${NC}" | show_indented_details
    echo "$OOM_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== OOM Events ==="
    log_detailed "$OOM_DETAILS_LOG"
fi

# Test case 2: Memory pressure
MEM_INFO=$(free -h 2>/dev/null)
MEM_USAGE=$(free 2>/dev/null | grep Mem | awk '{printf "%.1f", $3/$2 * 100}' || echo "0")
if [[ "$MEM_USAGE" != "0" ]]; then
    if (( $(echo "$MEM_USAGE > 90" | bc -l 2>/dev/null || echo 0) )); then
        warn "High memory usage: ${MEM_USAGE}%"
    else
        pass "Memory usage acceptable: ${MEM_USAGE}%"
    fi
    log_detailed "=== Memory Info ==="
    log_detailed "$MEM_INFO"
else
    skip "Memory usage check (free command failed)"
fi

# Test case 3: Thermal throttling
THERMAL_THROTTLE=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "thermal.*throttle|cpu.*throttle|temperature.*high" | wc -l)
if [[ $THERMAL_THROTTLE -eq 0 ]]; then
    pass "No thermal throttling events"
else
    warn "Found $THERMAL_THROTTLE thermal throttling event(s)"
    THERMAL_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "thermal.*throttle|cpu.*throttle|temperature.*high")
    THERMAL_DETAILS_CONSOLE=$(echo "$THERMAL_DETAILS_FULL" | limit_for_console)
    THERMAL_DETAILS_LOG=$(echo "$THERMAL_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}Thermal throttling:${NC}" | show_indented_details
    echo "$THERMAL_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Thermal Throttling ==="
    log_detailed "$THERMAL_DETAILS_LOG"
fi

# Test case 4: Power/ACPI anomalies
ACPI_ISSUES=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(acpi|power|suspend|resume).*(error|fail|warn)" | wc -l)
if [[ $ACPI_ISSUES -eq 0 ]]; then
    pass "No ACPI/power management issues"
else
    warn "Found $ACPI_ISSUES ACPI/power management issue(s)"
    ACPI_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(acpi|power|suspend|resume).*(error|fail|warn)")
    ACPI_DETAILS_CONSOLE=$(echo "$ACPI_DETAILS_FULL" | limit_for_console)
    ACPI_DETAILS_LOG=$(echo "$ACPI_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}ACPI/Power issues:${NC}" | show_indented_details
    echo "$ACPI_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== ACPI/Power Issues ==="
    log_detailed "$ACPI_DETAILS_LOG"
fi

# Test case 5: Disk pressure (full root)
DISK_USAGE=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")
if [[ "$DISK_USAGE" != "0" ]]; then
    if [[ $DISK_USAGE -gt 90 ]]; then
        fail "Root filesystem nearly full: ${DISK_USAGE}%"
    elif [[ $DISK_USAGE -gt 80 ]]; then
        warn "Root filesystem usage high: ${DISK_USAGE}%"
    else
        pass "Root filesystem usage acceptable: ${DISK_USAGE}%"
    fi
    log_detailed "=== Disk Usage ==="
    log_detailed "$(df -h)"
else
    skip "Disk usage check (df command failed)"
fi

# Test case 6: Inode exhaustion
INODE_USAGE=$(df -i / 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo "0")
if [[ "$INODE_USAGE" != "0" ]]; then
    if [[ $INODE_USAGE -gt 90 ]]; then
        fail "Inode usage critical: ${INODE_USAGE}%"
    elif [[ $INODE_USAGE -gt 80 ]]; then
        warn "Inode usage high: ${INODE_USAGE}%"
    else
        pass "Inode usage acceptable: ${INODE_USAGE}%"
    fi
else
    skip "Inode usage check (df -i failed)"
fi

# Test case 7: Load average
LOAD_AVG=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' || echo "0")
CPU_CORES=$(nproc 2>/dev/null || echo "1")
if [[ "$LOAD_AVG" != "0" ]]; then
    LOAD_THRESHOLD=$(echo "$CPU_CORES * 2" | bc 2>/dev/null || echo "2")
    if (( $(echo "$LOAD_AVG > $LOAD_THRESHOLD" | bc -l 2>/dev/null || echo 0) )); then
        warn "High load average: $LOAD_AVG (CPUs: $CPU_CORES)"
    else
        pass "Load average acceptable: $LOAD_AVG"
    fi
else
    skip "Load average check (uptime failed)"
fi

echo ""
