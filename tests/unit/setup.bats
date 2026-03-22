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
