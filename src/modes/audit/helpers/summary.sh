#!/usr/bin/env bash
# Summary generation functions

# Load dependencies
source "${BASH_SOURCE[0]%/*}/colors.sh"
source "${BASH_SOURCE[0]%/*}/phases.sh"

# Calculate phase status based on test results
calculate_phase_status() {
    local phase_id="$1"
    local phase_failed="${AUDIT_PHASE_FAILED[$phase_id]:-0}"
    local phase_warnings="${AUDIT_PHASE_WARNINGS[$phase_id]:-0}"
    local phase_passed="${AUDIT_PHASE_PASSED[$phase_id]:-0}"
    local phase_skipped="${AUDIT_PHASE_SKIPPED[$phase_id]:-0}"
    
    # If phase has failures, status is FAIL
    if [[ $phase_failed -gt 0 ]]; then
        echo "FAIL"
    # If phase has warnings but no failures, status is WARN
    elif [[ $phase_warnings -gt 0 ]]; then
        echo "WARN"
    # If phase has only passes or skips, status is PASS
    elif [[ $phase_passed -gt 0 ]] || [[ $phase_skipped -gt 0 ]]; then
        echo "PASS"
    # If phase has no tests, status is SKIP
    else
        echo "SKIP"
    fi
}

# Update phase counters - use directly tracked counters from functions.sh
update_phase_counters() {
    local phase_id="$1"
    
    # Use directly tracked phase counters (set by pass/fail/warn/skip functions)
    # If not set, default to 0
    AUDIT_PHASE_FAILED[$phase_id]=${AUDIT_PHASE_FAILED[$phase_id]:-0}
    AUDIT_PHASE_WARNINGS[$phase_id]=${AUDIT_PHASE_WARNINGS[$phase_id]:-0}
    AUDIT_PHASE_PASSED[$phase_id]=${AUDIT_PHASE_PASSED[$phase_id]:-0}
    AUDIT_PHASE_SKIPPED[$phase_id]=${AUDIT_PHASE_SKIPPED[$phase_id]:-0}
    
    # Set phase status
    AUDIT_PHASE_STATUS[$phase_id]=$(calculate_phase_status "$phase_id")
}

# Get boot information
get_boot_info() {
    # Boot ID
    if [[ -z "$AUDIT_BOOT_ID" ]]; then
        AUDIT_BOOT_ID=$(journalctl --list-boots 2>/dev/null | tail -1 | awk '{print $1}' || echo "unknown")
    fi
    
    # Boot to GUI status
    if [[ -z "$AUDIT_BOOT_TO_GUI" ]]; then
        if systemctl is-active --quiet graphical.target 2>/dev/null; then
            AUDIT_BOOT_TO_GUI="OK (graphical.target reached)"
        else
            # Check if we're in a graphical session
            if [[ -n "$XDG_SESSION_TYPE" ]] && [[ "$XDG_SESSION_TYPE" == "wayland" || "$XDG_SESSION_TYPE" == "x11" ]]; then
                AUDIT_BOOT_TO_GUI="OK (graphical session active)"
            else
                AUDIT_BOOT_TO_GUI="FAILED (graphical.target not reached)"
            fi
        fi
    fi
    
    # Boot timing
    if [[ -z "$AUDIT_BOOT_TOTAL_TIME" ]] && command -v systemd-analyze >/dev/null 2>&1; then
        local analyze_output=$(systemd-analyze 2>/dev/null)
        AUDIT_BOOT_TOTAL_TIME=$(echo "$analyze_output" | grep -oP 'Startup finished in \K[0-9.]+' || echo "")
        
        # Parse timing breakdown
        AUDIT_BOOT_FIRMWARE_TIME=$(echo "$analyze_output" | grep -oP 'firmware\) \K[0-9.]+' || echo "")
        AUDIT_BOOT_LOADER_TIME=$(echo "$analyze_output" | grep -oP 'loader\) \K[0-9.]+' || echo "")
        AUDIT_BOOT_KERNEL_TIME=$(echo "$analyze_output" | grep -oP 'kernel\) \K[0-9.]+' || echo "")
        AUDIT_BOOT_USERSPACE_TIME=$(echo "$analyze_output" | grep -oP 'userspace\) \K[0-9.]+' || echo "")
    fi
}

# Generate summary
generate_summary() {
    # Update all phase counters
    local phase_id
    for phase_id in $(get_all_phase_ids); do
        update_phase_counters "$phase_id"
    done
    
    # Get boot information
    get_boot_info
    
    # Calculate totals
    local total_tests=$((AUDIT_PASSED + AUDIT_FAILED + AUDIT_WARNINGS + AUDIT_SKIPPED))
    
    # Print summary header
    print_header "Audit Summary"
    
    # Boot scope and status
    echo -e "  Boot scope:      Current (boot id=${AUDIT_BOOT_ID})"
    if [[ "$AUDIT_BOOT_TO_GUI" == "OK"* ]]; then
        echo -e "  Boot to GUI:     ${GREEN}${AUDIT_BOOT_TO_GUI}${NC}"
    else
        echo -e "  Boot to GUI:     ${RED}${AUDIT_BOOT_TO_GUI}${NC}"
    fi
    
    # Boot timing
    if [[ -n "$AUDIT_BOOT_TOTAL_TIME" ]] && [[ "$AUDIT_BOOT_TOTAL_TIME" != "0" ]] && [[ "$AUDIT_BOOT_TOTAL_TIME" != "0.000" ]]; then
        local total_time_formatted=$(echo "$AUDIT_BOOT_TOTAL_TIME" | awk '{printf "%.3f", $1}')
        local timing_parts=""
        if [[ -n "$AUDIT_BOOT_FIRMWARE_TIME" ]] && [[ "$AUDIT_BOOT_FIRMWARE_TIME" != "0" ]] && [[ "$AUDIT_BOOT_FIRMWARE_TIME" != "0.000" ]]; then
            local fw_formatted=$(echo "$AUDIT_BOOT_FIRMWARE_TIME" | awk '{printf "%.3f", $1}')
            timing_parts="${timing_parts}firmware ${fw_formatted}s, "
        fi
        if [[ -n "$AUDIT_BOOT_LOADER_TIME" ]] && [[ "$AUDIT_BOOT_LOADER_TIME" != "0" ]] && [[ "$AUDIT_BOOT_LOADER_TIME" != "0.000" ]]; then
            local ld_formatted=$(echo "$AUDIT_BOOT_LOADER_TIME" | awk '{printf "%.3f", $1}')
            timing_parts="${timing_parts}loader ${ld_formatted}s, "
        fi
        if [[ -n "$AUDIT_BOOT_KERNEL_TIME" ]] && [[ "$AUDIT_BOOT_KERNEL_TIME" != "0" ]] && [[ "$AUDIT_BOOT_KERNEL_TIME" != "0.000" ]]; then
            local kn_formatted=$(echo "$AUDIT_BOOT_KERNEL_TIME" | awk '{printf "%.3f", $1}')
            timing_parts="${timing_parts}kernel ${kn_formatted}s, "
        fi
        if [[ -n "$AUDIT_BOOT_USERSPACE_TIME" ]] && [[ "$AUDIT_BOOT_USERSPACE_TIME" != "0" ]] && [[ "$AUDIT_BOOT_USERSPACE_TIME" != "0.000" ]]; then
            local us_formatted=$(echo "$AUDIT_BOOT_USERSPACE_TIME" | awk '{printf "%.3f", $1}')
            timing_parts="${timing_parts}userspace ${us_formatted}s"
        fi
        timing_parts=$(echo "$timing_parts" | sed 's/, $//')
        if [[ -n "$timing_parts" ]]; then
            echo -e "  Total time:      ${total_time_formatted}s (${timing_parts})"
        else
            echo -e "  Total time:      ${total_time_formatted}s"
        fi
    else
        echo -e "  Total time:      ${CYAN}not available${NC}"
    fi
    
    echo -e "  Phases run:      ${BLUE}${AUDIT_PHASE_COUNT}${NC}"
    echo -e "  Tests:           ${BLUE}${total_tests}${NC}  (pass ${GREEN}${AUDIT_PASSED}${NC}, warn ${YELLOW}${AUDIT_WARNINGS}${NC}, fail ${RED}${AUDIT_FAILED}${NC}, skip ${CYAN}${AUDIT_SKIPPED}${NC})"
    echo ""
    
    # Failures by phase (sorted by failure count, descending)
    local has_failures=false
    local phase_list=""
    
    # Collect phases with failures/warnings
    for phase_id in $(get_all_phase_ids); do
        local phase_failed="${AUDIT_PHASE_FAILED[$phase_id]:-0}"
        local phase_warnings="${AUDIT_PHASE_WARNINGS[$phase_id]:-0}"
        if [[ $phase_failed -gt 0 ]] || [[ $phase_warnings -gt 0 ]]; then
            local phase_name=$(get_phase_display_name "$phase_id")
            local status_str=""
            if [[ $phase_failed -gt 0 ]]; then
                status_str="${phase_failed} fail"
            fi
            if [[ $phase_warnings -gt 0 ]]; then
                if [[ -n "$status_str" ]]; then
                    status_str="${status_str}, ${phase_warnings} warn"
                else
                    status_str="${phase_warnings} warn"
                fi
            fi
            # Store: phase_id|phase_failed|phase_warnings|phase_name|status_str
            phase_list="${phase_list}${phase_id}|${phase_failed}|${phase_warnings}|${phase_name}|${status_str}"$'\n'
        fi
    done
    
    # Sort by failure count (descending), then by warnings (descending)
    if [[ -n "$phase_list" ]]; then
        echo -e "  ${BOLD}Failures by phase:${NC}"
        echo "$phase_list" | sort -t'|' -k2,2rn -k3,3rn | while IFS='|' read -r phase_id phase_failed phase_warnings phase_name status_str; do
            [[ -n "$phase_id" ]] && printf "    %-2s %-48s %s\n" "$phase_id" "${phase_name} " "$status_str"
        done
    else
        echo -e "  Failures by phase: ${GREEN}none${NC}"
    fi
    echo ""

    ################################################################################################
    #                                                                                              #
    # TEMPORAL: NEEDS TO BE ENHANCED BASED ON PHASES, SEVERITY, AND IMPACT (CURRENTLY NOT DONE)    #
    #           REMEDIATIONS NEEDS TO BE DEFINED IN EACH OF THE TEST CASES, AS FOR audith.sh       #
    #                                                                                              #
    ################################################################################################
    
    # Key Findings
    print_highest_impact_findings() {
        # Highest impact findings (simplified - can be enhanced)
        if [[ $AUDIT_FAILED -gt 0 ]] || [[ $AUDIT_WARNINGS -gt 0 ]]; then
            echo -e "  ${BOLD}Highest impact findings:${NC}"
            local finding_num=1
            
            # Filesystem errors (Phase 05)
            local fs_errors="${AUDIT_PHASE_FAILED[05]:-0}"
            if [[ $fs_errors -gt 0 ]]; then
                echo -e "    ${finding_num}) Filesystem errors detected. Treat as priority. Can cause boot slowness and desktop instability."
                ((finding_num++))
            fi
            
            # Kernel errors (Phase 02)
            local kernel_errors="${AUDIT_PHASE_FAILED[02]:-0}"
            if [[ $kernel_errors -gt 0 ]] && [[ -n "$AUDIT_BOOT_KERNEL_TIME" ]]; then
                local kernel_slow=false
                if (( $(echo "$AUDIT_BOOT_KERNEL_TIME > 20" | bc -l 2>/dev/null || echo 0) )); then
                    kernel_slow=true
                fi
                if [[ "$kernel_slow" == true ]]; then
                    echo -e "    ${finding_num}) Kernel time is slow (${AUDIT_BOOT_KERNEL_TIME}s). Likely driver init stall or hardware retry loop."
                    ((finding_num++))
                fi
            fi
            
            # OOM events (Phase 10)
            local oom_errors="${AUDIT_PHASE_FAILED[10]:-0}"
            if [[ $oom_errors -gt 0 ]]; then
                echo -e "    ${finding_num}) OOM events detected. Explains desktop crashes and random failures."
                ((finding_num++))
            fi
            
            # Security denials (Phase 07)
            local sec_warnings="${AUDIT_PHASE_WARNINGS[07]:-0}"
            if [[ $sec_warnings -gt 0 ]]; then
                echo -e "    ${finding_num}) Security policy denials detected. Mostly noise unless tied to a failing service."
                ((finding_num++))
            fi
            
            if [[ $finding_num -eq 1 ]]; then
                echo -e "    ${CYAN}No critical findings identified${NC}"
            fi
        else
            echo -e "  ${BOLD}Highest impact findings:${NC} ${GREEN}none${NC}"
        fi
        echo ""
    }
    
    
    # Action order/key remmediations
    print_action_order() {
        if [[ $AUDIT_FAILED -gt 0 ]]; then
            echo -e "  ${BOLD}Action order:${NC}"
            local action_letter="A"
            
            # Priority 1: Filesystem errors
            if [[ "${AUDIT_PHASE_FAILED[05]:-0}" -gt 0 ]]; then
                echo -e "    ${action_letter}) Fix storage and filesystem errors first."
                action_letter=$(printf "%c" $(( $(printf "%d" "'$action_letter") + 1 )) 2>/dev/null || echo "B")
            fi
            
            # Priority 2: Kernel issues
            if [[ "${AUDIT_PHASE_FAILED[02]:-0}" -gt 0 ]] || [[ -n "$AUDIT_BOOT_KERNEL_TIME" ]]; then
                echo -e "    ${action_letter}) Identify kernel boot stall (critical-chain plus dmesg timing)."
                action_letter=$(printf "%c" $(( $(printf "%d" "'$action_letter") + 1 )) 2>/dev/null || echo "C")
            fi
            
            # Priority 3: OOM
            if [[ "${AUDIT_PHASE_FAILED[10]:-0}" -gt 0 ]]; then
                echo -e "    ${action_letter}) Address OOM pressure (culprit process, swap, zram, limits)."
                action_letter=$(printf "%c" $(( $(printf "%d" "'$action_letter") + 1 )) 2>/dev/null || echo "D")
            fi
            
            # Priority 4: Display stack
            if [[ "${AUDIT_PHASE_FAILED[08]:-0}" -gt 0 ]] || [[ "${AUDIT_PHASE_WARNINGS[08]:-0}" -gt 0 ]]; then
                echo -e "    ${action_letter}) Triage display stack warnings only after A-C."
            fi
        else
            echo -e "  Action order: ${GREEN}No actions required${NC}"
        fi
        echo ""
    }
    
    # Phase status table
    print_header "Phase Status"
    for phase_id in $(get_all_phase_ids); do
        local phase_name=$(get_phase_display_name "$phase_id")
        local phase_status="${AUDIT_PHASE_STATUS[$phase_id]:-SKIP}"
        local status_color=""
        case "$phase_status" in
            PASS) status_color="${GREEN}" ;;
            WARN) status_color="${YELLOW}" ;;
            FAIL) status_color="${RED}" ;;
            *) status_color="${CYAN}" ;;
        esac
        # Build the full line with colors, then use echo -e to interpret escape codes
        local status_line="${status_color}${phase_status}${NC}"
        printf "    %-2s %-50s " "$phase_id" "${phase_name}"
        echo -e "$status_line"
    done
    echo ""
}

# Export functions
export -f calculate_phase_status update_phase_counters get_boot_info generate_summary
