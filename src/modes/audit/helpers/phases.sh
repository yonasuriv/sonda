#!/usr/bin/env bash
# Phase registry - defines phase IDs, filenames, and display names

# Phase definitions: phase_id|filename|display_name
declare -A PHASE_REGISTRY=(
    ["00"]="00_context_and_baseline.sh|Audit Context and Baselines"
    ["01"]="01_firmware_and_bootloader.sh|Firmware and Bootloader"
    ["02"]="02_kernel_and_hardware_bringup.sh|Kernel and Hardware Bring-up"
    ["03"]="03_initramfs_and_rootfs.sh|Initramfs and Root Filesystem Handoff"
    ["04"]="04_systemd_boot_and_critical_path.sh|Systemd Userspace"
    ["05"]="05_storage_and_filesystem_integrity.sh|Storage and Filesystem Integrity"
    ["06"]="06_network_stack_and_connectivity.sh|Network Stack and Connectivity"
    ["07"]="07_security_controls_and_policy_enforcement.sh|Security Controls and Policy Enforcement"
    ["08"]="08_display_stack_and_graphical_session.sh|Display Stack and Graphical Session Start"
    ["09"]="09_user_session_and_desktop_services.sh|User Session and Desktop Services"
    ["10"]="10_resource_pressure_and_system_stability.sh|Resource Pressure and System Stability"
    ["11"]="11_current_system_posture.sh|Current System Posture Snapshot"
    ["12"]="12_top_findings_and_risk_summary.sh|Top Findings and Risk Summary"
)

# Get phase filename
get_phase_filename() {
    local phase_id="$1"
    echo "${PHASE_REGISTRY[$phase_id]}" | cut -d'|' -f1
}

# Get phase display name
get_phase_display_name() {
    local phase_id="$1"
    echo "${PHASE_REGISTRY[$phase_id]}" | cut -d'|' -f2
}

# Get all phase IDs in order
get_all_phase_ids() {
    echo "00 01 02 03 04 05 06 07 08 09 10 11 12"
}

# Export functions
export -f get_phase_filename get_phase_display_name get_all_phase_ids
