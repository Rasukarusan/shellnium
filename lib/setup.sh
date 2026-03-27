#!/usr/bin/env bash

# Auto-download and start ChromeDriver matching the installed Chrome version.
# Downloaded binaries are cached in ~/.cache/shellnium/chromedriver-<version>/

SHELLNIUM_CACHE_DIR="${SHELLNIUM_CACHE_DIR:-${HOME}/.cache/shellnium}"
SHELLNIUM_PORT="${SHELLNIUM_PORT:-9515}"
SHELLNIUM_CHROME_BIN=""

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

_get_chrome_for_testing_json() {
  local url="$1"
  local json
  json=$(curl -sf "$url")
  if [ -z "$json" ]; then
    printf "\e[35m[ERROR] Failed to fetch Chrome for Testing info.\e[m\n" >&2
    return 1
  fi
  echo "$json"
}

# Download chrome-headless-shell when no system Chrome is found.
# Sets SHELLNIUM_CHROME_BIN to the downloaded binary path.
_download_chrome_headless_shell() {
  local platform version cache_dir download_url zip_file json

  platform=$(_get_platform) || return 1

  # Use specific version if set, otherwise fetch latest stable
  if [ -n "${SHELLNIUM_CHROME_VERSION:-}" ]; then
    version="$SHELLNIUM_CHROME_VERSION"
  else
    json=$(_get_chrome_for_testing_json "https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json") || return 1
    version=$(echo "$json" | jq -r '.channels.Stable.version' 2>/dev/null)
    if [ -z "$version" ] || [ "$version" = "null" ]; then
      printf "\e[35m[ERROR] Could not determine latest stable Chrome version.\e[m\n" >&2
      return 1
    fi
  fi

  cache_dir="${SHELLNIUM_CACHE_DIR}/chrome-headless-shell-${version}"

  # Return cached binary if it exists
  if [ -x "${cache_dir}/chrome-headless-shell" ]; then
    SHELLNIUM_CHROME_BIN="${cache_dir}/chrome-headless-shell"
    echo "$version"
    return 0
  fi

  mkdir -p "$cache_dir"

  download_url="https://storage.googleapis.com/chrome-for-testing-public/${version}/${platform}/chrome-headless-shell-${platform}.zip"

  printf "Downloading chrome-headless-shell %s (%s) ...\n" "$version" "$platform" >&2

  zip_file="${cache_dir}/chrome-headless-shell.zip"
  if ! curl -fL --progress-bar -o "$zip_file" "$download_url" 2>&1; then
    printf "\e[35m[ERROR] Failed to download chrome-headless-shell from %s\e[m\n" "$download_url" >&2
    rm -f "$zip_file"
    return 1
  fi

  if command -v unzip >/dev/null 2>&1; then
    unzip -o "$zip_file" -d "$cache_dir" >/dev/null 2>&1
  else
    printf "\e[35m[ERROR] 'unzip' is required to extract chrome-headless-shell.\e[m\n" >&2
    return 1
  fi

  rm -f "$zip_file"

  # Find the binary (may be nested in a subdirectory)
  local found
  found=$(find "$cache_dir" -name 'chrome-headless-shell' -type f | head -1)
  if [ -n "$found" ] && [ "$found" != "${cache_dir}/chrome-headless-shell" ]; then
    # Move all files from the nested directory (shared libs may be needed)
    local nested_dir
    nested_dir=$(dirname "$found")
    if [ "$nested_dir" != "$cache_dir" ]; then
      mv "$nested_dir"/* "$cache_dir"/ 2>/dev/null
      rm -rf "$nested_dir"
    fi
  fi

  chmod +x "${cache_dir}/chrome-headless-shell"

  if [ ! -x "${cache_dir}/chrome-headless-shell" ]; then
    printf "\e[35m[ERROR] chrome-headless-shell binary not found after extraction.\e[m\n" >&2
    return 1
  fi

  SHELLNIUM_CHROME_BIN="${cache_dir}/chrome-headless-shell"
  printf "chrome-headless-shell %s ready.\n" "$version" >&2
  echo "$version"
}

# Download ChromeDriver matching the given version (or system Chrome).
# When a version argument is provided, it is used instead of detecting system Chrome.
_download_chromedriver() {
  local chrome_version major platform download_url cache_dir zip_file

  # Use provided version or detect from system Chrome
  if [ -n "$1" ]; then
    chrome_version="$1"
  else
    chrome_version=$(_get_chrome_version)
    if [ -z "$chrome_version" ]; then
      printf "\e[35m[ERROR] Google Chrome is not installed.\e[m\n" >&2
      return 1
    fi
  fi

  major=$(echo "$chrome_version" | cut -d. -f1)
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
    json=$(_get_chrome_for_testing_json "https://googlechromelabs.github.io/chrome-for-testing/latest-versions-per-milestone-with-downloads.json") || return 1

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
  if ! curl -fL --progress-bar -o "$zip_file" "$download_url" 2>&1; then
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

  local chrome_version chromedriver_bin

  # Check if system Chrome is available
  chrome_version=$(_get_chrome_version)

  if [ -z "$chrome_version" ]; then
    # No system Chrome found — auto-download chrome-headless-shell
    printf "No system Chrome found. Auto-downloading chrome-headless-shell ...\n" >&2
    chrome_version=$(_download_chrome_headless_shell) || return 1
    export SHELLNIUM_CHROME_BIN
    # Force headless mode since chrome-headless-shell has no GUI
    export SHELLNIUM_HEADLESS=true
  fi

  # Try system chromedriver first, then auto-download
  if command -v chromedriver >/dev/null 2>&1; then
    # Verify version matches
    local system_major chrome_major
    system_major=$(chromedriver --version 2>/dev/null | awk '{print $2}' | cut -d. -f1)
    chrome_major=$(echo "$chrome_version" | cut -d. -f1)
    if [ -n "$chrome_major" ] && [ "$system_major" = "$chrome_major" ]; then
      chromedriver_bin="chromedriver"
    else
      chromedriver_bin=$(_download_chromedriver "$chrome_version") || return 1
    fi
  else
    chromedriver_bin=$(_download_chromedriver "$chrome_version") || return 1
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
