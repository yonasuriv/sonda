#!/usr/bin/env bash
# Phase 06: Networking bring-up
# Purpose: Connectivity issues that cascade into slow boots and service failures

print_phase_header

# Test case 1: Network manager errors
NETWORK_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(networkmanager|network-manager|systemd-networkd).*(error|fail|timeout)" | wc -l)
if [[ $NETWORK_ERRORS -eq 0 ]]; then
    pass "No network manager errors"
else
    warn "Found $NETWORK_ERRORS network manager error(s)"
    NETWORK_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(networkmanager|network-manager|systemd-networkd).*(error|fail|timeout)")
    NETWORK_DETAILS_CONSOLE=$(echo "$NETWORK_DETAILS_FULL" | limit_for_console)
    NETWORK_DETAILS_LOG=$(echo "$NETWORK_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}Network manager errors:${NC}" | show_indented_details
    echo "$NETWORK_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Network Manager Errors ==="
    log_detailed "$NETWORK_DETAILS_LOG"
fi

# Test case 2: DNS resolution issues
DNS_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(dns|resolved|resolver).*(error|fail|timeout)" | wc -l)
if [[ $DNS_ERRORS -eq 0 ]]; then
    pass "No DNS resolution errors"
else
    warn "Found $DNS_ERRORS DNS resolution error(s)"
    DNS_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(dns|resolved|resolver).*(error|fail|timeout)")
    DNS_DETAILS_CONSOLE=$(echo "$DNS_DETAILS_FULL" | limit_for_console)
    DNS_DETAILS_LOG=$(echo "$DNS_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}DNS errors:${NC}" | show_indented_details
    echo "$DNS_DETAILS_CONSOLE" | show_indented_details
    echo "" | show_indented_details
    log_detailed "=== DNS Resolution Errors ==="
    log_detailed "$DNS_DETAILS_LOG"
fi

# Test case 3: DHCP issues
DHCP_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "dhcp.*(error|fail|timeout)" | wc -l)
if [[ $DHCP_ERRORS -eq 0 ]]; then
    pass "No DHCP errors"
else
    warn "Found $DHCP_ERRORS DHCP error(s)"
    DHCP_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "dhcp.*(error|fail|timeout)")
    DHCP_DETAILS_CONSOLE=$(echo "$DHCP_DETAILS_FULL" | limit_for_console)
    DHCP_DETAILS_LOG=$(echo "$DHCP_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}DHCP errors:${NC}" | show_indented_details
    echo "$DHCP_DETAILS_CONSOLE" | show_indented_details
    echo "" | show_indented_details
    log_detailed "=== DHCP Errors ==="
    log_detailed "$DHCP_DETAILS_LOG"
fi

# Test case 4: Link flaps and interface issues
LINK_FLAPS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "link.*flap|interface.*down|carrier.*lost" | wc -l)
if [[ $LINK_FLAPS -eq 0 ]]; then
    pass "No link flap events"
else
    warn "Found $LINK_FLAPS link flap event(s)"
    LINK_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "link.*flap|interface.*down|carrier.*lost")
    LINK_DETAILS_CONSOLE=$(echo "$LINK_DETAILS_FULL" | limit_for_console)
    LINK_DETAILS_LOG=$(echo "$LINK_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}Link flap events:${NC}" | show_indented_details
    echo "$LINK_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Link Flap Events ==="
    log_detailed "$LINK_DETAILS_LOG"
fi

# Test case 5: Wi-Fi authentication failures
WIFI_AUTH_FAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "wifi|wlan.*auth.*fail|802.11.*fail" | wc -l)
if [[ $WIFI_AUTH_FAILS -eq 0 ]]; then
    pass "No Wi-Fi authentication failures"
else
    warn "Found $WIFI_AUTH_FAILS Wi-Fi authentication failure(s)"
    WIFI_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "wifi|wlan.*auth.*fail|802.11.*fail")
    WIFI_DETAILS_CONSOLE=$(echo "$WIFI_DETAILS_FULL" | limit_for_console)
    WIFI_DETAILS_LOG=$(echo "$WIFI_DETAILS_FULL" | limit_for_log)
    echo -e "\n${YELLOW}Wi-Fi auth failures:${NC}" | show_indented_details
    echo "$WIFI_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Wi-Fi Auth Failures ==="
    log_detailed "$WIFI_DETAILS_LOG"
fi

echo ""
