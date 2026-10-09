#!/usr/bin/env bats

# Session control in lib/selenium.sh, with the driver and the browser mocked.

setup() {
  SHELLNIUM_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
  unset SHELLNIUM_HEADLESS SHELLNIUM_OUTPUT SHELLNIUM_LOG_LEVEL SHELLNIUM_DRIVER_URL BASE_URL
  CALLS="${BATS_TEST_TMPDIR}/calls.log"
  : > "$CALLS"
}

# Replace everything that would touch a real driver.
_mock_driver() {
  setup_driver() { echo "setup_driver" >> "$CALLS"; export SHELLNIUM_DRIVER_URL="http://localhost:9515"; }
  cleanup_driver() { echo "cleanup_driver" >> "$CALLS"; }
  new_session() { echo "new_session $*" >> "$CALLS"; echo "session-1"; }
  delete_session() { echo "delete_session" >> "$CALLS"; }
}

@test "--no-init loads the library without starting anything" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init

  [ -z "${BASE_URL:-}" ]
  declare -F find_element >/dev/null
  declare -F start_session >/dev/null
}

@test "--no-init and --agent are not passed to the browser" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init --agent
  _mock_driver

  start_session --lang=es
  run cat "$CALLS"
  [[ "$output" == *"new_session --lang=es"* ]]
  [[ "$output" != *"--no-init"* ]]
  [[ "$output" != *"--agent"* ]]
}

@test "--agent turns on headless mode, JSON output and quiet logs" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init --agent

  [ "$SHELLNIUM_HEADLESS" = "true" ]
  [ "$SHELLNIUM_OUTPUT" = "json" ]
  [ "$SHELLNIUM_LOG_LEVEL" = "error" ]
}

@test "--agent keeps a log level chosen by the user" {
  SHELLNIUM_LOG_LEVEL=debug
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init --agent

  [ "$SHELLNIUM_LOG_LEVEL" = "debug" ]
}

@test "start_session sets up the driver and opens a session" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _mock_driver

  start_session
  [ "$BASE_URL" = "http://localhost:9515/session/session-1" ]
  [ "$ROOT" = "http://localhost:9515" ]
  run cat "$CALLS"
  [ "${lines[0]}" = "setup_driver" ]
  [[ "${lines[1]}" == "new_session"* ]]
}

@test "start_session prints nothing in plain mode and ok in JSON mode" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _mock_driver

  run start_session
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  SHELLNIUM_OUTPUT=json run start_session
  [ "$output" = '{"ok":true}' ]
}

@test "start_session --headless enables headless mode and keeps other arguments" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _mock_driver

  start_session --headless --lang=es
  [ "$SHELLNIUM_HEADLESS" = "true" ]
  run cat "$CALLS"
  [[ "$output" == *"new_session --lang=es"* ]]
  [[ "$output" != *"--headless"* ]]
}

@test "start_session fails when the driver cannot be started" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _mock_driver
  setup_driver() { return 1; }

  run start_session
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not start the chrome driver"* ]]
}

@test "start_session fails when no session comes back" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _mock_driver
  new_session() { return 1; }

  run start_session
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not start a chrome session"* ]]
}

@test "end_session closes the session and stops the driver" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _mock_driver

  start_session
  end_session
  [ -z "${BASE_URL:-}" ]
  run cat "$CALLS"
  [[ "$output" == *"delete_session"* ]]
  [[ "$output" == *"cleanup_driver"* ]]
}

@test "end_session without a session only stops the driver" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _mock_driver

  run end_session
  [ "$status" -eq 0 ]
  run cat "$CALLS"
  [[ "$output" != *"delete_session"* ]]
  [[ "$output" == *"cleanup_driver"* ]]
}

@test "cleanup_driver forgets a driver URL chosen by shellnium" {
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init
  _is_driver_running() { return 0; }
  _is_chromedriver_running() { return 0; }

  setup_driver
  [ "$SHELLNIUM_DRIVER_URL" = "http://localhost:9515" ]
  cleanup_driver
  [ -z "${SHELLNIUM_DRIVER_URL:-}" ]
}

@test "cleanup_driver keeps a driver URL set by the user" {
  SHELLNIUM_DRIVER_URL="http://selenium:4444"
  source "${SHELLNIUM_DIR}/lib/selenium.sh" --no-init

  setup_driver
  cleanup_driver
  [ "$SHELLNIUM_DRIVER_URL" = "http://selenium:4444" ]
}
