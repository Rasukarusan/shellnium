#!/usr/bin/env bash
# Setup script for Claude Code on the Web (cloud sandbox) environments
#
# Environment detection:
#   CLAUDE_CODE_REMOTE=true  -> Claude Code on the Web cloud environment
#   SANDBOX=1                -> Force execution manually
#
# Installs ShellCheck and Bats, then makes Docker available for browser tests.
#
# Usage:
#   SANDBOX=1 bash scripts/sandbox-setup.sh
set -euo pipefail

LOG_DIR="/tmp/shellnium-setup"
mkdir -p "$LOG_DIR"

green() { echo -e "\033[32m✓ $*\033[0m"; }
yellow() { echo -e "\033[33m⏳ $*\033[0m"; }
red() { echo -e "\033[31m✗ $*\033[0m"; }
info() { echo -e "\033[36mℹ $*\033[0m"; }

# ==============================================================================
# 1. Detect Claude Code on the Web environment
# ==============================================================================
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ -z "${SANDBOX:-}" ]; then
  info "Not running in Claude Code on the Web. Set SANDBOX=1 to force execution."
  exit 0
fi

# ==============================================================================
# 2. Install ShellCheck and Bats
# ==============================================================================
if ! command -v shellcheck &>/dev/null; then
  yellow "Installing ShellCheck..."
  sudo apt-get update -qq 2>"$LOG_DIR/apt.log"
  sudo apt-get install -y -qq shellcheck 2>>"$LOG_DIR/apt.log"
  green "ShellCheck installed ($(shellcheck --version | grep '^version:'))"
else
  green "ShellCheck already installed"
fi

if ! command -v bats &>/dev/null; then
  yellow "Installing Bats..."
  git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats-core 2>"$LOG_DIR/bats-install.log"
  sudo /tmp/bats-core/install.sh /usr/local 2>>"$LOG_DIR/bats-install.log"
  rm -rf /tmp/bats-core
  green "Bats installed ($(bats --version))"
else
  green "Bats already installed"
fi

# ==============================================================================
# 3. Switch iptables to legacy mode (required for Docker)
# ==============================================================================
if command -v update-alternatives &>/dev/null; then
  yellow "Switching iptables to legacy mode..."
  sudo update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || true
  sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true
  green "iptables configuration done"
fi

# ==============================================================================
# 4. Start Docker daemon
# ==============================================================================
if ! docker info &>/dev/null; then
  yellow "Starting Docker daemon..."
  # shellcheck disable=SC2024
  sudo -E dockerd --storage-driver=vfs &>"$LOG_DIR/dockerd.log" &
  for _ in $(seq 1 30); do
    if docker info &>/dev/null; then
      break
    fi
    sleep 1
  done
  if docker info &>/dev/null; then
    green "Docker daemon started"
  else
    red "Failed to start Docker daemon. Log: $LOG_DIR/dockerd.log"
    exit 1
  fi
else
  green "Docker daemon already running"
fi

# ==============================================================================
# Done
# ==============================================================================
echo ""
green "Setup complete! Available commands:"
echo "  shellcheck -s bash lib/*.sh          # Lint library scripts"
echo "  bats --recursive tests/              # Run test suite"
echo "  docker build -t shellnium:local .    # Build Docker image"
echo "  docker run --rm shellnium:local test # Run tests in Docker"
