#!/usr/bin/env python3

import requests
import socket
import psutil
import locale
import struct
import re
import platform
import subprocess
import argparse
from colorama import init, Fore, Style, Back

init(autoreset=True)

def color_text(text, color, attrs=None):
    color_code = getattr(Fore, color.upper(), Fore.RESET)
    style_code = ''.join(getattr(Style, attr.upper(), '') for attr in (attrs or []))
    return f"{style_code}{color_code}{text}{Style.RESET_ALL}"

def check_vpn_usage():
    try:
        # Fetch public IP information
        response = requests.get('https://ipinfo.io/json')
        data = response.json()
        ip = data.get('ip', 'Not available')
        hostname = data.get('hostname', 'No hostname')
        
        # Basic check to see if the hostname suggests a VPN or hosting provider
        vpn_indicators = ['vpn', 'vps', 'hosting']
        is_vpn = any(indicator in hostname.lower() for indicator in vpn_indicators)
        
        print(f"IP: {ip}")
        print(f"Hostname: {hostname}")
        print(f"VPN Likely: {'Yes' if is_vpn else 'No'}")
        
    except Exception as e:
        print(f"Error checking VPN usage: {e}")

def get_ipv6_address():
    ipv6 = 'Not Detected'
    for interface, snics in psutil.net_if_addrs().items():
        for snic in snics:
            if snic.family == socket.AF_INET6:
                ipv6_address = snic.address.split('%')[0]  # Split to remove interface scope identifier if present
                if ipv6_address == '::1':
                    continue  # Skip loopback address
                if not ipv6_address.startswith('fe80'):
                    ipv6 = ipv6_address
                    break
        if ipv6 != 'Not Detected':
            break  # Exit early if a valid IPv6 address is found

    if ipv6 == 'Not Detected':
        print(f"\n[-] IPv6 " + color_text(f"     {ipv6}", 'WHITE'))
    else:
        print(f"\n{Style.BRIGHT}[+] IPv6 {Style.RESET_ALL}" + color_text(f"     {ipv6}", 'YELLOW'))

def get_public_ip_info():
    try:
        response = requests.get('https://ipinfo.io/json', timeout=3)
        data = response.json()
        ipv4 = data.get('ip', 'Not available')
        isp = data.get('org', 'Not available')
        hostname = data.get('hostname', 'No hostname')
        country = data.get('country', 'Not available')
        region = data.get('region', 'Not available')
        city = data.get('city', 'Not available')
        loc = data.get('loc', 'No location available')
        org = data.get('org', 'No organization available')
        postal = data.get('postal', 'No postal code available')
        timezone = data.get('timezone', 'No timezone available')
        
        # Attempt to get the local system's locale setting
        locale.setlocale(locale.LC_ALL, '')  # Set the locale for all categories to the user's default setting (environment)
        local_locale = locale.getlocale()  # Get the current locale setting

        # Common VPN/Hosting/Cloud indicators
        vpn_indicators = [
            'VPN', 'VPS', 'Hosting', 'Colo', 'Datacenter', 'DC', 'Server',
            'Amazon', 'AWS', 'Azure', 'GCP', 'Google', 'Microsoft', 'Tailscale',
            'DigitalOcean', 'Linode', 'OVH', 'Hetzner', 'Contabo', 'Oracle',
            'Netcup', 'UpCloud', 'Vultr', 'Scaleway', 'Kamatera', 'IBMCloud',
            'Fortinet', 'Cisco', 'Juniper', 'Palo', 'Alto', 'GlobalProtect', 'AnyConnect',
            'SonicWall', 'Checkpoint', 'Citrix', 'NetScaler', 'F5', 'BIG-IP',
            'NordVPN', 'ExpressVPN', 'Surfshark', 'Proton', 'IPVanish', 'TunnelBear',
            'PIA', 'PrivateInternetAccess', 'Windscribe', 'CyberGhost', 'Hotspot', 'Datacamp', 'Datapacket'
        ]


        # Check hostname or ISP name for VPN/Cloud hints
        def tokenize(s):
            return set(re.findall(r'\w+', s.lower())) if isinstance(s, str) else set()
        
        vpn_indicators_lower = {i.lower() for i in vpn_indicators}
        
        normalized_isp = isp.lower()
        normalized_hostname = hostname.lower()

        # Avoid false positives from ultra-short keywords like "dc", "a", "s", etc.
        safe_indicators = [i.lower() for i in vpn_indicators if len(i) >= 4]

        def get_word_tokens(text):
            return set(re.findall(r'\b\w+\b', text.lower())) if isinstance(text, str) else set()

        isp_words = get_word_tokens(isp)
        hostname_words = get_word_tokens(hostname)
        safe_indicators = {i.lower() for i in vpn_indicators if len(i) >= 4}

        is_vpn_isp = bool(safe_indicators.intersection(isp_words))
        is_vpn_hostname = bool(safe_indicators.intersection(hostname_words))

        # Optional: compare region with local system locale (e.g. timezone or lang)
        local_lang = local_locale[0] if local_locale and isinstance(local_locale, tuple) else ''
        is_region_mismatch = region and local_lang and region.lower() not in local_lang.lower()

        if is_vpn_hostname or is_vpn_isp:
            # Strong match → GREEN
            print(f"{Style.BRIGHT}[+] IPv4 {Style.RESET_ALL}" + color_text(f"     {ipv4}", 'GREEN') + f" {Style.DIM}(Connected to VPN){Style.RESET_ALL}\n")

            if is_vpn_hostname:
                print(f" |  {Style.DIM}          Hostname matches known VPN/provider")
            if is_vpn_isp:
                print(f" |  {Style.DIM}          ISP matches known VPN/cloud")
            if is_region_mismatch:
                print(f" |  {Style.DIM}          Region mismatch with system locale")

        elif is_region_mismatch:
            # Weak match → YELLOW
            print(f"{Style.BRIGHT}[+] IPv4 {Style.RESET_ALL}" + color_text(f"     {ipv4}", 'YELLOW') + f" {Style.DIM}(Public IP may be exposed){Style.RESET_ALL}\n")
            print(f" |  {Style.DIM}          No known VPN indicators found")
            print(f" |  {Style.DIM}          Region mismatch with system locale")

        else:
            # No match → RED
            print(f"{Style.BRIGHT}[+] IPv4 {Style.RESET_ALL}" + color_text(f"     {ipv4}", 'RED') + f" {Style.DIM}(No VPN detected){Style.RESET_ALL}\n")


        get_ipv6_address()
        print(f"    ")
        print(f" |  {Style.DIM}INTRNSP{Style.RESET_ALL}   {isp}")
        print(f" |  {Style.DIM}HOSTNME{Style.RESET_ALL}   {hostname}")
        print(f" |  {Style.DIM}CNTRYCD   {country}{Style.RESET_ALL}")
        print(f" |  {Style.DIM}REGIONN   {region}{Style.RESET_ALL}")
        print(f" |  {Style.DIM}CITYNAM   {city}{Style.RESET_ALL}")
        print(f" |  {Style.DIM}POSTCOD   {postal}{Style.RESET_ALL}")
        print(f" |  {Style.DIM}TIMEZON   {timezone}{Style.RESET_ALL}")
        print(f" |  {Style.DIM}COORDIN   {loc}{Style.RESET_ALL}")


    except requests.exceptions.ConnectionError:
    # This handles connection errors, like no internet access
        print(f"{color_text('[!]', 'YELLOW')} {color_text('DISCONNECTED', 'RED')}")
    except requests.exceptions.Timeout:
        # Handles timeouts
        print(f"{color_text('[!]', 'YELLOW')} {color_text('CONNECTION TIMEOUT', 'RED')}")
    except socket.gaierror:
        # Handles general network errors like name resolution failures
        print(f"{color_text('[!]', 'YELLOW')} {color_text('TEMPORARY FAILURE IN NAME RESOLUTION', 'RED')}")
    except Exception as e:
        # Catch any other exception and print it
        print(f"{color_text('[!]', 'YELLOW')} {color_text(f'ERROR: {e}', 'RED')}")

        #print(" VPN Likely:     Relying on external sources: " + (color_text('Yes', 'GREEN') if is_vpn_external else color_text('No', 'RED')) + ", Utilizing internal data: " + (color_text('Yes', 'GREEN') if is_vpn_internal else color_text('No', 'RED')))
    # except requests.exceptions.Timeout:
    #     print(color_text(" E ", 'RED') + " Not Connected.") #Timeout reached while trying to fetch the public IP address. Are you connected to internet?")
    #except Exception as e:
        #print(color_text(" E", 'RED') + f" Timeout reached while trying to fetch the public IP address. Are you connected to internet? \n\n" + color_text(f"   {e}", 'WHITE', attrs=['CONCEALED']))

def get_subnet(ip, netmask):
    """
    Calculate the network address (subnet) and CIDR notation based on IP and netmask.
    Handle loopback address separately.
    """
    # Special handling for loopback addresses
    if ip.startswith('127.'):
        return f"127.0.0.0/8"
    
    try:
        # Convert IP and netmask to binary form
        ip_bin = struct.unpack('!L', socket.inet_aton(ip))[0]
        netmask_bin = struct.unpack('!L', socket.inet_aton(netmask))[0]
        
        # Calculate the network address by performing bitwise AND
        subnet_bin = ip_bin & netmask_bin
        subnet = socket.inet_ntoa(struct.pack('!L', subnet_bin))
        
        # Calculate the CIDR prefix length by counting the number of 1s in the netmask
        cidr = bin(netmask_bin).count('1')
        
        return f"{subnet}/{cidr}"
    except (OSError, ValueError) as e:
        # Handle invalid IP or netmask formats
        return "Invalid IP or Netmask"

def get_default_gateway():
    """
    Get the default gateway from psutil.
    """
    gateways = psutil.net_if_addrs()
    for iface, snics in gateways.items():
        for snic in snics:
            if snic.family == socket.AF_INET and snic.address != '127.0.0.1':
                return snic.address
    return "No Gateway Found"

def print_network_info():
    os_system = platform.system()
    interfaces = psutil.net_if_addrs()  # Get network interface addresses

    if os_system == "Linux":
        cmd = "ip -br -4 addr show"
    elif os_system == "Windows":
        cmd = "ipconfig"
    elif os_system == "Darwin":  # macOS
        cmd = "ifconfig"
    else:
        print("Unsupported OS")
        return

    result = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if result.stderr:
        print("Error:", result.stderr)
        return

    previous_line = ""
    # Lists to store interfaces by category
    loopback_interfaces = []
    vpn_interfaces = []
    ethernet_interfaces = []
    bridge_interfaces = []
    docker_interfaces = []
    other_connections = []
    

    if os_system in ["Linux", "Darwin"]:
        for line in result.stdout.split('\n'):
            if line:
                if os_system == "Linux":
                    parts = line.split()
                    iface = parts[0].split("@")[0]
                    ip_cidr = parts[2] if len(parts) > 2 else "N/A"
                    # Extract IP without CIDR
                    ip_only = ip_cidr.split('/')[0]
                elif os_system == "Darwin":  # Parsing for macOS
                    if "inet " in line and not line.strip().startswith("inet6"):
                        parts = line.split()
                        ip_cidr = parts[1]
                        ip_only = ip_cidr.split('/')[0]
                        iface = previous_line.split(":")[0] if previous_line else "Unknown"
                else:
                    continue

                # Fetch MAC address, netmask, and subnet with CIDR
                mac = 'N/A'
                netmask = 'N/A'
                subnet_with_cidr = 'N/A'
                if iface in interfaces:
                    for snic in interfaces[iface]:
                        if snic.family == psutil.AF_LINK:  # MAC Address
                            mac = snic.address
                        if snic.family == socket.AF_INET:  # IPv4 address
                            netmask = snic.netmask
                            # Pass IP without CIDR to get_subnet()
                            subnet_with_cidr = get_subnet(ip_only, netmask)

                gateway = get_default_gateway()  # Get the gateway

                # Categorize interfaces
                if iface == "lo" or iface == "lo0":  # "lo0" for macOS Loopback Interface
                    loopback_interfaces.append((iface, ip_only, mac, subnet_with_cidr, netmask, gateway))

                elif re.match(r'^eth[0-9]+$', iface) or "en" in iface:  # Ethernet interfaces
                    ethernet_interfaces.append((iface, ip_only, mac, subnet_with_cidr, netmask, gateway))

                elif iface.startswith('br-'):  # Bridge interfaces (e.g., br-b53a08e16e0e)
                    bridge_interfaces.append((iface, ip_only, mac, subnet_with_cidr, netmask, gateway))

                elif re.match(r'^docker[0-9]+$', iface):
                    docker_interfaces.append((iface, ip_only, mac, subnet_with_cidr, netmask, gateway))

                elif iface == "tun0":  # VPN interface
                    vpn_interfaces.append((iface, ip_only, mac, subnet_with_cidr, netmask, gateway))

                else:
                    other_connections.append((iface, ip_only, mac, subnet_with_cidr, netmask, gateway))

            previous_line = line  # Keep track of the previous line for macOS parsing

        # Print categorized interfaces in desired order

        # for iface, ip, mac, subnet, netmask, gateway in loopback_interfaces:
        #     print(f"\n {Style.BRIGHT}[+] LOOPBACK {Style.RESET_ALL} {color_text(iface, 'MAGENTA')}")
        #     print(f"  ")
        #     print(f"  |  {Style.DIM}MACAD{Style.RESET_ALL}     {color_text(mac, 'BLUE')}")
        #     print(f"  |  {Style.DIM}IPADD{Style.RESET_ALL}     {color_text(ip, 'CYAN')}")
        #     print(f"  |  {Style.DIM}SUBNET    {subnet}{Style.RESET_ALL}")
        #     print(f"  |  {Style.DIM}GATEWAY   {gateway}{Style.RESET_ALL}")
        #     print(f"  |  {Style.DIM}NETMASK   {netmask}{Style.RESET_ALL}")

        # Interface type → label map
        interface_labels = {
            "tailscale0": ("TUNNEL", "Tailscale VPN"),
            "vmnet0": ("BRIDGE", "VMware bridged network"),
            "vmnet1": ("BRIDGE", "VMware Host-only"),
            "vmnet8": ("BRIDGE", "VMware NAT network"),
            "virbr0": ("BRIDGE", "libvirt (KVM) NAT bridge"),
            "wlan0": ("ETHERNET", "Wi-Fi adapter"),
            "eth0": ("ETHERNET", "Main Ethernet"),
            "eth1": ("ETHERNET", "Secondary Ethernet"),
            "lo": ("OTHER", "Loopback interface"),
        }

        # Use this method to format each group dynamically
        def print_interface_block(group_name, iface_list, color):
            for iface, ip, mac, subnet, netmask, gateway in iface_list:
                label, desc = interface_labels.get(iface, (group_name.upper(), ""))
                print(f"\n{Style.BRIGHT}[+] {label:<9}{Style.RESET_ALL} {color_text(iface, color)} {Style.DIM} ({desc}){Style.RESET_ALL}\n")
                print(f" |  {Style.DIM}MACAD{Style.RESET_ALL}     {color_text(mac, 'BLUE')}")
                print(f" |  {Style.DIM}IPADD{Style.RESET_ALL}     {color_text(ip, 'CYAN')}")
                print(f" |  {Style.DIM}SUBNET    {subnet}{Style.RESET_ALL}")
                print(f" |  {Style.DIM}GATEWAY   {gateway}{Style.RESET_ALL}")
                #print(f" |  {Style.DIM}NETMASK   {netmask}{Style.RESET_ALL}")

        # Call grouped output
        print_interface_block("vpn", vpn_interfaces, 'GREEN')
        print_interface_block("ethernet", ethernet_interfaces, 'LIGHTGREEN_EX')
        print_interface_block("bridge", bridge_interfaces, 'MAGENTA')
        print_interface_block("docker", docker_interfaces, 'MAGENTA')
        print_interface_block("other", other_connections, 'RED')


    elif os_system == "Windows":
        print(result.stdout)

def flush_network():
    os_system = platform.system()
    try:
        if os_system == "Linux":
            subprocess.run("sudo ipconfig /release", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("sudo ipconfig /renew", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("sudo systemctl restart vmware-networks.service", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("sudo dhclient -r", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("sudo dhclient", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif os_system == "Windows":
            subprocess.run("ipconfig /release", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("ipconfig /renew", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        elif os_system == "Darwin":  # macOS
            subprocess.run("sudo ipconfig set en0 BOOTP", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("sudo ipconfig set en0 DHCP", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("sudo ifconfig en0 down", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run("sudo ifconfig en0 up", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            print("Unsupported OS for flushing network.")
            return
        print("Network flushed successfully.")
    except Exception as e:
        print(f"Error flushing network: {e}")

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description="Network Information Tool")
    parser.add_argument('--flush', action='store_true', help='Flush the network settings')

    args = parser.parse_args()

    if args.flush:
        flush_network()
    else:
        print(f"\n{Back.WHITE}{Fore.BLACK}[#] Internal IP Address Information {Style.RESET_ALL}")
        #print(color_text(f"\n Internal IP Address Information\n", 'CYAN'))
        print_network_info()
        print(f"\n{Back.WHITE}{Fore.BLACK}[#] External IP Address Information {Style.RESET_ALL}\n")
        #print(color_text(f"\n External IP Address Information\n", 'CYAN'))
        get_public_ip_info()
        
        
        
