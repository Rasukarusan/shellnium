#!/usr/bin/env bash
set -euo pipefail

info() {
  printf '[bootstrap] %s\n' "$*"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

install_with_brew() {
  local packages=()

  for package in jq unzip; do
    if ! brew list "$package" >/dev/null 2>&1; then
      packages+=("$package")
    fi
  done

  if [ "${#packages[@]}" -eq 0 ]; then
    info "Homebrew dependencies already installed."
    return 0
  fi

  info "Installing with Homebrew: ${packages[*]}"
  brew install "${packages[@]}"
}

install_with_apt() {
  local packages=(jq unzip)

  info "Installing with apt-get: ${packages[*]}"
  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
}

main() {
  info "Checking optional local runtime commands."

  if have jq && have unzip; then
    info "Local runtime commands already available."
  elif have brew; then
    install_with_brew
  elif have apt-get; then
    install_with_apt
  else
    info "No supported package manager found."
    printf '%s\n' \
      'Install these commands manually, then rerun verification:' \
      '  jq unzip'
    exit 1
  fi

  if have google-chrome || have google-chrome-stable || have chromium || have chromium-browser; then
    info "Chrome or Chromium detected."
  elif [ "$(uname -s)" = "Darwin" ] && [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    info "Google Chrome.app detected."
  else
    info "Chrome or Chromium is not installed. Browser smoke tests may require Docker."
  fi

  info "Bootstrap complete."
  info "Suggested next step: make ci"
}

main "$@"
