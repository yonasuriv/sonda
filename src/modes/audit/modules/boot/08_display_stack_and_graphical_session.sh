#!/usr/bin/env bash
# Phase 08: Display stack and graphical session start
# Purpose: Split display stack vs desktop session

print_phase_header

# Test case 1: Display manager status
DISPLAY_MANAGER=""
if systemctl is-active --quiet gdm.service 2>/dev/null; then
    DISPLAY_MANAGER="gdm"
elif systemctl is-active --quiet sddm.service 2>/dev/null; then
    DISPLAY_MANAGER="sddm"
elif systemctl is-active --quiet lightdm.service 2>/dev/null; then
    DISPLAY_MANAGER="lightdm"
fi

if [[ -n "$DISPLAY_MANAGER" ]]; then
    pass "Display manager active: $DISPLAY_MANAGER"
    
    # Check for display manager failures
    DM_FAILURES=$(systemctl show "$DISPLAY_MANAGER.service" --property=ActiveState,SubState 2>/dev/null | grep -i "failed\|inactive" | wc -l)
    if [[ $DM_FAILURES -eq 0 ]]; then
        pass "$DISPLAY_MANAGER service healthy"
    else
        fail "$DISPLAY_MANAGER service has issues"
        DM_STATUS=$(systemctl status "$DISPLAY_MANAGER.service" --no-pager -l 2>/dev/null)
        log_detailed "=== $DISPLAY_MANAGER Status ==="
        log_detailed "$DM_STATUS"
    fi
else
    skip "Display manager check (no active display manager found)"
fi

# Test case 2: Display protocol (Wayland/X11)
if [[ -n "$WAYLAND_DISPLAY" ]]; then
    pass "Display protocol: Wayland"
    log_detailed "=== Display Protocol ==="
    log_detailed "Protocol: Wayland"
    log_detailed "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
elif [[ -n "$DISPLAY" ]]; then
    pass "Display protocol: X11"
    log_detailed "=== Display Protocol ==="
    log_detailed "Protocol: X11"
    log_detailed "DISPLAY: $DISPLAY"
else
    skip "Display protocol detection (no display session)"
fi

# Test case 3: Compositor crashes (Mutter/gnome-shell)
COMPOSITOR_CRASHES=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(mutter|gnome-shell|compositor).*(crash|segfault|SIGSEGV|SIGABRT)" | wc -l)
if [[ $COMPOSITOR_CRASHES -eq 0 ]]; then
    pass "No compositor crashes detected"
else
    fail "Found $COMPOSITOR_CRASHES compositor crash(es)"
    COMPOSITOR_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(mutter|gnome-shell|compositor).*(crash|segfault|SIGSEGV|SIGABRT)" | tail -20)
    echo -e "\n${RED}Compositor crashes:${NC}" | show_indented_details
    echo "$COMPOSITOR_DETAILS" | show_indented_details
    log_detailed "=== Compositor Crashes ==="
    log_detailed "$COMPOSITOR_DETAILS"
fi

# Test case 4: GPU/DRM/KMS errors
if [[ "$SUDO_AVAILABLE" == true ]]; then
    GPU_DRM_ERRORS=$($SUDO_DMESG_BASE 2>/dev/null | grep -iE "(drm|kms|gpu|radeon|nvidia|intel|amdgpu).*(error|fail|timeout|reset|modeset.*fail)" | wc -l)
    if [[ $GPU_DRM_ERRORS -eq 0 ]]; then
        pass "No GPU/DRM/KMS errors detected"
    else
        fail "Found $GPU_DRM_ERRORS GPU/DRM/KMS error(s)"
        GPU_DRM_DETAILS=$($SUDO_DMESG_BASE 2>/dev/null | grep -iE "(drm|kms|gpu|radeon|nvidia|intel|amdgpu).*(error|fail|timeout|reset|modeset.*fail)" | tail -30)
        echo -e "\n${RED}GPU/DRM/KMS errors:${NC}" | show_indented_details
        echo "$GPU_DRM_DETAILS" | show_indented_details
        log_detailed "=== GPU/DRM/KMS Errors ==="
        log_detailed "$GPU_DRM_DETAILS"
    fi
else
    skip "GPU/DRM/KMS check (sudo required)"
fi

# Test case 5: Monitor/EDID issues
MONITOR_ISSUES=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(monitor|edid|display).*(error|fail|timeout|disconnect)" | wc -l)
if [[ $MONITOR_ISSUES -eq 0 ]]; then
    pass "No monitor/EDID issues detected"
else
    warn "Found $MONITOR_ISSUES monitor/EDID issue(s)"
    MONITOR_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(monitor|edid|display).*(error|fail|timeout|disconnect)" | tail -20)
    echo -e "\n${YELLOW}Monitor/EDID issues:${NC}" | show_indented_details
    echo "$MONITOR_DETAILS" | show_indented_details
    log_detailed "=== Monitor/EDID Issues ==="
    log_detailed "$MONITOR_DETAILS"
fi

# Test case 6: Wayland/X11 protocol errors
WAYLAND_X11_ERRORS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(wayland|x11|xorg|weston).*(error|fail|crash|abort)" | wc -l)
if [[ $WAYLAND_X11_ERRORS -eq 0 ]]; then
    pass "No Wayland/X11 protocol errors"
else
    warn "Found $WAYLAND_X11_ERRORS Wayland/X11 error(s)"
    WAYLAND_X11_DETAILS=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "(wayland|x11|xorg|weston).*(error|fail|crash|abort)" | tail -20)
    echo -e "\n${YELLOW}Wayland/X11 errors:${NC}" | show_indented_details
    echo "$WAYLAND_X11_DETAILS" | show_indented_details
    log_detailed "=== Wayland/X11 Errors ==="
    log_detailed "$WAYLAND_X11_DETAILS"
fi

echo ""
