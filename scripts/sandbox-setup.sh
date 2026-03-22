#!/usr/bin/env bash
# Automatic setup script for Claude Code on the Web (cloud sandbox) environments
# Intended to be called from a SessionStart Hook
#
# Environment detection:
#   CLAUDE_CODE_REMOTE=true  -> Claude Code on the Web cloud environment
#   SANDBOX=1                -> Force execution manually
#
# Features:
#   - Start Docker daemon
#   - Run ShellCheck static analysis on shell scripts
#   - Run Bats test suite
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="/tmp/shellnium-setup"
mkdir -p "$LOG_DIR"

# Colored output helpers
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
  # Wait for daemon (up to 30 seconds)
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

# ==============================================================================
# 5. Run ShellCheck (static analysis)
# ==============================================================================
yellow "Running ShellCheck..."
SHELLCHECK_EXIT=0
docker run --rm -v "$PROJECT_ROOT:/app:ro" shellnium:local shellcheck 2>"$LOG_DIR/shellcheck.log" || SHELLCHECK_EXIT=$?
if [ "$SHELLCHECK_EXIT" -eq 0 ]; then
  green "ShellCheck: all scripts passed"
else
  red "ShellCheck: issues found (exit code: $SHELLCHECK_EXIT)"
  cat "$LOG_DIR/shellcheck.log" >&2
fi

# ==============================================================================
# 6. Run Bats tests
# ==============================================================================
yellow "Running Bats tests..."
BATS_EXIT=0
docker run --rm -v "$PROJECT_ROOT:/app:ro" shellnium:local test 2>"$LOG_DIR/bats.log" || BATS_EXIT=$?
if [ "$BATS_EXIT" -eq 0 ]; then
  green "Bats tests: all passed"
else
  red "Bats tests: failures detected (exit code: $BATS_EXIT)"
  cat "$LOG_DIR/bats.log" >&2
fi

# ==============================================================================
# Done
# ==============================================================================
echo ""
if [ "$SHELLCHECK_EXIT" -eq 0 ] && [ "$BATS_EXIT" -eq 0 ]; then
  green "Sandbox setup complete! All checks passed."
else
  yellow "Sandbox setup complete (some checks failed)"
  exit 1
fi
