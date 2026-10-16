#!/usr/bin/env bats

setup() {
  SHELLNIUM_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
}

# =====================
# _get_chrome_major_version tests
# =====================

@test "_get_chrome_major_version extracts major version number" {
  # Mock _get_chrome_version to return a known version
  _get_chrome_version() {
    echo "120.0.6099.109"
  }
  export -f _get_chrome_version

  source "${SHELLNIUM_DIR}/lib/setup.sh"

  # Override _get_chrome_version after sourcing
  _get_chrome_version() {
    echo "120.0.6099.109"
  }

  run _get_chrome_major_version
  [[ "$output" == "120" ]]
}

@test "_get_chrome_major_version handles version 115" {
  _get_chrome_version() {
    echo "115.0.5790.170"
  }

  source "${SHELLNIUM_DIR}/lib/setup.sh"

  _get_chrome_version() {
    echo "115.0.5790.170"
  }

  run _get_chrome_major_version
  [[ "$output" == "115" ]]
}

@test "_get_chrome_major_version handles version 90" {
  _get_chrome_version() {
    echo "90.0.4430.93"
  }

  source "${SHELLNIUM_DIR}/lib/setup.sh"

  _get_chrome_version() {
    echo "90.0.4430.93"
  }

  run _get_chrome_major_version
  [[ "$output" == "90" ]]
}

# =====================
# _get_platform tests
# =====================

@test "_get_platform returns a non-empty value on current OS" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  run _get_platform
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "_get_platform returns mac-arm64 for Darwin arm64" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  # Override uname
  uname() {
    case "$1" in
      -s) echo "Darwin" ;;
      -m) echo "arm64" ;;
      *)  command uname "$@" ;;
    esac
  }
  export -f uname

  run _get_platform
  [[ "$output" == "mac-arm64" ]]
}

@test "_get_platform returns mac-x64 for Darwin x86_64" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  uname() {
    case "$1" in
      -s) echo "Darwin" ;;
      -m) echo "x86_64" ;;
      *)  command uname "$@" ;;
    esac
  }
  export -f uname

  run _get_platform
  [[ "$output" == "mac-x64" ]]
}

@test "_get_platform returns linux64 for Linux" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  uname() {
    case "$1" in
      -s) echo "Linux" ;;
      -m) echo "x86_64" ;;
      *)  command uname "$@" ;;
    esac
  }
  export -f uname

  run _get_platform
  [[ "$output" == "linux64" ]]
}

@test "_get_platform returns error for unsupported OS" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  uname() {
    case "$1" in
      -s) echo "FreeBSD" ;;
      -m) echo "amd64" ;;
      *)  command uname "$@" ;;
    esac
  }
  export -f uname

  run _get_platform
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported OS"* ]]
}

# =====================
# Version string parsing tests
# =====================

@test "Chrome version string is correctly parsed from 'Google Chrome 120.0.6099.109'" {
  version_output="Google Chrome 120.0.6099.109"
  result=$(echo "$version_output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
  [[ "$result" == "120.0.6099.109" ]]
}

@test "Chrome version string is correctly parsed from 'Chromium 119.0.6045.159'" {
  version_output="Chromium 119.0.6045.159"
  result=$(echo "$version_output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
  [[ "$result" == "119.0.6045.159" ]]
}

@test "Major version is extracted correctly via cut" {
  version="120.0.6099.109"
  major=$(echo "$version" | cut -d. -f1)
  [[ "$major" == "120" ]]
}

@test "Major version extraction works for single-digit versions" {
  version="9.0.100.0"
  major=$(echo "$version" | cut -d. -f1)
  [[ "$major" == "9" ]]
}

@test "Major version extraction works for three-digit versions" {
  version="131.0.6778.69"
  major=$(echo "$version" | cut -d. -f1)
  [[ "$major" == "131" ]]
}

# =====================
# _get_chrome_for_testing_json tests
# =====================

@test "_get_chrome_for_testing_json returns JSON on success" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  curl() {
    echo '{"channels":{"Stable":{"version":"120.0.6099.109"}}}'
  }
  export -f curl

  run _get_chrome_for_testing_json "https://example.com/test.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"120.0.6099.109"* ]]
}

@test "_get_chrome_for_testing_json fails when curl returns empty" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  curl() {
    echo ""
  }
  export -f curl

  run _get_chrome_for_testing_json "https://example.com/test.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Failed to fetch"* ]]
}

# =====================
# _download_chrome_headless_shell tests
# =====================

@test "_download_chrome_headless_shell returns cached binary if exists" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  local version="120.0.6099.109"
  local test_cache="${BATS_TEST_TMPDIR}/shellnium-cache"
  local cache_dir="${test_cache}/chrome-headless-shell-${version}"
  mkdir -p "$cache_dir"
  touch "${cache_dir}/chrome-headless-shell"
  chmod +x "${cache_dir}/chrome-headless-shell"

  SHELLNIUM_CACHE_DIR="$test_cache"
  SHELLNIUM_CHROME_VERSION="$version"

  run _download_chrome_headless_shell
  [ "$status" -eq 0 ]
  [[ "$output" == "$version" ]]
}

@test "_download_chrome_headless_shell sets SHELLNIUM_CHROME_BIN on cache hit" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  local version="120.0.6099.109"
  local test_cache="${BATS_TEST_TMPDIR}/shellnium-cache"
  local cache_dir="${test_cache}/chrome-headless-shell-${version}"
  mkdir -p "$cache_dir"
  touch "${cache_dir}/chrome-headless-shell"
  chmod +x "${cache_dir}/chrome-headless-shell"

  SHELLNIUM_CACHE_DIR="$test_cache"
  SHELLNIUM_CHROME_VERSION="$version"

  _download_chrome_headless_shell
  [[ "$SHELLNIUM_CHROME_BIN" == "${cache_dir}/chrome-headless-shell" ]]
}

# =====================
# _download_chromedriver version argument tests
# =====================

@test "_download_chromedriver uses provided version instead of detecting system Chrome" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  local test_cache="${BATS_TEST_TMPDIR}/shellnium-cache"
  local cache_dir="${test_cache}/chromedriver-120.0.6099.109"
  mkdir -p "$cache_dir"
  touch "${cache_dir}/chromedriver"
  chmod +x "${cache_dir}/chromedriver"

  SHELLNIUM_CACHE_DIR="$test_cache"

  run _download_chromedriver "120.0.6099.109"
  [ "$status" -eq 0 ]
  [[ "$output" == "${cache_dir}/chromedriver" ]]
}

# =====================
# setup_chromedriver Chrome auto-download tests
# =====================

@test "setup_chromedriver skips when SHELLNIUM_DRIVER_URL is set" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_DRIVER_URL="http://remote:9515"
  run setup_chromedriver
  [ "$status" -eq 0 ]
}

@test "_download_chromedriver prints only the binary path on a fresh download" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_CACHE_DIR="${BATS_TEST_TMPDIR}/shellnium-cache"

  # curl draws its progress bar on stderr; the legacy endpoint answers with
  # the driver version.
  curl() {
    local out="" prev=""
    for arg in "$@"; do
      [ "$prev" = "-o" ] && out="$arg"
      prev="$arg"
    done
    if [ -n "$out" ]; then
      echo "######## 100.0%" >&2
      touch "$out"
    else
      echo "100.0.4896.60"
    fi
  }
  unzip() {
    local dir="" prev=""
    for arg in "$@"; do
      [ "$prev" = "-d" ] && dir="$arg"
      prev="$arg"
    done
    touch "${dir}/chromedriver"
  }

  local bin
  bin=$(_download_chromedriver "100.0.4896.60" 2>/dev/null)
  [ "$bin" = "${SHELLNIUM_CACHE_DIR}/chromedriver-100.0.4896.60/chromedriver" ]
}

# =====================
# Browser selection
# =====================

@test "SHELLNIUM_BROWSER defaults to chrome on port 9515" {
  unset SHELLNIUM_BROWSER SHELLNIUM_PORT
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  [ "$SHELLNIUM_BROWSER" = "chrome" ]
  [ "$SHELLNIUM_PORT" = "9515" ]
}

@test "firefox uses port 4444 by default" {
  unset SHELLNIUM_PORT
  SHELLNIUM_BROWSER=firefox
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  [ "$SHELLNIUM_PORT" = "4444" ]
}

@test "SHELLNIUM_PORT overrides the default port of any browser" {
  SHELLNIUM_BROWSER=firefox
  SHELLNIUM_PORT=5555
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  [ "$SHELLNIUM_PORT" = "5555" ]
}

@test "setup_driver starts chromedriver for chrome" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  setup_chromedriver() { echo "chromedriver"; }
  setup_geckodriver() { echo "geckodriver"; }

  SHELLNIUM_BROWSER=chrome
  run setup_driver
  [ "$output" = "chromedriver" ]
}

@test "setup_driver starts geckodriver for firefox" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  setup_chromedriver() { echo "chromedriver"; }
  setup_geckodriver() { echo "geckodriver"; }

  SHELLNIUM_BROWSER=firefox
  run setup_driver
  [ "$output" = "geckodriver" ]
}

@test "setup_driver rejects an unsupported browser" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_BROWSER=netscape
  run setup_driver
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported browser: netscape"* ]]
}

# =====================
# GeckoDriver
# =====================

@test "_get_geckodriver_platform returns linux64 for Linux x86_64" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  uname() {
    case "$1" in
      -s) echo "Linux" ;;
      -m) echo "x86_64" ;;
    esac
  }

  run _get_geckodriver_platform
  [ "$output" = "linux64" ]
}

@test "_get_geckodriver_platform returns linux-aarch64 for Linux aarch64" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  uname() {
    case "$1" in
      -s) echo "Linux" ;;
      -m) echo "aarch64" ;;
    esac
  }

  run _get_geckodriver_platform
  [ "$output" = "linux-aarch64" ]
}

@test "_get_geckodriver_platform returns macos-aarch64 for Darwin arm64" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  uname() {
    case "$1" in
      -s) echo "Darwin" ;;
      -m) echo "arm64" ;;
    esac
  }

  run _get_geckodriver_platform
  [ "$output" = "macos-aarch64" ]
}

@test "_get_geckodriver_platform returns macos for Darwin x86_64" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  uname() {
    case "$1" in
      -s) echo "Darwin" ;;
      -m) echo "x86_64" ;;
    esac
  }

  run _get_geckodriver_platform
  [ "$output" = "macos" ]
}

@test "_get_geckodriver_platform returns error for unsupported OS" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"
  uname() { echo "FreeBSD"; }

  run _get_geckodriver_platform
  [ "$status" -eq 1 ]
}

@test "_get_firefox_bin prefers SHELLNIUM_FIREFOX_BIN" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_FIREFOX_BIN="/opt/firefox/firefox"
  run _get_firefox_bin
  [ "$status" -eq 0 ]
  [ "$output" = "/opt/firefox/firefox" ]
}

@test "_download_geckodriver returns cached binary if exists" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_CACHE_DIR="${BATS_TEST_TMPDIR}/shellnium-cache"
  SHELLNIUM_GECKODRIVER_VERSION="0.36.0"
  local cache_dir="${SHELLNIUM_CACHE_DIR}/geckodriver-v0.36.0"
  mkdir -p "$cache_dir"
  touch "${cache_dir}/geckodriver"
  chmod +x "${cache_dir}/geckodriver"

  run _download_geckodriver
  [ "$status" -eq 0 ]
  [ "$output" = "${cache_dir}/geckodriver" ]
}

@test "_download_geckodriver downloads the latest release for the platform" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_CACHE_DIR="${BATS_TEST_TMPDIR}/shellnium-cache"
  unset SHELLNIUM_GECKODRIVER_VERSION
  _get_geckodriver_platform() { echo "linux64"; }

  # The GitHub API answers with the latest release; the download draws a
  # progress bar on stderr.
  curl() {
    local out="" prev=""
    for arg in "$@"; do
      [ "$prev" = "-o" ] && out="$arg"
      prev="$arg"
    done
    echo "$*" >> "${BATS_TEST_TMPDIR}/curl.log"
    if [ -n "$out" ]; then
      echo "######## 100.0%" >&2
      touch "$out"
    else
      echo '{"tag_name": "v0.37.1"}'
    fi
  }
  tar() {
    local dir="" prev=""
    for arg in "$@"; do
      [ "$prev" = "-C" ] && dir="$arg"
      prev="$arg"
    done
    touch "${dir}/geckodriver"
  }

  local bin
  bin=$(_download_geckodriver 2>/dev/null)
  [ "$bin" = "${SHELLNIUM_CACHE_DIR}/geckodriver-v0.37.1/geckodriver" ]
  run cat "${BATS_TEST_TMPDIR}/curl.log"
  [[ "$output" == *"releases/download/v0.37.1/geckodriver-v0.37.1-linux64.tar.gz"* ]]
}

@test "_download_geckodriver fails when the latest version cannot be determined" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_CACHE_DIR="${BATS_TEST_TMPDIR}/shellnium-cache"
  unset SHELLNIUM_GECKODRIVER_VERSION
  curl() { return 22; }

  run _download_geckodriver
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not determine the latest GeckoDriver version"* ]]
}

@test "setup_geckodriver skips when SHELLNIUM_DRIVER_URL is set" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  SHELLNIUM_DRIVER_URL="http://localhost:4444"
  run setup_geckodriver
  [ "$status" -eq 0 ]
}

@test "setup_geckodriver fails when Firefox is not installed" {
  source "${SHELLNIUM_DIR}/lib/setup.sh"

  unset SHELLNIUM_DRIVER_URL
  _is_driver_running() { return 1; }
  _get_firefox_bin() { return 1; }

  run setup_geckodriver
  [ "$status" -eq 1 ]
  [[ "$output" == *"Firefox is not installed"* ]]
}
