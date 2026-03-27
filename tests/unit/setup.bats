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
