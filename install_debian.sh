#!/usr/bin/env bash
# Purpose: Fast build and/or install the sonda .deb.
# Usage: ./install_debian.sh [build|install|deps|all]
# Notes: Builds inside .build/ so package artifacts never land outside the repo.

set -euo pipefail

# Build dependencies only (minimal set needed to build the .deb package)
# Runtime dependencies are defined in debian/control
DEPS=(
  build-essential
  "debhelper-compat (= 13)"
  dh-python
  dpkg-dev
  python3-all
)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BUILD_ROOT="$SCRIPT_DIR/.build"
BUILD_SRC="$BUILD_ROOT/sonda-src"
DIST_ROOT="$SCRIPT_DIR/dist"

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

    # Special handling for debhelper-compat (virtual package)
    if [[ "$pkg" == "debhelper-compat" ]]; then
      # Check if debhelper is installed
      if ! dpkg-query -W -f='${Status}' debhelper 2>/dev/null | grep -q "install ok installed"; then
        return 1
      fi
      # Check if debhelper provides the required compat level
      local provides
      provides=$(apt-cache show debhelper 2>/dev/null | grep "^Provides:" | grep -o "debhelper-compat (= ${ver})" || true)
      if [[ -n "$provides" ]]; then
        return 0
      else
        # Fallback: if debhelper is installed, assume it provides the compat level
        # (the actual build will fail if it doesn't)
        return 0
      fi
    fi

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
  apt-get update
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
      if [[ "${ORIGINAL_CMD:-}" == "all" ]]; then
        sudo -E bash "$0" deps
        return 0
      fi
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
    # Special handling for debhelper-compat: install debhelper instead
    if [[ "$dep" == "debhelper-compat (= 13)" ]] || [[ "$dep" =~ ^debhelper-compat ]]; then
      missing+=("debhelper")
    else
      local pkg_regex='^([a-z0-9][a-z0-9+.-]+)[[:space:]]*\('
      if [[ "$dep" =~ $pkg_regex ]]; then
        pkg="${BASH_REMATCH[1]}"
        missing+=("$pkg")
      else
        missing+=("$dep")
      fi
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

build() {
  need_cmd dpkg-buildpackage
  need_cmd tar

  cd "$SCRIPT_DIR"
  make -f debian/rules clean

  rm -rf "$BUILD_SRC"
  mkdir -p "$BUILD_SRC"

  # dpkg-buildpackage writes output to the parent of the source tree. Building
  # from a copy under .build keeps every generated file inside this repository.
  tar \
    --exclude='./.git' \
    --exclude='./.build' \
    --exclude='./build' \
    --exclude='./dist' \
    -cf - . | tar -xf - -C "$BUILD_SRC"

  echo ""
  echo "Building debian package..."
  echo ""
  (cd "$BUILD_SRC" && dpkg-buildpackage -us -uc -b)
  echo ""
  echo "Package built successfully."

  mkdir -p "$DIST_ROOT"
  find "$BUILD_ROOT" -maxdepth 1 -type f \
    \( -name 'sonda_*.deb' -o -name 'sonda_*.buildinfo' -o -name 'sonda_*.changes' \) \
    -exec cp -a {} "$DIST_ROOT/" \;

  make -f debian/rules collect
}

install() {
  # Use debian/rules install-package target
  cd "$SCRIPT_DIR"
  make -f debian/rules install-package
}

case "${1:-}" in
  deps)     check_deps ;;
  build)  build ;;
  install)  install ;;
  ""|all)   ORIGINAL_CMD="all" check_deps; build; install ;;
  *)
    echo "Usage: $0 [deps|build|install|all]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  deps     - Check and install build dependencies" >&2
    echo "  build    - Clean and build the .deb package" >&2
    echo "  install  - Install the built .deb package from dist/" >&2
    echo "  all      - Run deps, build, and install (default)" >&2
    exit 2
    ;;
esac
