#!/usr/bin/env bats

setup() {
  SHELLNIUM_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
}

# =====================
# Syntax validation (bash -n)
# =====================

@test "lib/core.sh has no syntax errors" {
  run bash -n "${SHELLNIUM_DIR}/lib/core.sh"
  [ "$status" -eq 0 ]
}

@test "lib/setup.sh has no syntax errors" {
  run bash -n "${SHELLNIUM_DIR}/lib/setup.sh"
  [ "$status" -eq 0 ]
}

@test "lib/selenium.sh has no syntax errors" {
  run bash -n "${SHELLNIUM_DIR}/lib/selenium.sh"
  [ "$status" -eq 0 ]
}

@test "lib/util.sh has no syntax errors" {
  run bash -n "${SHELLNIUM_DIR}/lib/util.sh"
  [ "$status" -eq 0 ]
}

@test "demo.sh has no syntax errors" {
  run bash -n "${SHELLNIUM_DIR}/demo.sh"
  [ "$status" -eq 0 ]
}

@test "demo2.sh has no syntax errors" {
  run bash -n "${SHELLNIUM_DIR}/demo2.sh"
  [ "$status" -eq 0 ]
}

@test "demo3.sh has no syntax errors" {
  run bash -n "${SHELLNIUM_DIR}/demo3.sh"
  [ "$status" -eq 0 ]
}

# =====================
# ShellCheck (if available)
# =====================

@test "lib/core.sh passes shellcheck" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck is not installed"
  fi
  run shellcheck -s bash -e SC1091 "${SHELLNIUM_DIR}/lib/core.sh"
  [ "$status" -eq 0 ]
}

@test "lib/setup.sh passes shellcheck" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck is not installed"
  fi
  run shellcheck -s bash -e SC1091 "${SHELLNIUM_DIR}/lib/setup.sh"
  [ "$status" -eq 0 ]
}

@test "lib/util.sh passes shellcheck" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck is not installed"
  fi
  run shellcheck -s bash -e SC1091 "${SHELLNIUM_DIR}/lib/util.sh"
  [ "$status" -eq 0 ]
}
