#!/usr/bin/env bash
source ./lib/util.sh
source ./lib/core.sh

ROOT=http://localhost:9515

GET='curl -s -X GET'
POST='curl -s -X POST -H "Content-Type: application/json"'

if [ "$(uname)" == 'Darwin' ]; then
  browserVer=$(get_version_google_chrome | awk '{print $3}' | awk -F '.' '{print $1$2}')
  driverVer=$(get_version_chromedriver | awk '{print $2}' | awk -F '.' '{print $1$2}')
  if [ $browserVer -ne $driverVer ];then
    printf "\e[35m**Make sure you have the right version of Chromedriver and GoogleChrome.**\e[m\n"
    get_version_google_chrome 
    get_version_chromedriver
    exit
  fi
fi

chromeOptions=$(for i in $@; do printf "\"${i}\",";done | sed 's/,$//')
sessionId=$(new_session)
BASE_URL=${ROOT}/session/$sessionId

if [ "$(is_ready)" != 'true' ]; then
  printf "\e[35m[ERROR] chromedriver is not running.\e[m\n"
  exit
fi
