#!/usr/bin/env bash

# Auto-download and start ChromeDriver matching the installed Chrome version.
# Downloaded binaries are cached in ~/.cache/shellnium/chromedriver-<version>/

SHELLNIUM_CACHE_DIR="${SHELLNIUM_CACHE_DIR:-${HOME}/.cache/shellnium}"
SHELLNIUM_PORT="${SHELLNIUM_PORT:-9515}"

_get_chrome_version() {
  local version_output
  if [ "$(uname)" = 'Darwin' ]; then
    version_output=$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version 2>/dev/null)
  elif command -v google-chrome >/dev/null 2>&1; then
    version_output=$(google-chrome --version 2>/dev/null)
  elif command -v google-chrome-stable >/dev/null 2>&1; then
    version_output=$(google-chrome-stable --version 2>/dev/null)
  elif command -v chromium-browser >/dev/null 2>&1; then
    version_output=$(chromium-browser --version 2>/dev/null)
  elif command -v chromium >/dev/null 2>&1; then
    version_output=$(chromium --version 2>/dev/null)
  fi

  if [ -z "$version_output" ]; then
    return 1
  fi

  # Extract version number (e.g. "Google Chrome 120.0.6099.109" -> "120.0.6099.109")
  echo "$version_output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
}

_get_chrome_major_version() {
  _get_chrome_version | cut -d. -f1
}

_get_platform() {
  local os arch
  os=$(uname -s)
  arch=$(uname -m)

  case "$os" in
    Darwin)
      case "$arch" in
        arm64) echo "mac-arm64" ;;
        *)     echo "mac-x64" ;;
      esac
      ;;
    Linux)
      echo "linux64"
      ;;
    *)
      printf "\e[35m[ERROR] Unsupported OS: %s\e[m\n" "$os" >&2
      return 1
      ;;
  esac
}

_download_chromedriver() {
  local chrome_version major platform download_url cache_dir zip_file

  chrome_version=$(_get_chrome_version)
  if [ -z "$chrome_version" ]; then
    printf "\e[35m[ERROR] Google Chrome is not installed.\e[m\n" >&2
    return 1
  fi

  major=$(_get_chrome_major_version)
  platform=$(_get_platform) || return 1
  cache_dir="${SHELLNIUM_CACHE_DIR}/chromedriver-${chrome_version}"

  # Return cached binary if it exists
  if [ -x "${cache_dir}/chromedriver" ]; then
    echo "${cache_dir}/chromedriver"
    return 0
  fi

  mkdir -p "$cache_dir"

  printf "Downloading ChromeDriver for Chrome %s ...\n" "$chrome_version" >&2

  if [ "$major" -ge 115 ]; then
    # Chrome for Testing API (Chrome 115+)
    local json driver_version
    json=$(curl -sf "https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone-with-downloads.json")
    if [ -z "$json" ]; then
      printf "\e[35m[ERROR] Failed to fetch ChromeDriver version info.\e[m\n" >&2
      return 1
    fi

    download_url=$(echo "$json" | jq -r \
      ".milestones.\"${major}\".downloads.chromedriver[] | select(.platform==\"${platform}\") | .url" 2>/dev/null)
    driver_version=$(echo "$json" | jq -r ".milestones.\"${major}\".version" 2>/dev/null)
  else
    # Legacy API (Chrome < 115)
    local driver_version
    driver_version=$(curl -sf "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${major}")
    if [ -z "$driver_version" ]; then
      printf "\e[35m[ERROR] No ChromeDriver found for Chrome %s.\e[m\n" "$major" >&2
      return 1
    fi

    local legacy_platform
    case "$platform" in
      mac-arm64) legacy_platform="mac_arm64" ;;
      mac-x64)   legacy_platform="mac64" ;;
      linux64)   legacy_platform="linux64" ;;
    esac
    download_url="https://chromedriver.storage.googleapis.com/${driver_version}/chromedriver_${legacy_platform}.zip"
  fi

  if [ -z "$download_url" ]; then
    printf "\e[35m[ERROR] Could not determine ChromeDriver download URL for Chrome %s (%s).\e[m\n" "$major" "$platform" >&2
    return 1
  fi

  zip_file="${cache_dir}/chromedriver.zip"
  if ! curl -sfL -o "$zip_file" "$download_url"; then
    printf "\e[35m[ERROR] Failed to download ChromeDriver from %s\e[m\n" "$download_url" >&2
    rm -f "$zip_file"
    return 1
  fi

  # Extract chromedriver binary
  if command -v unzip >/dev/null 2>&1; then
    unzip -o -j "$zip_file" '*/chromedriver' -d "$cache_dir" >/dev/null 2>&1 \
      || unzip -o "$zip_file" -d "$cache_dir" >/dev/null 2>&1
  else
    printf "\e[35m[ERROR] 'unzip' is required to extract ChromeDriver.\e[m\n" >&2
    return 1
  fi

  rm -f "$zip_file"

  # Find the chromedriver binary (may be nested in a subdirectory)
  local found
  found=$(find "$cache_dir" -name 'chromedriver' -type f ! -name '*.zip' | head -1)
  if [ -n "$found" ] && [ "$found" != "${cache_dir}/chromedriver" ]; then
    mv "$found" "${cache_dir}/chromedriver"
  fi

  chmod +x "${cache_dir}/chromedriver"

  if [ ! -x "${cache_dir}/chromedriver" ]; then
    printf "\e[35m[ERROR] ChromeDriver binary not found after extraction.\e[m\n" >&2
    return 1
  fi

  printf "ChromeDriver %s ready.\n" "${driver_version:-$chrome_version}" >&2
  echo "${cache_dir}/chromedriver"
}

_is_chromedriver_running() {
  curl -sf "http://localhost:${SHELLNIUM_PORT}/status" >/dev/null 2>&1
}

# Ensure chromedriver is available and running.
# Sets SHELLNIUM_DRIVER_URL and SHELLNIUM_CHROMEDRIVER_PID (if we started it).
setup_chromedriver() {
  # If user set a custom URL, assume they manage chromedriver themselves
  if [ -n "$SHELLNIUM_DRIVER_URL" ]; then
    return 0
  fi

  export SHELLNIUM_DRIVER_URL="http://localhost:${SHELLNIUM_PORT}"

  # Already running? Nothing to do.
  if _is_chromedriver_running; then
    return 0
  fi

  # Try system chromedriver first, then auto-download
  local chromedriver_bin
  if command -v chromedriver >/dev/null 2>&1; then
    # Verify version matches
    local system_major chrome_major
    system_major=$(chromedriver --version 2>/dev/null | awk '{print $2}' | cut -d. -f1)
    chrome_major=$(_get_chrome_major_version)
    if [ -n "$chrome_major" ] && [ "$system_major" = "$chrome_major" ]; then
      chromedriver_bin="chromedriver"
    else
      # Version mismatch - download the right one
      chromedriver_bin=$(_download_chromedriver) || return 1
    fi
  else
    chromedriver_bin=$(_download_chromedriver) || return 1
  fi

  # Start chromedriver in the background
  "$chromedriver_bin" --port="$SHELLNIUM_PORT" >/dev/null 2>&1 &
  SHELLNIUM_CHROMEDRIVER_PID=$!
  export SHELLNIUM_CHROMEDRIVER_PID

  # Wait for chromedriver to be ready
  local _i
  for _i in $(seq 1 30); do
    if _is_chromedriver_running; then
      return 0
    fi
    sleep 0.1
  done

  printf "\e[35m[ERROR] ChromeDriver failed to start.\e[m\n" >&2
  return 1
}

# Stop chromedriver if we started it.
cleanup_chromedriver() {
  if [ -n "$SHELLNIUM_CHROMEDRIVER_PID" ]; then
    kill "$SHELLNIUM_CHROMEDRIVER_PID" 2>/dev/null
    wait "$SHELLNIUM_CHROMEDRIVER_PID" 2>/dev/null
    unset SHELLNIUM_CHROMEDRIVER_PID
  fi
}
