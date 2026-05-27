#!/bin/bash

# Fetch the hostname from /etc/hostname
hostname=$(cat /etc/hostname)

# Fetch static hostname from /proc/sys/kernel/hostname
static_hostname=$(cat /proc/sys/kernel/hostname)

# Fetch machine ID
machine_id=$(cat /etc/machine-id)

# Fetch boot ID
boot_id=$(cat /proc/sys/kernel/random/boot_id)

# Fetch chassis type from /sys/class/dmi/id/chassis_type or chassis_vendor if available
chassis_type=$(cat "/sys/class/dmi/id/chassis_type")
chassis_vendor=$(cat "/sys/class/dmi/id/chassis_vendor")

# Fetch distribution information from /etc/os-release
os_name=$(grep "^NAME=" /etc/os-release |  cut -d '=' -f2 |  tr -d '"')
os_version=$(grep "^VERSION=" /etc/os-release |  cut -d '=' -f2 |  tr -d '"')
os_pretty_name=$(grep "^PRETTY_NAME=" /etc/os-release |  cut -d '=' -f2 |  tr -d '"')

# Fetch distribution type (ID) and parent distribution (ID_LIKE)
distro_type=$(grep "^ID=" /etc/os-release |  cut -d '=' -f2 |  tr -d '"')
distro_base=$(grep "^ID_LIKE=" /etc/os-release |  cut -d '=' -f2 |  tr -d '"')

# Fetch kernel version from /proc/version
kernel_version=$(cat /proc/version |  awk '{print $3}')
kernel_name=$(uname -s)

# Fetch architecture from uname
architecture=$(uname -m)

# Fetch kernel release and version from /proc/sys/kernel
kernel_release=$(cat /proc/sys/kernel/osrelease)
kernel_version_full=$(cat /proc/sys/kernel/version)

# Fetch system uptime in a human-readable format (using /proc/uptime)
uptime_seconds=$(awk '{print $1}' /proc/uptime)
uptime_days=$(awk -v seconds="$uptime_seconds" 'BEGIN {print int(seconds/86400)}')
uptime_hours=$(awk -v seconds="$uptime_seconds" 'BEGIN {print int((seconds%86400)/3600)}')
uptime_minutes=$(awk -v seconds="$uptime_seconds" 'BEGIN {print int((seconds%3600)/60)}')
formatted_uptime="${uptime_days} days, ${uptime_hours} hours, ${uptime_minutes} minutes"

# Fetch CPU model and details from /proc/cpuinfo
cpu_model=$(grep -m 1 'model name' /proc/cpuinfo |  cut -d ':' -f2 |  xargs)

# Fetch total memory (RAM) from /proc/meminfo
total_memory=$(grep MemTotal /proc/meminfo |  awk '{print $2 / 1024 " MB"}')

# Fetch firmware version from /sys/class/dmi/id/bios_version
firmware_version=$(cat "/sys/class/dmi/id/bios_version")

# Fetch hardware vendor and model from /sys/class/dmi/id
hardware_vendor=$(cat "/sys/class/dmi/id/sys_vendor")
hardware_model=$(cat "/sys/class/dmi/id/product_name")

# Fetch firmware version from /sys/class/dmi/id/bios_version
firmware_version=$(cat "/sys/class/dmi/id/bios_version")

# Fetch firmware date from /sys/class/dmi/id/bios_date
firmware_date=$(cat /sys/class/dmi/id/bios_date)

# Get the current date in seconds since the epoch
current_date_seconds=$(date +%s)

# Get the firmware date in seconds since the epoch
firmware_date_seconds=$(date -d "$firmware_date" +%s)

# Calculate the difference in seconds
seconds_diff=$((current_date_seconds - firmware_date_seconds))

# Perform floating-point division to convert seconds to months using awk
firmware_age_in_months=$(awk "BEGIN {print int($seconds_diff / (60*60*24*30.44))}")

# Calculate years and remaining months
firmware_years=$(awk "BEGIN {print int($firmware_age_in_months / 12)}")
firmware_months=$(awk "BEGIN {print int($firmware_age_in_months % 12)}")

# Display the firmware age in years and months
firmware_age="${firmware_years}y, $firmware_months"

# Fetch total installed packages
total_pkgs="$(dpkg -l |  cat |  wc -l)"

# Fetch memory information
total_memory=$(grep MemTotal /proc/meminfo |  awk '{print $2 / 1024 " MB"}')
available_memory=$(grep MemAvailable /proc/meminfo |  awk '{print $2 / 1024 " MB"}')
used_memory=$(awk '/MemTotal/{total=$2} /MemAvailable/{available=$2} END {print (total-available) / 1024 " MB"}' /proc/meminfo)

# Fetch disk information
total_disk=$(df --total -BG |  grep 'total' |  awk '{print $2}' |  sed 's/G//')
used_disk=$(df --total -BG |  grep 'total' |  awk '{print $3}' |  sed 's/G//')
available_disk=$(df --total -BG |  grep 'total' |  awk '{print $4}' |  sed 's/G//')
most_used_fs=$(df -h |  grep -vE '^Filesystem|tmpfs|cdrom' |  sort -k 5 -r |  head -n 1 |  awk '{print $1 " (" $5 " used)"}')

# Fetch GPU model information
gpu_info=$(lspci |  grep -i vga |  cut -d ':' -f3 |  xargs)

# Fetch Audio model information
audio_info=$(lspci |  grep -i audio |  cut -d ':' -f3 |  xargs)

# Output the information in a formatted way
echo -e "[+] ${WHITE2}System Information ${RT}"
echo -e " |  "
echo -e " |  System Uptime:          $formatted_uptime"
echo -e " |  "
echo -e " |  Hostname:               $hostname"
echo -e " |  "
echo -e " |  Operating System:       $os_pretty_name $os_version"
echo -e " |  Architecture:           $architecture"
echo -e " |  Distribution Type:      $distro_base"
echo -e " |  "
echo -e " |  Kernel Name:            $kernel_name"
echo -e " |  Kernel Release:         $kernel_version ($kernel_release)"
echo -e " |  Kernel Version:         $kernel_version_full"
echo -e " |  "
echo -e " |  CPU Model:              $cpu_model"
echo -e " |  GPU Model:              $gpu_info"
echo -e " |  Audio Model:            $audio_info"
echo -e " |  "
echo -e " |  Hardware Vendor:        $hardware_vendor"
echo -e " |  Hardware Model:         $hardware_model"
echo -e " |  "
echo -e " |  Firmware Version:       $firmware_version"
echo -e " |  Firmware Date:          $firmware_date"
echo -e " |  Firmware Age:           $firmware_age_in_months months"
echo -e " |  "
echo -e " |  Installed Packages:     $total_pkgs"
echo -e " |  "
echo -e " |  Total Disk Space:       $total_disk GB"
echo -e " |  Used Disk Space:        $used_disk GB"
echo -e " |  Available Disk Space:   $available_disk GB"
echo -e " |  Most Used Filesystem:   $most_used_fs"
echo -e " |  "
echo -e " |  Total Memory:           $total_memory"
echo -e " |  Used Memory:            $used_memory"
echo -e " |  Available Memory:       $available_memory"
echo -e " |  "
echo -e " |  Boot ID:                $boot_id"
echo -e " |  Machine ID:             $machine_id"
#echo -e " |  "
#echo -e " |  Chassis Type:           $chassis_type"
#echo -e " |  Chassis Vendor:         $chassis_vendor"
#echo ""