#!/usr/bin/env bash

# Resolve location of current script, in case it's executed from another folder.
SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &> /dev/null && pwd)"
# shellcheck source=lib/setup.sh
source "${SCRIPT_DIR}/setup.sh"
# shellcheck source=lib/core.sh
source "${SCRIPT_DIR}/core.sh"

init() {
  local sessionId
  sessionId=$(_plain new_session "$@")
  export BASE_URL="${ROOT}/session/${sessionId}"

  if [ -z "$sessionId" ] || [ "$sessionId" = "null" ]; then
    printf "\e[35m[ERROR] Could not start a %s session.\e[m\n" "$SHELLNIUM_BROWSER" >&2
    exit 1
  fi
}

setup_driver || exit 1
trap cleanup_driver EXIT
# The driver may have been started on a port chosen in setup.sh
ROOT="${SHELLNIUM_DRIVER_URL}"
init "$@"
