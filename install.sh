#!/usr/bin/env bash
# Install Sonda from a GitHub release package or from this source checkout.

set -euo pipefail

REPO_URL="https://github.com/yonasuriv/sonda"
LATEST_DEB_URL="$REPO_URL/releases/latest/download/sonda_latest_all.deb"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
MODE=""
DISTRO=""
VERBOSE=0
SUDO_KEEPALIVE_PID=""

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  ./install.sh release -d debian [-v]
  ./install.sh source  -d debian [-v]

Modes:
  release   Install the latest published .deb release package.
  source    Build the Debian package from this checkout, then install it.

Options:
  -d, --distro DISTRO   Target distro packaging flow. Currently only "debian".
  -v, --verbose         Show command output.
  -h, --help            Show this help.
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

log() {
  echo "==> $*"
}

run() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    "$@"
    return
  fi

  local log_file
  log_file="$(mktemp)"
  if "$@" >"$log_file" 2>&1; then
    rm -f "$log_file"
    return
  fi

  echo "Command failed: $*" >&2
  echo "" >&2
  cat "$log_file" >&2
  rm -f "$log_file"
  exit 1
}

sudo_keepalive() {
  need_cmd sudo
  log "Requesting sudo access"
  sudo -v

  while true; do
    sudo -n true >/dev/null 2>&1 || exit
    sleep 60
  done &
  SUDO_KEEPALIVE_PID="$!"
}

cleanup() {
  if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
}

parse_args() {
  [[ "$#" -gt 0 ]] || { usage; exit 2; }

  MODE="$1"
  shift

  case "$MODE" in
    release|source) ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Unknown install mode: $MODE"
      ;;
  esac

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -d|--distro)
        [[ "$#" -ge 2 ]] || die "$1 requires a value"
        DISTRO="$2"
        shift 2
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        usage >&2
        die "Unknown option: $1"
        ;;
    esac
  done

  [[ -n "$DISTRO" ]] || die "Missing distro. Use: -d debian"
  [[ "$DISTRO" == "debian" ]] || die "Unsupported distro: $DISTRO. Currently only debian is supported."
}

download() {
  local url="$1"
  local out="$2"

  if command -v wget >/dev/null 2>&1; then
    run wget -q -O "$out" "$url"
  elif command -v curl >/dev/null 2>&1; then
    run curl -fsSL -o "$out" "$url"
  else
    die "Missing download tool: install wget or curl"
  fi
}

install_release_debian() {
  need_cmd apt-get
  sudo_keepalive

  local tmp_dir deb_file
  tmp_dir="$(mktemp -d)"
  deb_file="$tmp_dir/sonda.deb"

  log "Downloading latest Sonda Debian release"
  download "$LATEST_DEB_URL" "$deb_file"

  log "Installing release package"
  run sudo apt-get install -y "$deb_file"

  log "Sonda release installation complete"
}

install_source_debian() {
  [[ -x "$SCRIPT_DIR/scripts/install_debian.sh" ]] || die "Missing executable helper: scripts/install_debian.sh"
  sudo_keepalive

  log "Building and installing Debian package from source"
  run "$SCRIPT_DIR/scripts/install_debian.sh" all

  log "Sonda source installation complete"
}

main() {
  trap cleanup EXIT
  parse_args "$@"

  case "$MODE:$DISTRO" in
    release:debian) install_release_debian ;;
    source:debian) install_source_debian ;;
    *) die "Unsupported install target: $MODE -d $DISTRO" ;;
  esac
}

main "$@"
