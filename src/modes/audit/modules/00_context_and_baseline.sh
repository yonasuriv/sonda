#!/usr/bin/env bash
# Phase 00: Audit context and baselines
# Purpose: Make results comparable and debuggable

# This module must be sourced after lib/init.sh

print_phase_header

# Test case 1: Host identity
#info "Collecting host identity information..."

# Hostname
HOSTNAME=$(hostnamectl --static 2>/dev/null || hostname 2>/dev/null || echo "unknown")
if [[ "$HOSTNAME" != "unknown" ]]; then
    pass "Hostname: $HOSTNAME"
    log_detailed "=== Hostname ==="
    log_detailed "Hostname: $HOSTNAME"
else
    skip "Hostname detection (hostnamectl/hostname not available)"
fi

# OS information
if [[ -f /etc/os-release ]]; then
    OS_NAME=$(grep "^NAME=" /etc/os-release | cut -d'"' -f2 || echo "Unknown")
    OS_VERSION=$(grep "^VERSION=" /etc/os-release | cut -d'"' -f2 | head -1 || echo "Unknown")
    pass "OS: $OS_NAME $OS_VERSION"
    log_detailed "=== OS Information ==="
    log_detailed "$(cat /etc/os-release)"
else
    skip "OS information (/etc/os-release not found)"
fi

# Kernel version
KERNEL_VERSION=$(uname -r 2>/dev/null || echo "Unknown")
if [[ "$KERNEL_VERSION" != "Unknown" ]]; then
    pass "Kernel: $KERNEL_VERSION"
    log_detailed "=== Kernel Information ==="
    log_detailed "Kernel: $KERNEL_VERSION"
    log_detailed "Architecture: $(uname -m)"
else
    skip "Kernel version (uname failed)"
fi

# Init system
if command -v systemd >/dev/null 2>&1; then
    INIT_SYSTEM="systemd"
    SYSTEMD_VERSION=$(systemd --version 2>/dev/null | head -1 || echo "Unknown")
    pass "Init system: $INIT_SYSTEM ($SYSTEMD_VERSION)"
    log_detailed "=== Init System ==="
    log_detailed "$SYSTEMD_VERSION"
else
    INIT_SYSTEM="unknown"
    skip "Init system detection (systemd not found)"
fi

# Desktop environment
if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
    pass "Desktop: $XDG_CURRENT_DESKTOP"
    log_detailed "=== Desktop Environment ==="
    log_detailed "XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
    log_detailed "XDG_SESSION_TYPE: ${XDG_SESSION_TYPE:-unknown}"
else
    skip "Desktop environment (XDG_CURRENT_DESKTOP not set)"
fi

# GPU information
if command -v lspci >/dev/null 2>&1; then
    GPU_INFO=$(lspci 2>/dev/null | grep -i "vga\|3d\|display" | head -3)
    if [[ -n "$GPU_INFO" ]]; then
        pass "GPU detected"
        log_detailed "=== GPU Information ==="
        log_detailed "$GPU_INFO"
    else
        skip "GPU detection (no GPU found in lspci)"
    fi
else
    skip "GPU detection (lspci not available)"
fi

# Storage information
STORAGE_INFO=$(lsblk -d -o NAME,SIZE,TYPE,MODEL 2>/dev/null | head -10)
if [[ -n "$STORAGE_INFO" ]]; then
    pass "Storage devices detected"
    log_detailed "=== Storage Information ==="
    log_detailed "$STORAGE_INFO"
else
    skip "Storage detection (lsblk not available or no devices)"
fi

# Test case 2: Time reference
#info "Collecting time reference information..."

# Boot ID
BOOT_ID=$(journalctl --list-boots 2>/dev/null | tail -1 | awk '{print $1}' || echo "unknown")
if [[ "$BOOT_ID" != "unknown" ]]; then
    pass "Boot ID: $BOOT_ID"
    log_detailed "Boot ID: $BOOT_ID"
    export AUDIT_BOOT_ID="$BOOT_ID"
else
    skip "Boot ID (journalctl not available)"
fi

# Boot timestamp
BOOT_TIME=$(systemd-analyze 2>/dev/null | grep -oP 'Startup finished in \K[0-9.]+' || echo "unknown")
if [[ "$BOOT_TIME" != "unknown" ]]; then
    pass "Boot time: ${BOOT_TIME}s"
    log_detailed "Boot time: ${BOOT_TIME}s"
else
    skip "Boot time (systemd-analyze not available)"
fi

# System uptime
UPTIME=$(uptime -p 2>/dev/null || echo "unknown")
if [[ "$UPTIME" != "unknown" ]]; then
    pass "Uptime: $UPTIME"
    log_detailed "=== System Uptime ==="
    log_detailed "$UPTIME"
    log_detailed "$(uptime)"
else
    skip "Uptime (uptime command failed)"
fi

# Timezone
TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "unknown")
if [[ "$TIMEZONE" != "unknown" ]]; then
    pass "Timezone: $TIMEZONE"
    log_detailed "=== Time Information ==="
    log_detailed "Timezone: $TIMEZONE"
    log_detailed "Current time: $(date)"
else
    skip "Timezone (timedatectl not available)"
fi

# Test case 3: Log scope and journal status
#info "Checking log scope and journal status..."

# Journal status
if command -v journalctl >/dev/null 2>&1; then
    JOURNAL_STATUS=$(journalctl --list-boots 2>/dev/null | wc -l)
    if [[ $JOURNAL_STATUS -gt 0 ]]; then
        pass "Systemd journal available ($JOURNAL_STATUS boot(s) recorded)"
        log_detailed "=== Journal Status ==="
        log_detailed "Boots recorded: $JOURNAL_STATUS"
        log_detailed "$(journalctl --list-boots | tail -5)"
    else
        warn "Systemd journal empty or not persistent"
    fi
else
    skip "Journal status (journalctl not available)"
fi

# Persistent journal check
if [[ -d /var/log/journal ]]; then
    pass "Persistent journal enabled (/var/log/journal exists)"
    log_detailed "=== Persistent Journal ==="
    log_detailed "Journal directory: /var/log/journal"
    log_detailed "Directory size: $(du -sh /var/log/journal 2>/dev/null | awk '{print $1}' || echo 'unknown')"
else
    warn "Persistent journal not enabled (only in-memory logs)"
    log_detailed "=== Persistent Journal ==="
    log_detailed "Warning: /var/log/journal does not exist - logs may be lost on reboot"
fi

# Journal disk usage
if command -v journalctl >/dev/null 2>&1; then
    JOURNAL_DISK_USAGE=$(journalctl --disk-usage 2>/dev/null | tr -d '\r' || echo "")
    if [[ -n "$JOURNAL_DISK_USAGE" ]]; then
        pass "Journal disk usage: $JOURNAL_DISK_USAGE"
        log_detailed "=== Journal Disk Usage ==="
        log_detailed "$JOURNAL_DISK_USAGE"
    else
        skip "Journal disk usage (unable to determine)"
    fi
else
    skip "Journal disk usage (journalctl not available)"
fi

# Reboot required check
if [[ -e /var/run/reboot-required ]]; then
    warn "Reboot required (marker present: /var/run/reboot-required)"
    log_detailed "=== Reboot Required ==="
    log_detailed "Marker file: /var/run/reboot-required"
    if [[ -f /var/run/reboot-required.pkgs ]]; then
        log_detailed "Packages requiring reboot:"
        log_detailed "$(cat /var/run/reboot-required.pkgs 2>/dev/null || echo 'unable to read')"
    fi
else
    pass "Reboot required: no"
fi

echo ""
