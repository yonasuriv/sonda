# 10. Network Information
function network_info {
    # ip addr show displays IP address information for all network interfaces.
    echo -e "${LB}${CYAN}[#] Network Interfaces ${BLUE}(ip addr show)${RT}${LB}"
    pprint "ip addr show"

    # ip route show displays the current routing table.
    echo -e "${LB}${CYAN}[#] Routing Table ${BLUE}(ip route show)${RT}${LB}"
    pprint "ip route show"
}

# Network Identity and Connectivity Summary
function network_identity {
    echo -e "${LB}${CYAN}[#] Network Identity and Connectivity${RT}${LB}"
    
    # Primary IPv4
    if command -v ip >/dev/null 2>&1; then
        primary_ipv4=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.' | head -n 1 || echo "N/A")
        echo -e "${WHITE2}Primary IPv4:${RT} $primary_ipv4"
        
        # Primary IPv6
        primary_ipv6=$(ip -6 addr show | grep -oP '(?<=inet6\s)[0-9a-f:]+' | grep -v '^::1$' | grep -v '^fe80:' | head -n 1 || echo "N/A")
        if [[ "$primary_ipv6" != "N/A" ]]; then
            echo -e "${WHITE2}Primary IPv6:${RT} $primary_ipv6"
        fi
        
        # Interface names and link state
        echo -e "${WHITE2}Active Interfaces:${RT}"
        ip -br link show | grep -v "lo" | awk '{print "  " $1 " (" $2 ")"}'
        echo ""
        
        # Default gateway
        default_gateway=$(ip route | grep default | awk '{print $3}' | head -n 1 || echo "N/A")
        echo -e "${WHITE2}Default Gateway:${RT} $default_gateway"
    else
        echo -e "${YELLOW}[!] ip command not available${RT}"
    fi
    
    # DNS servers
    echo -e "${WHITE2}DNS Servers:${RT}"
    if [[ -f /etc/resolv.conf ]]; then
        dns_servers=$(grep -E "^nameserver" /etc/resolv.conf | awk '{print $2}' || echo "N/A")
        if [[ "$dns_servers" != "N/A" ]]; then
            echo "$dns_servers" | while read -r dns; do
                echo -e "  $dns"
            done
        else
            echo -e "  N/A"
        fi
    else
        echo -e "  N/A"
    fi
    
    # Check systemd-resolved if available
    if command -v resolvectl >/dev/null 2>&1; then
        resolved_dns=$(resolvectl status 2>/dev/null | grep "DNS Servers:" | sed 's/DNS Servers://' | xargs || echo "")
        if [[ -n "$resolved_dns" ]]; then
            echo -e "${WHITE2}systemd-resolved DNS:${RT} $resolved_dns"
        fi
    fi
}

# Active connections summary
function network_connections_summary {
    echo -e "${LB}${CYAN}[#] Active Connections Summary${RT}${LB}"
    
    if command -v ss >/dev/null 2>&1; then
        # TCP connections
        tcp_est=$(ss -tn state established 2>/dev/null | wc -l || echo "0")
        tcp_listen=$(ss -tln 2>/dev/null | wc -l || echo "0")
        echo -e "${WHITE2}TCP Connections:${RT}"
        echo -e "  Established: $tcp_est"
        echo -e "  Listening: $tcp_listen"
        
        # UDP connections
        udp_listen=$(ss -uln 2>/dev/null | wc -l || echo "0")
        echo -e "${WHITE2}UDP Connections:${RT}"
        echo -e "  Listening: $udp_listen"
        
        # Top listening ports
        echo -e "${WHITE2}Top Listening Ports:${RT}"
        ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | cut -d':' -f2 | sort | uniq -c | sort -rn | head -n 5 | awk '{print "  Port " $2 ": " $1 " connections"}'
    elif command -v netstat >/dev/null 2>&1; then
        tcp_est=$(netstat -tn 2>/dev/null | grep ESTABLISHED | wc -l || echo "0")
        tcp_listen=$(netstat -tln 2>/dev/null | wc -l || echo "0")
        echo -e "${WHITE2}TCP Connections:${RT}"
        echo -e "  Established: $tcp_est"
        echo -e "  Listening: $tcp_listen"
    else
        echo -e "${YELLOW}[!] ss or netstat not available${RT}"
    fi
}

# 13. Running Network Connections
function network_connections {
    # netstat -tuln shows active TCP and UDP network connections.
    echo -e "${LB}${CYAN}[#] Active Network Connections ${BLUE}(netstat -tuln)${RT}${LB}"
    pprint "netstat -tuln"
}
