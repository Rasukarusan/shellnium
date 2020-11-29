#!/usr/bin/env bash
source ./util.sh
source ./core.sh

ROOT=http://localhost:9515

GET='curl -s -X GET'
POST='curl -s -X POST -H "Content-Type: application/json"'

chromeOptions=$(for i in $@; do printf "\"${i}\",";done | sed 's/,$//')
sessionId=$(new_session)
BASE_URL=${ROOT}/session/$sessionId

if [ "$(is_ready)" != 'true' ]; then
  echo "[ERROR] chromedriver is not running."
  exit
fi
