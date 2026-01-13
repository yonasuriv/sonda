#!/usr/bin/env bash
# Phase 04: systemd userspace - critical path to graphical.target
# Purpose: What actually delays "GUI up"

print_phase_header

# Boot analysis functions (migrated from boot-analyzer.sh)
have() { command -v "$1" >/dev/null 2>&1; }

# Convert a duration like "1min 1.923s" or "61.923s" into seconds (float).
to_seconds() {
  local s="$1"
  awk -v str="$s" '
    function trim(x){ gsub(/^[ \t]+|[ \t]+$/, "", x); return x }
    BEGIN{
      str=trim(str)
      mins=0; secs=0
      if (match(str, /([0-9]+)min/, m)) mins=m[1]
      if (match(str, /([0-9]+(\.[0-9]+)?)s/, t)) secs=t[1]
      printf "%.3f", (mins*60 + secs)
    }'
}

# Thresholds in seconds per phase.
# Levels: 0=hyper fast, 1=fast, 2=moderate, 3=slow, 4=super slow
classify() {
  local phase="$1" t="$2"
  awk -v p="$phase" -v x="$t" '
    function lvl_from_bounds(a,b,c,d, x){
      if (x < a) return 0
      if (x < b) return 1
      if (x < c) return 2
      if (x < d) return 3
      return 4
    }
    BEGIN{
      if (p=="firmware")      print lvl_from_bounds(2, 5, 12, 25, x)
      else if (p=="loader")   print lvl_from_bounds(0.2, 0.8, 2, 5, x)
      else if (p=="kernel")   print lvl_from_bounds(1, 2.5, 6, 12, x)
      else if (p=="userspace")print lvl_from_bounds(5, 12, 25, 60, x)
      else if (p=="total")    print lvl_from_bounds(8, 18, 35, 75, x)
      else if (p=="graphical")print lvl_from_bounds(5, 12, 25, 60, x)
      else                    print lvl_from_bounds(5, 12, 25, 60, x)
    }'
}

# Color setup (tput). Falls back to no color if not on a tty or tput missing.
if [[ -t 1 ]] && have tput; then
  C_RESET="$(tput sgr0)"
  C_HYPER="$(tput setaf 10)"  # green
  C_FAST="$(tput setaf 2)"    # cyan
  C_MOD="$(tput setaf 208)"  # yellow
  C_SLOW="$(tput setaf 3)"   # magenta
  C_SUPER="$(tput setaf 1)"  # red
  C_DIM="$(tput dim)"
  C_BOLD="$(tput bold)"
else
  C_RESET="" C_HYPER="" C_FAST="" C_MOD="" C_SLOW="" C_SUPER="" C_DIM="" C_BOLD=""
fi

color_for_level() {
  case "$1" in
    0) printf "%s" "$C_HYPER" ;;
    1) printf "%s" "$C_FAST"  ;;
    2) printf "%s" "$C_MOD"   ;;
    3) printf "%s" "$C_SLOW"  ;;
    4) printf "%s" "$C_SUPER" ;;
    *) printf "%s" "$C_RESET" ;;
  esac
}

label_for_level() {
  case "$1" in
    0) printf "hyper fast" ;;
    1) printf "fast" ;;
    2) printf "moderate" ;;
    3) printf "slow" ;;
    4) printf "super slow" ;;
    *) printf "unknown" ;;
  esac
}

print_metric() {
  local name="$1" raw="$2" seconds="$3" phase="$4"
  local lvl c lbl
  lvl="$(classify "$phase" "$seconds")"
  c="$(color_for_level "$lvl")"
  lbl="$(label_for_level "$lvl")"
  
  local max_width=19
  local name_with_colon="${name}:"
  local name_len=${#name_with_colon}
  local dots_needed=$((max_width - name_len))
  local dots=""
  
  if [[ $dots_needed -gt 0 ]]; then
    dots=$(printf "%*s" $dots_needed "" | tr ' ' '.')
  fi
  
  printf "%s%s %s%s%s %s(%.3fs, %s)%s\n" \
    "$name_with_colon" "$dots" \
    "$c" "$raw" "$C_RESET" \
    "$C_DIM" "$seconds" "$lbl" "$C_RESET"
}

# Initialize boot analysis data
_init_boot_analysis() {
  an_out="$(systemd-analyze 2>/dev/null || true)"
  if [[ -z "$an_out" ]]; then
    echo "systemd-analyze returned no output" >&2
    return 1
  fi

  startup_line="$(printf '%s\n' "$an_out" | awk '/^Startup finished in /{print; exit}')"
  if [[ -z "$startup_line" ]]; then
    echo "Could not find: Startup finished in ..." >&2
    return 1
  fi

  # Extract raw segments
  fw_raw="$(sed -n 's/.*in \([0-9.]\+s\) (firmware).*/\1/p' <<<"$startup_line")"
  ld_raw="$(sed -n 's/.*+ \([0-9.]\+s\) (loader).*/\1/p' <<<"$startup_line")"
  kn_raw="$(sed -n 's/.*+ \([0-9.]\+s\) (kernel).*/\1/p' <<<"$startup_line")"
  us_raw="$(sed -n 's/.*+ \([0-9.]\+s\) (userspace).*/\1/p' <<<"$startup_line")"
  tot_raw="$(sed -n 's/.*= \(.*\)$/\1/p' <<<"$startup_line")"

  # Graphical target line
  graph_line="$(printf '%s\n' "$an_out" | awk '/graphical\.target reached/{print; exit}')"
  graph_raw=""
  if [[ -n "$graph_line" ]]; then
    graph_raw="$(sed -n 's/.*reached after \([0-9.]\+s\) in userspace.*/\1/p' <<<"$graph_line")"
  fi

  # Convert to seconds
  fw_s="$(to_seconds "$fw_raw")"
  ld_s="$(to_seconds "$ld_raw")"
  kn_s="$(to_seconds "$kn_raw")"
  us_s="$(to_seconds "$us_raw")"
  tot_s="$(to_seconds "$tot_raw")"
  
  # Export values for summary
  export AUDIT_BOOT_TOTAL_TIME="$tot_s"
  export AUDIT_BOOT_FIRMWARE_TIME="$fw_s"
  export AUDIT_BOOT_LOADER_TIME="$ld_s"
  export AUDIT_BOOT_KERNEL_TIME="$kn_s"
  export AUDIT_BOOT_USERSPACE_TIME="$us_s"
  
  if [[ -n "$graph_raw" ]]; then
    graph_s="$(to_seconds "$graph_raw")"
    export AUDIT_BOOT_GRAPHICAL_TIME="$graph_s"
  else
    export AUDIT_BOOT_GRAPHICAL_TIME=""
  fi
  
  return 0
}

get_boot_analysis() {
  # Note: _init_boot_analysis() should be called before this function
  # to ensure variables are exported and available
  
  print_metric "Firmware"            "$fw_raw" "$fw_s" "firmware"
  print_metric "Loader"              "$ld_raw" "$ld_s" "loader"
  print_metric "Kernel"              "$kn_raw" "$kn_s" "kernel"
  print_metric "Userspace"           "$us_raw" "$us_s" "userspace"
  print_metric "Total"               "$tot_raw" "$tot_s" "total"

  if [[ -n "$graph_raw" ]]; then
    # graph_s was already calculated in _init_boot_analysis if graph_raw exists
    if [[ -z "$graph_s" ]]; then
      graph_s="$(to_seconds "$graph_raw")"
    fi
    echo
    print_metric "Graphical target" "$graph_raw" "$graph_s" "graphical"
  fi
}

get_slow_services() {
  # Get slow services - use console limit for display, log limit for logging
  local console_limit=$(get_console_limit)
  local log_limit=$(get_log_limit)
  
  if [[ -n "$console_limit" ]]; then
    SLOW_SERVICES=$(systemd-analyze blame --no-pager 2>/dev/null | head -n "$console_limit")
  else
    SLOW_SERVICES=$(systemd-analyze blame --no-pager 2>/dev/null)
  fi
  
  echo "$SLOW_SERVICES"
  
  if type log_detailed >/dev/null 2>&1; then
    if [[ -n "$log_limit" ]]; then
      SLOW_SERVICES_LOG=$(systemd-analyze blame --no-pager 2>/dev/null | head -n "$log_limit")
    else
      SLOW_SERVICES_LOG=$(systemd-analyze blame --no-pager 2>/dev/null)
    fi
    log_detailed "=== Slowest Boot Services ==="
    log_detailed "$SLOW_SERVICES_LOG"
  fi
}

# Test case 1: Boot analysis
if command -v systemd-analyze >/dev/null 2>&1; then
    # Initialize boot analysis first (this exports the time variables)
    # We need to call this directly, not in a subshell, so exports persist
    if _init_boot_analysis 2>/dev/null; then
        # Now get the formatted output for display
        BOOT_OUTPUT=$(get_boot_analysis 2>&1)
        BOOT_RC=$?
        if [[ $BOOT_RC -eq 0 ]]; then
            echo "$BOOT_OUTPUT" | show_indented_details
            log_detailed "=== Boot Analysis ==="
            log_detailed "$BOOT_OUTPUT"
            echo "" | show_indented_details
        fi
        
        # Test case 1a: Total boot time
        # Check if value exists and is not zero
        if [[ -n "$AUDIT_BOOT_TOTAL_TIME" ]] && [[ "$AUDIT_BOOT_TOTAL_TIME" != "0" ]] && [[ "$AUDIT_BOOT_TOTAL_TIME" != "0.000" ]]; then
            TOTAL_TIME=$(echo "$AUDIT_BOOT_TOTAL_TIME" | awk '{printf "%.1f", $1}')
            if (( $(echo "$TOTAL_TIME < 35" | bc -l 2>/dev/null || echo 0) )); then
                pass "Total boot time acceptable: ${TOTAL_TIME}s"
            elif (( $(echo "$TOTAL_TIME < 50" | bc -l 2>/dev/null || echo 0) )); then
                warn "Total boot time moderate: ${TOTAL_TIME}s"
            elif (( $(echo "$TOTAL_TIME > 75" | bc -l 2>/dev/null || echo 0) )); then
                fail "Total boot time too slow: ${TOTAL_TIME}s"
            else
                warn "Total boot time slow: ${TOTAL_TIME}s"
            fi
        else
            skip "Total boot time check (value not available or zero)"
        fi
        
        # Test case 1b: Graphical target time
        if [[ -n "$AUDIT_BOOT_GRAPHICAL_TIME" ]] && [[ "$AUDIT_BOOT_GRAPHICAL_TIME" != "" ]] && [[ "$AUDIT_BOOT_GRAPHICAL_TIME" != "0" ]] && [[ "$AUDIT_BOOT_GRAPHICAL_TIME" != "0.000" ]]; then
            GRAPHICAL_TIME=$(echo "$AUDIT_BOOT_GRAPHICAL_TIME" | awk '{printf "%.1f", $1}')
            if (( $(echo "$GRAPHICAL_TIME < 12" | bc -l 2>/dev/null || echo 0) )); then
                pass "Graphical target time acceptable: ${GRAPHICAL_TIME}s"
            elif (( $(echo "$GRAPHICAL_TIME < 25" | bc -l 2>/dev/null || echo 0) )); then
                warn "Graphical target time moderate: ${GRAPHICAL_TIME}s"
            else
                fail "Graphical target time too slow: ${GRAPHICAL_TIME}s"
            fi
        else
            skip "Graphical target time check (value not available or zero)"
        fi
    else
        skip "Boot analysis initialization failed"
        log_detailed "=== Boot Analysis Initialization Failed ==="
    fi
    
    # Test case 2: Slow services
    echo -e "\n${CYAN}Slowest boot services:\n${NC}" | show_indented_details
    SLOW_OUTPUT=$(get_slow_services 2>&1)
    SLOW_RC=$?
    if [[ $SLOW_RC -eq 0 ]]; then
        echo "$SLOW_OUTPUT" | show_indented_details
        echo "" | show_indented_details 
        if ! type log_detailed >/dev/null 2>&1 || ! echo "$SLOW_OUTPUT" | grep -q "Slowest Boot Services"; then
            log_detailed "=== Slowest Boot Services ==="
            log_detailed "$SLOW_OUTPUT"
        fi
    else
        skip "Slow services list (command failed)"
        log_detailed "=== Slow Services Failed ==="
        log_detailed "$SLOW_OUTPUT"
    fi
else
    skip "Boot analysis (systemd-analyze not available)"
fi

# Test case 3: Failed system units
FAILED_SERVICES=$($SYSTEMCTL_FAILED_BASE 2>/dev/null | wc -l)
if [[ $FAILED_SERVICES -eq 0 ]]; then
    pass "No failed system services"
else
    fail "Found $FAILED_SERVICES failed service(s)"
    FAILED_LIST=$($SYSTEMCTL_FAILED_BASE 2>/dev/null)
    echo -e "\n${RED}Failed services:${NC}" | show_indented_details
    echo "$FAILED_LIST" | show_indented_details
    echo "" | show_indented_details
    log_detailed "=== Failed Services ==="
    log_detailed "$FAILED_LIST"
    echo "" | show_indented_details
fi

# Test case 4: Services that failed to start
FAILED_START=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "Failed to start|Failed to activate" | wc -l)
if [[ $FAILED_START -eq 0 ]]; then
    pass "No services failed to start during boot"
else
    fail "Found $FAILED_START service(s) that failed to start"
    FAILED_START_DETAILS_FULL=$($JOURNALCTL_BASE 2>/dev/null | grep -iE "Failed to start|Failed to activate")
    FAILED_START_DETAILS_CONSOLE=$(echo "$FAILED_START_DETAILS_FULL" | limit_for_console)
    FAILED_START_DETAILS_LOG=$(echo "$FAILED_START_DETAILS_FULL" | limit_for_log)
    echo -e "\n${RED}Services that failed to start:${NC}" | show_indented_details
    echo "$FAILED_START_DETAILS_CONSOLE" | show_indented_details
    log_detailed "=== Services Failed to Start ==="
    log_detailed "$FAILED_START_DETAILS_LOG"
fi

echo ""
