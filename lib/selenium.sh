#!/usr/bin/env bash

# Resolve location of current script, in case it's executed from another folder.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/util.sh"
source "${SCRIPT_DIR}/core.sh"

init() {
  local sessionId=$(new_session $@)
  BASE_URL=${ROOT}/session/$sessionId

  if [ "$(is_ready)" != 'true' ]; then
    printf "\e[35m[ERROR] chromedriver is not running.\e[m\n"
    exit
  fi
}

detect_version
init $@

