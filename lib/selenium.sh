#!/usr/bin/env bash
source ./lib/util.sh
source ./lib/core.sh

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

