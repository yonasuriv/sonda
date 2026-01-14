#!/bin/bash

#####################################################################################
echo -e "[┬] ${WHITE2}System Information ${RT}     $net_status $sys_status"        ##
#####################################################################################
echo -e " |  "
echo -e "$update_recommended $(calculate_time_since_last_update) since the last system update."
echo -e " |  "
echo -e " |  Kernel Version:         $kernel_version_full ($kernel_release)"   
echo -e " |  Operating System:       $os_pretty_name $os_version" 
echo -e " |  Distribution Type:      $distro_base"
echo -e " |  Architecture:           $architecture"
echo -e " |  Hostname:               $hostname"
echo -e " |"
echo -e " |  Terminal Settings:      $terminal terminal with $shell ($shell_version) shell" 
echo -e " |  Display Settings:       $desktop_environment desktop environment on $resolution resolution (WM: $wm, SM: $session_manager)"
echo -e " |  Theme Settings:         $theme GTK Theme (WM: $wm_theme, Icons: $icons)"
echo -e " |"
echo -e " |  GPU:                    $gpu_info"
echo -e " |  CPU:                    $cpu_model ($cpu_cores cores @ $cpu_speed MHz, Cache: $cpu_cache)"
echo -e " |  RAM:                    $total_memory Total ($available_memory available, $used_memory in use)"
echo -e " |  Audio:                  $audio_info"
echo -e " |  Board:                  $board_name ($board_vendor)"
echo -e " |  Hardware:               $hardware_model ($hardware_vendor)"
echo -e " |  Firmware:               $full_firmware, release $firmware_date ($firmware_age old)"
echo -e " |  System Identifier:      BOOT ID: $boot_id, MACHINE ID: $machine_id${RT}"
echo -e " |  "

#####################################################################################
echo -e "[┬] ${WHITE2}System Performance ${RT}"                                    ##
#####################################################################################
echo -e " |  "
echo -e "$restart_recommended $formatted_uptime since the last reboot."
echo -e " |  "
stats_cpu_mem_disk
echo -e " |  "
echo -e "[+] ${NKBRCYAN}$processes_start${RT} startup processes enabled, ${NKBRCYAN}$processes_running${RT} running (${NKBRCYAN}$services_running${RT} services)${RT}"
echo -e " |  "
echo -e "[+] ${NKBRCYAN}$manual_pkgs${RT} packages installed by user, ${NKBRCYAN}$default_pkgs${RT} from OS, ${NKBRCYAN}$total_pkgs${RT} total."
echo -e " |  "
echo -e " |  Last installed:${RT} $(lastipkgs)${LB}"
