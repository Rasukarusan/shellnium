#!/usr/bin/env bash
get_version_google_chrome() {
  if [ "$(uname)" = 'Darwin' ]; then
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version
  elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome --version
  elif command -v google-chrome-stable >/dev/null 2>&1; then
    google-chrome-stable --version
  elif command -v chromium-browser >/dev/null 2>&1; then
    chromium-browser --version
  elif command -v chromium >/dev/null 2>&1; then
    chromium --version
  else
    echo ""
  fi
}

get_version_chromedriver() {
  chromedriver --version
}

detect_version() {
  local browserVersion
  browserVersion=$(get_version_google_chrome)
  if [ -z "$browserVersion" ]; then
    return
  fi

  local browserVer
  browserVer=$(echo "$browserVersion" | awk '{print $NF}' | awk -F '.' '{print $1}')
  local driverVer
  driverVer=$(get_version_chromedriver | awk '{print $2}' | awk -F '.' '{print $1}')

  if [ "$browserVer" != "$driverVer" ]; then
    printf "\e[35m**Make sure you have the right version of ChromeDriver and Google Chrome.**\e[m\n"
    printf "  Chrome:       %s\n" "$browserVersion"
    printf "  ChromeDriver: %s\n" "$(get_version_chromedriver)"
    exit 1
  fi
}
