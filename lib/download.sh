#!/bin/sh
set -e

INSTALL_DIR="$HOME/.local/bin" VERSION="${VERSION:-}" \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/kodaskills/oplint/main/install.sh)"
