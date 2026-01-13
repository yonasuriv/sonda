#!/usr/bin/env bash
# Purpose: Fast rebuild and/or install the sonda .deb.
# Usage: ./dev.sh [rebuild|install|deps|all]
# Notes: Runs make in current dir. Installs sonda_*.deb via sudo dpkg -i.

set -euo pipefail

# Build dependencies only (minimal set needed to build the .deb package)
# Runtime dependencies are defined in packagng/debian/control
DEPS=(
  build-essential
  "debhelper-compat (= 13)"
  dh-python
  python3-all
  python3-pip
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
  local regex='^([a-z0-9][a-z0-9+.-]+)[[:space:]]*\(([[:space:]]*[<>=]+[[:space:]]*)([^)]+)\)[[:space:]]*$'

  if [[ "$dep" =~ $regex ]]; then
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

check_deps() {
  need_cmd apt-get
  need_cmd dpkg-query
  need_cmd dpkg

  if ! is_root; then
    if command -v sudo >/dev/null 2>&1; then
      exec sudo -E bash "$0" deps
    fi
    die "Run as root (or install sudo) to check dependencies."
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
    local pkg_regex='^([a-z0-9][a-z0-9+.-]+)[[:space:]]*\('
    if [[ "$dep" =~ $pkg_regex ]]; then
      pkg="${BASH_REMATCH[1]}"
      missing+=("$pkg")
    else
      missing+=("$dep")
    fi
  done

  if [[ "${#missing[@]}" -eq 0 ]]; then
    echo "All required build dependencies are already installed."
    return 0
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

rebuild() {
  make clean
  make build | tail -3
}

install() {
  # Find the .deb file in current directory
  local deb_file
  deb_file=$(find . -maxdepth 1 -name "sonda_*.deb" -type f | head -n 1)
  
  if [[ -z "$deb_file" ]]; then
    die "No sonda_*.deb file found in current directory. Run 'rebuild' first."
  fi
  
  echo "Installing $deb_file..."
  sudo dpkg -i "$deb_file"
}

case "${1:-}" in
  deps)     check_deps ;;
  rebuild)  rebuild ;;
  install)  install ;;
  ""|all)   check_deps; rebuild; install ;;
  *)
    echo "Usage: $0 [deps|rebuild|install|all]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  deps     - Check and install build dependencies" >&2
    echo "  rebuild  - Clean and build the .deb package" >&2
    echo "  install  - Install the built .deb package" >&2
    echo "  all      - Run deps, rebuild, and install (default)" >&2
    exit 2
    ;;
esac
