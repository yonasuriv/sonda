#!/usr/bin/env bash
# Module loader - dynamically loads phase modules

# Load a phase module
load_phase_module() {
    local phase_num="$1"
    local phase_file="$AUDIT_MODULES_DIR/${phase_num}_*.sh"
    
    # Find the module file
    local module_file=""
    for file in $phase_file; do
        if [[ -f "$file" ]]; then
            module_file="$file"
            break
        fi
    done
    
    if [[ -z "$module_file" || ! -f "$module_file" ]]; then
        warn "Phase module not found: $phase_num"
        return 1
    fi
    
    # Source the module
    source "$module_file"
    return $?
}

# Load all phase modules in order
load_all_phases() {
    local phase_num
    for phase_num in 00 01 02 03 04 05 06 07 08 09 10 11 12; do
        # Check if phase should be skipped entirely
        local skip_phase=false
        if [[ -n "$AUDIT_CONSOLE_SKIP_PHASES" ]]; then
            for skip_phase_id in $AUDIT_CONSOLE_SKIP_PHASES; do
                if [[ "$phase_num" == "$skip_phase_id" ]]; then
                    skip_phase=true
                    break
                fi
            done
        fi
        # Also check log skip phases
        if [[ "$skip_phase" == false ]] && [[ -n "$AUDIT_LOG_SKIP_PHASES" ]]; then
            for skip_phase_id in $AUDIT_LOG_SKIP_PHASES; do
                if [[ "$phase_num" == "$skip_phase_id" ]]; then
                    skip_phase=true
                    break
                fi
            done
        fi
        
        # Skip the phase if it's in either skip list
        if [[ "$skip_phase" == true ]]; then
            continue
        fi
        
        # Load the phase module
        load_phase_module "$phase_num"
    done
}

# Export functions
export -f load_phase_module load_all_phases
