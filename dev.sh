#!/usr/bin/env bash
# Purpose: Fast rebuild and/or install the sonda .deb.
# Usage: ./dev.sh [rebuild|install]
# Notes: Runs make in current dir. Installs ../sonda_*.deb via sudo dpkg -i.

#!/usr/bin/env bash
# sonda-apt-builddeps.sh | v1.0 | Purpose: Ensure required APT build dependencies are installed | Author: ChatGPT | License: MIT

set -euo pipefail

DEPS=(
  build-essential
  "debhelper-compat (= 13)"
  dh-python
  python3-all
  python3-pip
  python3-colorama
  net-tools
  mesa-utils
  wmctrl
  lolcat
)

die() { echo "ERROR: $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

# Return 0 if dependency is satisfied, else 1.
# Handles:
#   - plain package name: "dh-python"
#   - versioned: "debhelper-compat (= 13)"
dep_satisfied() {
  local dep="$1"
  local pkg op ver

  if [[ "$dep" =~ ^([a-z0-9][a-z0-9+.-]+)[[:space:]]*\(([[:space:]]*[<>=]+[[:space:]]*)([^)]+)\)[[:space:]]*$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    op="$(echo "${BASH_REMATCH[2]}" | xargs)"
    ver="$(echo "${BASH_REMATCH[3]}" | xargs)"

    # Must be installed first.
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed" || return 1

    # Compare installed version against requested constraint.
    local installed
    installed="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
    [[ -n "$installed" ]] || return 1

    dpkg --compare-versions "$installed" "$op" "$ver"
    return $?
  else
    pkg="$dep"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
    return $?
  fi
}

apt_update_once() {
  # Keep noise down but still useful.
  apt-get update -y
}

apt_install() {
  local pkgs=("$@")
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}"
}

main() {
  need_cmd apt-get
  need_cmd dpkg-query
  need_cmd dpkg

  if ! is_root; then
    if command -v sudo >/dev/null 2>&1; then
      exec sudo -E bash "$0" "$@"
    fi
    die "Run as root (or install sudo)."
  fi

  local missing=()
  local dep pkg

  for dep in "${DEPS[@]}"; do
    if dep_satisfied "$dep"; then
      continue
    fi

    # For apt install, strip version constraint because APT cannot install "pkg (= X)" reliably
    # unless the exact version exists in enabled repos. We prefer ensuring the package exists,
    # then validate the version constraint post-install.
    if [[ "$dep" =~ ^([a-z0-9][a-z0-9+.-]+)[[:space:]]*\( ]]; then
      pkg="${BASH_REMATCH[1]}"
      missing+=("$pkg")
    else
      missing+=("$dep")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    echo "All required build dependencies are already installed."
    exit 0
  fi

  echo "Missing packages: ${missing[*]}"
  apt_update_once
  apt_install "${missing[@]}"

  # Re-validate versioned constraints (specifically debhelper-compat (= 13)).
  local failed=0
  for dep in "${DEPS[@]}"; do
    if ! dep_satisfied "$dep"; then
      echo "Unsatisfied after install: $dep" >&2
      failed=1
    fi
  done

  if [[ "$failed" -ne 0 ]]; then
    cat >&2 <<'EOF'

One or more versioned constraints are not met.
Common causes:
  - Your distro repos do not provide the required version (ex: debhelper-compat 13).
Fix:
  - Enable the appropriate repository for your distro release, or build in a container/chroot
    matching the target distro, or adjust the package's Build-Depends.

EOF
    exit 2
  fi

  echo "Build dependencies satisfied."
}

main "$@"



rebuild() {
  make clean
  make build | tail -3
}

install() {
  sudo dpkg -I ../sonda_*.deb
}

case "${1:-}" in
  rebuild) rebuild ;;
  install) install ;;
  ""|all)  rebuild; install ;;
  *)
    echo "Usage: $0 [rebuild|install|all]" >&2
    exit 2
    ;;
esac
