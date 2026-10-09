#!/usr/bin/env bash

# Resolve location of current script, in case it's executed from another folder.
SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &> /dev/null && pwd)"
# shellcheck source=lib/setup.sh
source "${SCRIPT_DIR}/setup.sh"
# shellcheck source=lib/core.sh
source "${SCRIPT_DIR}/core.sh"

# Start the driver of the selected browser and open a session.
# Arguments are passed to the browser; --headless turns headless mode on
# whatever the browser.
# Call it directly, not inside $( ): the session lives in the variables it
# sets in the current shell.
# usage: start_session [--headless] [browser arguments...]
start_session() {
  local sessionId arg
  local browserArgs=()
  for arg in "$@"; do
    if [ "$arg" = "--headless" ]; then
      export SHELLNIUM_HEADLESS=true
    else
      browserArgs+=("$arg")
    fi
  done

  setup_driver || {
    _fail "driver not started" "Error: could not start the $SHELLNIUM_BROWSER driver"
    return 1
  }
  # The driver may have been started on a port chosen in setup.sh
  ROOT="${SHELLNIUM_DRIVER_URL}"

  sessionId=$(_plain new_session ${browserArgs[@]+"${browserArgs[@]}"})
  if [ -z "$sessionId" ] || [ "$sessionId" = "null" ]; then
    _fail "session not created" "Error: could not start a $SHELLNIUM_BROWSER session"
    return 1
  fi
  export BASE_URL="${ROOT}/session/${sessionId}"
  _ok
}

# Close the session and stop the driver if start_session started it.
end_session() {
  local failed=false
  if [ -n "${BASE_URL:-}" ]; then
    _plain delete_session || failed=true
    unset BASE_URL
  fi
  cleanup_driver
  if [ "$failed" = false ]; then
    _ok
  else
    _fail "session not closed" "Error: could not close the session"
  fi
}

# Kept for scripts that call it: opens a session or exits.
init() {
  start_session "$@" >/dev/null || exit 1
}

# Options for this file, taken out of the arguments meant for the browser:
#   --no-init  load the library only; call start_session when ready
#   --agent    headless, JSON output and quiet logs, for AI agents
_shellnium_init=true
_shellnium_args=()
for _shellnium_arg in "$@"; do
  case "$_shellnium_arg" in
    --no-init) _shellnium_init=false ;;
    --agent)
      export SHELLNIUM_HEADLESS=true
      export SHELLNIUM_OUTPUT=json
      export SHELLNIUM_LOG_LEVEL="${SHELLNIUM_LOG_LEVEL:-error}"
      ;;
    *) _shellnium_args+=("$_shellnium_arg") ;;
  esac
done
unset _shellnium_arg

trap cleanup_driver EXIT
if [ "$_shellnium_init" = true ]; then
  init ${_shellnium_args[@]+"${_shellnium_args[@]}"}
fi
unset _shellnium_init _shellnium_args
