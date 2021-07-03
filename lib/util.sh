#!/usr/bin/env bash
get_version_google_chrome() {
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version
}

get_version_chromedriver() {
  chromedriver --version
}

detect_version() {
  if [ "$(uname)" == 'Darwin' ]; then
    local browserVer=$(get_version_google_chrome | awk '{print $3}' | awk -F '.' '{print $1$2}')
    local driverVer=$(get_version_chromedriver | awk '{print $2}' | awk -F '.' '{print $1$2}')
    if [ $browserVer -ne $driverVer ];then
      printf "\e[35m**Make sure you have the right version of Chromedriver and GoogleChrome.**\e[m\n"
      get_version_google_chrome
      get_version_chromedriver
      exit
    fi
  fi
}
