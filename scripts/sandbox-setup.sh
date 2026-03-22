#!/usr/bin/env bash
# Start Docker daemon in Claude Code on the Web (cloud sandbox) environments
#
# Environment detection:
#   CLAUDE_CODE_REMOTE=true  -> Claude Code on the Web cloud environment
#   SANDBOX=1                -> Force execution manually
#
# Usage:
#   SANDBOX=1 bash scripts/sandbox-setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
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
# 2. Switch iptables to legacy mode (required for Docker)
# ==============================================================================
if command -v update-alternatives &>/dev/null; then
  yellow "Switching iptables to legacy mode..."
  sudo update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || true
  sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true
  green "iptables configuration done"
fi

# ==============================================================================
# 3. Start Docker daemon
# ==============================================================================
if ! docker info &>/dev/null; then
  yellow "Starting Docker daemon..."
  sudo -E dockerd --iptables=false --bridge=none --storage-driver=vfs &>"$LOG_DIR/dockerd.log" &
  for i in $(seq 1 30); do
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
# 4. Build Docker image
# ==============================================================================
yellow "Building Docker image..."
cd "$PROJECT_ROOT"
if docker build -t shellnium:local . 2>"$LOG_DIR/docker-build.log"; then
  green "Docker image built successfully"
else
  red "Docker image build failed. Log: $LOG_DIR/docker-build.log"
  cat "$LOG_DIR/docker-build.log" >&2
  exit 1
fi

green "Docker is ready. You can now run:"
echo "  docker run --rm shellnium:local shellcheck   # Run ShellCheck"
echo "  docker run --rm shellnium:local test          # Run Bats tests"
echo "  docker run --rm --shm-size=2g shellnium:local demo.sh  # Run demo"
