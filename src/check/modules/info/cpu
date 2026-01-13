# 4. CPU Information
function cpu_info {
    # lscpu displays information about the CPU architecture, cores, threads, cache, and more.
    echo -e "${LB}${CYAN}[#] CPU Information ${BLUE}(lscpu)${RT}${LB}"
    pprint "lscpu"
}

# CPU Topology and Performance
function cpu_topology {
    echo -e "${LB}${CYAN}[#] CPU Topology and Performance${RT}${LB}"
    
    if command -v lscpu >/dev/null 2>&1; then
        echo -e "${WHITE2}CPU Topology:${RT}"
        sockets=$(lscpu | grep "^Socket(s):" | awk '{print $2}' || echo "N/A")
        cores=$(lscpu | grep "^Core(s) per socket:" | awk '{print $4}' || echo "N/A")
        threads=$(lscpu | grep "^Thread(s) per core:" | awk '{print $4}' || echo "N/A")
        total_cores=$(lscpu | grep "^CPU(s):" | awk '{print $2}' || echo "N/A")
        
        echo -e "  Sockets: $sockets"
        echo -e "  Cores per socket: $cores"
        echo -e "  Threads per core: $threads"
        echo -e "  Total CPU threads: $total_cores"
        echo ""
        
        # CPU frequency governor
        if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
            governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")
            echo -e "${WHITE2}CPU Frequency Governor:${RT} $governor"
            
            # Min/Max frequencies
            if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq ]] && [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq ]]; then
                min_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null)
                max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
                min_freq_mhz=$((min_freq / 1000))
                max_freq_mhz=$((max_freq / 1000))
                echo -e "  Min: ${min_freq_mhz} MHz, Max: ${max_freq_mhz} MHz"
            fi
            echo ""
        fi
        
        # Load averages
        if [[ -f /proc/loadavg ]]; then
            load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
            echo -e "${WHITE2}Load Averages:${RT} 1min: $(echo $load | awk '{print $1}'), 5min: $(echo $load | awk '{print $2}'), 15min: $(echo $load | awk '{print $3}')"
            echo ""
        fi
        
        # Virtualization flags
        if command -v lscpu >/dev/null 2>&1; then
            virt_flag=$(lscpu | grep -i "Virtualization:" | awk '{print $2}' || echo "N/A")
            hypervisor=$(lscpu | grep -i "Hypervisor vendor:" | awk '{print $3}' || echo "N/A")
            echo -e "${WHITE2}Virtualization:${RT}"
            echo -e "  Flag: $virt_flag"
            if [[ "$hypervisor" != "N/A" ]] && [[ -n "$hypervisor" ]]; then
                echo -e "  Hypervisor: $hypervisor (running under virtualization)"
            else
                echo -e "  Hypervisor: None (bare metal)"
            fi
        fi
    else
        echo -e "${YELLOW}[!] lscpu not available${RT}"
    fi
}

# Top CPU consumers
function cpu_top_consumers {
    echo -e "${LB}${CYAN}[#] Top CPU Consumers${RT}${LB}"
    if command -v ps >/dev/null 2>&1; then
        echo -e "${WHITE2}Top 10 processes by CPU usage:${RT}"
        pprint "ps aux --sort=-%cpu | head -n 11"
    else
        echo -e "${YELLOW}[!] ps not available${RT}"
    fi
}
