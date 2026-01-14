#!/usr/bin/env bash
# Phase 07: Security controls and policy enforcement
# Purpose: Security denials correlated to services and desktop

print_phase_header

# Test case 1: SELinux status and denials
if command -v getenforce >/dev/null 2>&1; then
    SELINUX_STATUS=$(getenforce 2>/dev/null || echo "unknown")
    if [[ "$SELINUX_STATUS" == "Enforcing" ]]; then
        pass "SELinux is enforcing"
    elif [[ "$SELINUX_STATUS" == "Permissive" ]]; then
        warn "SELinux is permissive (not enforcing)"
    elif [[ "$SELINUX_STATUS" == "Disabled" ]]; then
        warn "SELinux is disabled"
    else
        skip "SELinux status check (status: $SELINUX_STATUS)"
    fi
    
    SELINUX_DENIALS=$($JOURNALCTL_BASE 2>/dev/null | grep -i "selinux.*denied\|avc:.*denied" | wc -l)
    if [[ $SELINUX_DENIALS -eq 0 ]]; then
        pass "No SELinux denials"
    else
        warn "Found $SELINUX_DENIALS SELinux denial(s)"
        SELINUX_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -i "selinux.*denied\|avc:.*denied")
        SELINUX_DETAILS_CONSOLE=$(echo "$SELINUX_DETAILS_FULL" | limit_for_console)
        SELINUX_DETAILS_LOG=$(echo "$SELINUX_DETAILS_FULL" | limit_for_log)
        echo -e "\n${YELLOW}SELinux denials:${NC}" | show_indented_details
        echo "$SELINUX_DETAILS_CONSOLE" | show_indented_details
        log_detailed "=== SELinux Denials ==="
        log_detailed "$SELINUX_DETAILS_LOG"
    fi
else
    skip "SELinux checks (getenforce not available)"
fi

# Test case 2: AppArmor denials
APPARMOR_DENIALS=$($JOURNALCTL_BASE 2>/dev/null | grep -i "apparmor.*denied\|apparmor=.*DENIED" | wc -l)
if [[ $APPARMOR_DENIALS -eq 0 ]]; then
    pass "No AppArmor denials"
else
    warn "Found $APPARMOR_DENIALS AppArmor denial(s)"
    APPARMOR_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -i "apparmor.*denied\|apparmor=.*DENIED")
    APPARMOR_DETAILS_CONSOLE=$(echo "$APPARMOR_DETAILS_FULL" | limit_for_console)
    APPARMOR_DETAILS_LOG=$(echo "$APPARMOR_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}AppArmor denials:${NC}" | show_indented_details
    echo "$APPARMOR_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== AppArmor Denials ==="
    log_detailed "$APPARMOR_DETAILS_LOG"
fi

# Test case 3: Firewall status (UFW, firewalld, nftables, iptables)
FIREWALL_FOUND=0

# UFW (Uncomplicated Firewall)
if command -v ufw >/dev/null 2>&1; then
    FIREWALL_FOUND=1
    UFW_STATUS=$(ufw status 2>/dev/null | head -1 | grep -oE "(Status:.*)" || echo "")
    if echo "$UFW_STATUS" | grep -qi "active"; then
        pass "UFW firewall is active"
        
        # Check if logging is enabled
        UFW_LOGGING=$(ufw status verbose 2>/dev/null | grep -i "logging" | head -1 || echo "")
        if [[ -n "$UFW_LOGGING" ]]; then
            log_detailed "=== UFW Logging ==="
            log_detailed "$UFW_LOGGING"
        fi
        
        # Get firewall rules count
        UFW_RULES=$(ufw status numbered 2>/dev/null | grep -E "^\[" | wc -l || echo "0")
        if [[ $UFW_RULES -gt 0 ]]; then
            pass "UFW has $UFW_RULES rule(s) configured"
            # Get full rules list, then limit for console and log
            UFW_RULES_FULL=$(ufw status numbered 2>/dev/null)
            UFW_RULES_CONSOLE=$(echo "$UFW_RULES_FULL" | limit_for_console)
            UFW_RULES_LOG=$(echo "$UFW_RULES_FULL" | limit_for_log)
            if [[ "$AUDIT_VERBOSE" == true ]]; then
                echo -e "\n${CYAN}UFW Rules:${NC}" | show_indented_details
                echo "$UFW_RULES_CONSOLE" | show_indented_details
            fi
            log_detailed "=== UFW Rules ==="
            log_detailed "$UFW_RULES_LOG"
            
            # Check for UFW blocks in logs
            UFW_BLOCKS=$($JOURNALCTL_BASE 2>/dev/null | grep -i "UFW BLOCK" | wc -l)
            if [[ $UFW_BLOCKS -gt 0 ]]; then
                warn "Found $UFW_BLOCKS UFW block(s) in logs"
                UFW_BLOCK_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -i "UFW BLOCK")
                UFW_BLOCK_DETAILS_CONSOLE=$(echo "$UFW_BLOCK_DETAILS_FULL" | limit_for_console)
                UFW_BLOCK_DETAILS_LOG=$(echo "$UFW_BLOCK_DETAILS_FULL" | limit_for_log)
                echo -e "\n${YELLOW}UFW blocks:${NC}" | show_indented_details
                echo "$UFW_BLOCK_DETAILS_CONSOLE" | show_indented_details
                log_detailed "=== UFW Blocks ==="
                log_detailed "$UFW_BLOCK_DETAILS_LOG"
            fi
        else
            warn "UFW is active but has no rules configured"
        fi
    elif echo "$UFW_STATUS" | grep -qi "inactive"; then
        warn "UFW firewall is inactive"
    else
        skip "UFW status check (unable to determine status)"
    fi
fi

# firewalld
if command -v firewall-cmd >/dev/null 2>&1; then
    FIREWALL_FOUND=1
    if firewall-cmd --state 2>/dev/null | grep -qi "running"; then
        pass "firewalld is running"
        if [[ "$AUDIT_VERBOSE" == true ]]; then
            FIREWALLD_INFO=$(firewall-cmd --list-all 2>/dev/null)
            echo -e "\n${CYAN}firewalld configuration:${NC}" | show_indented_details
            echo "$FIREWALLD_INFO" | limit_for_console | show_indented_details
            log_detailed "=== firewalld Configuration ==="
            log_detailed "$FIREWALLD_INFO"
        fi
    else
        warn "firewalld is not running"
    fi
fi

# nftables
if command -v nft >/dev/null 2>&1; then
    FIREWALL_FOUND=1
    NFT_RULES=$(nft list ruleset 2>/dev/null | wc -l 2>/dev/null || echo "0")
    NFT_RULES=$(echo "$NFT_RULES" | tr -d '[:space:]')
    if [[ -n "$NFT_RULES" ]] && [[ "$NFT_RULES" =~ ^[0-9]+$ ]] && [[ $NFT_RULES -gt 0 ]]; then
        pass "nftables is active ($NFT_RULES rules)"
        if [[ "$AUDIT_VERBOSE" == true ]]; then
            NFT_RULESET=$(nft list ruleset 2>/dev/null)
            NFT_RULESET_CONSOLE=$(echo "$NFT_RULESET" | limit_for_console)
            NFT_RULESET_LOG=$(echo "$NFT_RULESET" | limit_for_log)
            echo -e "\n${CYAN}nftables ruleset:${NC}" | show_indented_details
            echo "$NFT_RULESET_CONSOLE" | show_indented_details
            log_detailed "=== nftables Ruleset ==="
            log_detailed "$NFT_RULESET_LOG"
        fi
    else
        warn "nftables: no rules found"
    fi
fi

# iptables
if command -v iptables >/dev/null 2>&1; then
    FIREWALL_FOUND=1
    IPT_RULES=$(iptables -S 2>/dev/null | wc -l 2>/dev/null || echo "0")
    IPT_RULES=$(echo "$IPT_RULES" | tr -d '[:space:]')
    if [[ -n "$IPT_RULES" ]] && [[ "$IPT_RULES" =~ ^[0-9]+$ ]] && [[ $IPT_RULES -gt 0 ]]; then
        pass "iptables is active ($IPT_RULES rules)"
        if [[ "$AUDIT_VERBOSE" == true ]]; then
            IPT_RULESET=$(iptables -S 2>/dev/null)
            IPT_RULESET_CONSOLE=$(echo "$IPT_RULESET" | limit_for_console)
            IPT_RULESET_LOG=$(echo "$IPT_RULESET" | limit_for_log)
            echo -e "\n${CYAN}iptables rules:${NC}" | show_indented_details
            echo "$IPT_RULESET_CONSOLE" | show_indented_details
            log_detailed "=== iptables Rules ==="
            log_detailed "$IPT_RULESET_LOG"
        fi
    else
        warn "iptables: no rules found"
    fi
fi

if [[ $FIREWALL_FOUND -eq 0 ]]; then
    warn "No firewall tooling found (ufw/firewalld/nftables/iptables)"
fi

# Test case 4: Kernel lockdown mode
if [[ -f /sys/kernel/security/lockdown ]]; then
    LOCKDOWN_MODE=$(cat /sys/kernel/security/lockdown 2>/dev/null || echo "unknown")
    if echo "$LOCKDOWN_MODE" | grep -qi "none"; then
        warn "Kernel lockdown: None (not enforced)"
    elif echo "$LOCKDOWN_MODE" | grep -qi "integrity"; then
        pass "Kernel lockdown: Integrity mode"
    elif echo "$LOCKDOWN_MODE" | grep -qi "confidentiality"; then
        pass "Kernel lockdown: Confidentiality mode"
    else
        skip "Kernel lockdown (status: $LOCKDOWN_MODE)"
    fi
    log_detailed "=== Kernel Lockdown ==="
    log_detailed "Mode: $LOCKDOWN_MODE"
else
    skip "Kernel lockdown check (not available)"
fi

# Test case 5: seccomp violations
SECCOMP_VIOLATIONS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "seccomp|SECCOMP" | grep -iE "denied|blocked" | wc -l)
if [[ $SECCOMP_VIOLATIONS -eq 0 ]]; then
    pass "No seccomp violations detected"
else
    warn "Found $SECCOMP_VIOLATIONS seccomp violation(s)"
    SECCOMP_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "seccomp|SECCOMP" | grep -iE "denied|blocked")
    SECCOMP_DETAILS_CONSOLE=$(echo "$SECCOMP_DETAILS_FULL" | limit_for_console)
    SECCOMP_DETAILS_LOG=$(echo "$SECCOMP_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}seccomp violations:${NC}" | show_indented_details
    echo "$SECCOMP_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== seccomp Violations ==="
    log_detailed "$SECCOMP_DETAILS_LOG"
fi

echo ""
