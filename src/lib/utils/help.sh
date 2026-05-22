#!/usr/bin/env bash
# metadata: Sonda centralized help/man. Single entrypoint with topic dispatch. Heredoc-based, no quoting games.

set -euo pipefail

sonda_help() {
  local topic="${1:-main}"
  case "$topic" in
    -h|--help|help|main) _sonda_help_main  ;;
    audit)               _sonda_help_audit ;;
    check|scan)           _sonda_help_check ;;
    utils)                _sonda_help_utils ;;
    *)                    _sonda_help_main  ;;
  esac
}

_sonda_help_main() {
  cat <<'EOF'
sonda

USAGE
  sonda <mode> [args] [flags]
  sonda <util> [args]
  sonda help [topic]

MODES
  audit <boot|security>   Run audit modules (boot session, security baseline)
  scan  <target>          Run scanners (devices, networks, services)
  check <target>          Run local checks (system, kernel, security, etc)

UTILS
  sys                     Print enhanced system info
  net                     Print enhanced network info
  
  --update                  Check for updates, show version comparison
  --upgrade                 Upgrade to latest version
  --version                 Print installed version
  --help [topic]            Help topics: main, audit, scan, check, utils
EOF
}

_sonda_help_audit() {
  cat <<'EOF'
sonda audit

USAGE
  sonda audit <boot|system|security> [flags]

FLAGS
  -v, --verbose           Increase verbosity (repeatable if implemented)
  -s, --silent            Suppress terminal detail (logs still allowed)

  -u, --user              Include username in log filenames
  -a, --no-user           Do not include username in log filenames (default)

  -t, --timestamp         Include timestamp in log filenames
  -nt, --no-timestamp     Do not include timestamp in log filenames (default)

  --save-logs, --log      Write detailed logs
  --log-dir, -d DIR       Log directory (default: ./logs)

  -h, --help              Show this help

DEFAULTS
  --silent --no-timestamp --no-user

EXAMPLES
  sonda audit boot
  sonda audit security --save-logs
  sonda audit boot -v --log-dir /var/log/sonda
EOF
}

_sonda_help_check() {
  cat <<'EOF'
sonda check

USAGE
  sonda check <target> [flags]

TARGETS
  pkgs                    Installed packages
  cpu                     CPU information
  gpu                     GPU information
  disks                   Disk/storage (sudo may be required for full detail)
  memory                  Memory (sudo may be required for full detail)
  kernel                  Kernel params and loaded modules
  devices                 PCI and USB devices
  network                 Interfaces and active connections
  battery                 Battery and power status
  boot                    Boot analysis, warnings, errors
  security                Security baseline (firewall, MAC, ssh, encryption)
  all                     Everything (long output)

FLAGS
  -v                      Increase verbosity (repeatable if implemented)
  -s, --save              Save output to a log file
  -nc, --no-color          Strip color codes

EXAMPLES
  sonda check network
  sonda check cpu -v
  sonda check all --save --no-color -vv
EOF
}

_sonda_help_utils() {
  cat <<'EOF'
sonda utils

USAGE
  sonda sys
  sonda net
  sonda update
  sonda upgrade
  sonda version

NOTES
  Utilities are fast paths. They should not require mode selection.
EOF
}

_sonda_help_unknown() {
  local topic="$1"
  cat <<EOF
Unknown help topic: $topic

Try:
  sonda help
  sonda help audit
  sonda help check
  sonda help utils
EOF
}

# If script is called directly, execute help function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  sonda_help "${1:-main}"
fi
