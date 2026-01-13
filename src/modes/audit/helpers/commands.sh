#!/usr/bin/env bash
# Common command variable definitions
# Note: Redirections are added when commands are executed, not in the base variables

# Journalctl commands
JOURNALCTL_BASE="journalctl -b -o cat --no-pager"
JOURNALCTL_USER_BASE="journalctl --user -b -o cat --no-pager"

# Systemctl commands
SYSTEMCTL_FAILED_BASE="systemctl --failed --no-legend"
SYSTEMCTL_USER_FAILED_BASE="systemctl --user list-units --type=service --state=failed --no-legend"

# dmesg commands (without sudo)
DMESG_BASE="dmesg -T"
DMESG_WARN="dmesg -T --level=warn,notice"
DMESG_ERR="dmesg -T --level=emerg,alert,crit,err"

# dmesg commands (with sudo)
SUDO_DMESG_BASE="sudo dmesg -T"
SUDO_DMESG_WARN="sudo dmesg -T --level=warn,notice"
SUDO_DMESG_ERR="sudo dmesg -T --level=emerg,alert,crit,err"

# Export for use in other modules
export JOURNALCTL_BASE JOURNALCTL_USER_BASE
export SYSTEMCTL_FAILED_BASE SYSTEMCTL_USER_FAILED_BASE
export DMESG_BASE DMESG_WARN DMESG_ERR
export SUDO_DMESG_BASE SUDO_DMESG_WARN SUDO_DMESG_ERR
