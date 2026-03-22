#!/usr/bin/env bash

# Resolve location of current script, in case it's executed from another folder.
SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &> /dev/null && pwd)"
# shellcheck source=lib/util.sh
source "${SCRIPT_DIR}/util.sh"
# shellcheck source=lib/core.sh
source "${SCRIPT_DIR}/core.sh"

init() {
  local sessionId
  sessionId=$(new_session "$@")
  export BASE_URL="${ROOT}/session/${sessionId}"

  if [ "$(is_ready)" != 'true' ]; then
    printf "\e[35m[ERROR] chromedriver is not running.\e[m\n"
    exit 1
  fi
}

detect_version
init "$@"
