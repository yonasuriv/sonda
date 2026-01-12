#!/usr/bin/env bash
# Purpose: Fast rebuild and/or install the sonda .deb.
# Usage: ./dev.sh [rebuild|install]
# Notes: Runs make in current dir. Installs ../sonda_*.deb via sudo dpkg -i.

set -euo pipefail

rebuild() {
  make clean
  make build | tail -3
}

install() {
  sudo dpkg -i ../sonda_*.deb
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
