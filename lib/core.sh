#!/usr/bin/env bash

ROOT=${SHELLNIUM_DRIVER_URL:-http://localhost:9515}

##############################
# Key Constants (W3C WebDriver)
##############################
# Use these with send_keys to send special keys.
# Example: send_keys "$element" "panda${KEY_ENTER}"

export KEY_NULL KEY_CANCEL KEY_HELP KEY_BACKSPACE KEY_TAB KEY_CLEAR
export KEY_RETURN KEY_ENTER KEY_SHIFT KEY_CONTROL KEY_ALT KEY_PAUSE KEY_ESCAPE
export KEY_SPACE KEY_PAGE_UP KEY_PAGE_DOWN KEY_END KEY_HOME
export KEY_ARROW_LEFT KEY_ARROW_UP KEY_ARROW_RIGHT KEY_ARROW_DOWN
export KEY_INSERT KEY_DELETE KEY_F1 KEY_F12 KEY_META

KEY_NULL=$(printf '\xee\x80\x80')       # U+E000
KEY_CANCEL=$(printf '\xee\x80\x81')     # U+E001
KEY_HELP=$(printf '\xee\x80\x82')       # U+E002
KEY_BACKSPACE=$(printf '\xee\x80\x83')  # U+E003
KEY_TAB=$(printf '\xee\x80\x84')        # U+E004
KEY_CLEAR=$(printf '\xee\x80\x85')      # U+E005
KEY_RETURN=$(printf '\xee\x80\x86')     # U+E006
KEY_ENTER=$(printf '\xee\x80\x87')      # U+E007
KEY_SHIFT=$(printf '\xee\x80\x88')      # U+E008
KEY_CONTROL=$(printf '\xee\x80\x89')    # U+E009
KEY_ALT=$(printf '\xee\x80\x8a')        # U+E00A
KEY_PAUSE=$(printf '\xee\x80\x8b')      # U+E00B
KEY_ESCAPE=$(printf '\xee\x80\x8c')     # U+E00C
KEY_SPACE=$(printf '\xee\x80\x8d')      # U+E00D
KEY_PAGE_UP=$(printf '\xee\x80\x8e')    # U+E00E
KEY_PAGE_DOWN=$(printf '\xee\x80\x8f')  # U+E00F
KEY_END=$(printf '\xee\x80\x90')        # U+E010
KEY_HOME=$(printf '\xee\x80\x91')       # U+E011
KEY_ARROW_LEFT=$(printf '\xee\x80\x92') # U+E012
KEY_ARROW_UP=$(printf '\xee\x80\x93')   # U+E013
KEY_ARROW_RIGHT=$(printf '\xee\x80\x94') # U+E014
KEY_ARROW_DOWN=$(printf '\xee\x80\x95') # U+E015
KEY_INSERT=$(printf '\xee\x80\x96')     # U+E016
KEY_DELETE=$(printf '\xee\x80\x97')     # U+E017
KEY_F1=$(printf '\xee\x80\xb1')         # U+E031
KEY_F12=$(printf '\xee\x80\xbc')        # U+E03C
KEY_META=$(printf '\xee\x80\xbd')       # U+E03D

_GET() {
  curl -s -X GET "$@"
}

_POST() {
  curl -s -X POST -H "Content-Type: application/json" "$@"
}

_DELETE() {
  curl -s -X DELETE "$@"
}

##############################
# Session
##############################

is_ready() {
  _GET "${ROOT}/status" | jq -r '.value.ready'
}

new_session() {
  local chromeOptions
  # Always include anti-automation-detection flags
  local allArgs=(
    "--disable-blink-features=AutomationControlled"
    "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    "--window-size=1920,1080"
    "$@"
  )

  # Append headless flag when SHELLNIUM_HEADLESS is enabled
  if [ "${SHELLNIUM_HEADLESS}" = "true" ] || [ "${SHELLNIUM_HEADLESS}" = "1" ]; then
    allArgs+=("--headless=new")
  fi
  chromeOptions=$(for i in "${allArgs[@]}"; do printf '"%s",' "${i}"; done | sed 's/,$//')
  _POST -d '{
    "desiredCapabilities": {
      "browserName":"chrome",
      "chromeOptions": {
        "args": ['"${chromeOptions}"'],
        "excludeSwitches": ["enable-automation", "enable-logging"],
        "useAutomationExtension": false
      }
    }
  }' "${ROOT}/session" | jq -r '.sessionId'
}

delete_session() {
  _DELETE "${BASE_URL}" > /dev/null
}

get_all_cookies() {
  _GET "${BASE_URL}/cookie" | jq -r '.value[]'
}

get_named_cookie() {
  local name=$1
  _GET "${BASE_URL}/cookie/${name}" | jq -r '.value'
}

add_cookie() {
  local cookie=$1
  local value="{\"cookie\": ${cookie}}"
  _POST -d "$value" "${BASE_URL}/cookie"
}

delete_cookie() {
  local name=$1
  _DELETE "${BASE_URL}/cookie/${name}" > /dev/null
}

delete_all_cookies() {
 	_DELETE "${BASE_URL}/cookie" > /dev/null
}

##############################
# Navigate
##############################

navigate_to() {
  local url=$1
  local payload
  payload=$(jq -n --arg url "$url" '{url: $url}')
  _POST -d "$payload" "${BASE_URL}/url" >/dev/null
}

get_current_url() {
  _GET "${BASE_URL}/url" | jq -r '.value'
}

get_title() {
  _GET "${BASE_URL}/title" | jq -r '.value'
}

back() {
  _POST "${BASE_URL}/back" >/dev/null
}

forward() {
  _POST "${BASE_URL}/forward" >/dev/null
}

refresh() {
  _POST "${BASE_URL}/refresh" >/dev/null
}

##############################
# Timeouts
##############################
get_timeouts() {
  _GET "${BASE_URL}/timeouts" | jq -r '.value'
}

set_timeouts() {
  local script=$1
  local pageLoad=$2
  local implicit=$3
  _POST -d "{\"script\": $script, \"pageLoad\": $pageLoad, \"implicit\": $implicit}" "${BASE_URL}/timeouts" >/dev/null
}

set_timeout_script() {
  local script=$1
  _POST -d "{\"script\": $script}" "${BASE_URL}/timeouts" >/dev/null
}

set_timeout_pageLoad() {
  local pageLoad=$1
  _POST -d "{\"pageLoad\": $pageLoad}" "${BASE_URL}/timeouts" >/dev/null
}

set_timeout_implicit() {
  local implicit=$1
  _POST -d "{\"implicit\": $implicit}" "${BASE_URL}/timeouts" >/dev/null
}

##############################
# Element Retrieval
##############################

#
# $property:
#   - "id"
#   - "name"
#   - "css selector"
#   - "link text"
#   - "partial link text"
#   - "tag name"
#   - "class name"
#   - "xpath"
#
find_element() {
  local property=$1
  local value=$2
  local payload
  payload=$(jq -n --arg using "$property" --arg value "$value" '{using: $using, value: $value}')
  _POST -d "$payload" "${BASE_URL}/element" | jq -r '.value.ELEMENT'
}

find_elements() {
  local property=$1
  local value=$2
  local payload
  payload=$(jq -n --arg using "$property" --arg value "$value" '{using: $using, value: $value}')
  _POST -d "$payload" "${BASE_URL}/elements" | jq -r '.value[].ELEMENT'
}

find_element_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  local payload
  payload=$(jq -n --arg using "$property" --arg value "$value" '{using: $using, value: $value}')
  _POST -d "$payload" "${BASE_URL}/element/${elementId}/element" | jq -r '.value.ELEMENT'
}

find_elements_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  local payload
  payload=$(jq -n --arg using "$property" --arg value "$value" '{using: $using, value: $value}')
  _POST -d "$payload" "${BASE_URL}/element/${elementId}/elements" | jq -r '.value[].ELEMENT'
}

get_active_element() {
  _GET "${BASE_URL}/element/active" | jq -r '.value.ELEMENT'
}

get_alert_text() {
  _GET "${BASE_URL}/alert/text" | jq -r '.value'
}

##############################
# Element State
##############################

get_attribute() {
  local elementId=$1
  local name=$2
  _GET "${BASE_URL}/element/${elementId}/attribute/${name}" | jq -r '.value'
}

get_property() {
  local elementId=$1
  local name=$2
  _GET "${BASE_URL}/element/${elementId}/property/${name}" | jq -r '.value'
}

get_css_value() {
  local elementId=$1
  local propertyName=$2
  _GET "${BASE_URL}/element/${elementId}/css/${propertyName}" | jq -r '.value'
}

get_text() {
  local elementId=$1
  _GET "${BASE_URL}/element/${elementId}/text" | jq -r '.value'
}

get_tag_name() {
  local elementId=$1
  _GET "${BASE_URL}/element/${elementId}/name" | jq -r '.value'
}

get_rect() {
  local elementId=$1
  _GET "${BASE_URL}/element/${elementId}/rect" | jq -r '.value'
}

get_page_source() {
  _GET "${BASE_URL}/source" | jq -r '.value'
}

is_element_enabled() {
  local elementId=$1
  _GET "${BASE_URL}/element/${elementId}/enabled" | jq -r '.value'
}

##############################
# Element Interaction
##############################

send_keys() {
  local elementId=$1
  local value=$2
  local payload
  payload=$(jq -n --arg value "$value" '{value: [$value]}')
  _POST -d "$payload" "${BASE_URL}/element/${elementId}/value" >/dev/null
}

send_alert_text() {
  local value=$1
  local payload
  payload=$(jq -n --arg value "$value" '{value: [$value]}')
  _POST -d "$payload" "${BASE_URL}/alert/text" >/dev/null
}

click() {
  local elementId=$1
  _POST "${BASE_URL}/element/${elementId}/click" >/dev/null
}

element_clear() {
  local elementId=$1
  _POST "${BASE_URL}/element/${elementId}/clear" >/dev/null
}

##############################
# Document
##############################

get_source() {
	_GET "${BASE_URL}/source"
}

exec_script() {
  local script args payload
  script=$(printf '%s' "$1" | jq -Rs '.')
  if [ -n "$2" ]; then
    args="[\"$2\"]"
  else
    args="[]"
  fi
  payload=$(printf '{"script": %s, "args": %s}' "$script" "$args")
  _POST -d "$payload" "${BASE_URL}/execute/sync"
}

element_screenshot() {
  local elementId=$1
  local path=${2:-./screenshot.png}
  _GET "${BASE_URL}/element/${elementId}/screenshot" | jq -r '.value' | base64 -d > "$path"
}

screenshot() {
  local path=${1:-./screenshot.png}
  _GET "${BASE_URL}/screenshot" | jq -r '.value' | base64 -d > "$path"
}


##############################
# Context
##############################

get_window_handle() {
  _GET "${BASE_URL}/window" | jq -r '.value'
}

get_window_handles() {
  _GET "${BASE_URL}/window/handles" | jq -r '.value[]'
}

delete_window() {
  curl -s -X DELETE "${BASE_URL}/window"
}

new_window() {
  local type=$1 # 'tab' or 'window'
  _POST -d "{\"type\":\"$type\"}" "${BASE_URL}/window/new" | jq -r '.value.handle'
}

switch_to_window() {
  local handle=$1
  _POST -d "{\"name\":\"$handle\"}" "${BASE_URL}/window" >/dev/null
}

#
# param is
#   - element
#   - integer
#   - id
#
switch_to_frame() {
  local id=$1

  # is element
  local frameId
  frameId=$(get_attribute "$id" 'id')
  if ! echo "$frameId" | grep "stale element reference" >/dev/null ; then
    _POST -d "{\"id\":\"$frameId\"}" "${BASE_URL}/frame" >/dev/null
    return
  fi

  if expr "$id" : "[0-9]*$" >&/dev/null;then # is integer
    _POST -d "{\"id\":$id}" "${BASE_URL}/frame" >/dev/null
  else # is id
    _POST -d "{\"id\":\"$id\"}" "${BASE_URL}/frame" >/dev/null
  fi
}

switch_to_parent_frame() {
  _POST "${BASE_URL}/frame/parent" >/dev/null
}

dismiss_alert() {
  local handle=$1
  _POST "${BASE_URL}/alert/dismiss" >/dev/null
}

accept_alert() {
  local handle=$1
  _POST "${BASE_URL}/alert/accept" >/dev/null
}

get_window_rect() {
  _GET "${BASE_URL}/window/rect" | jq -r '.value'
}

set_window_rect() {
  local x=$1
  local y=$2
  local width=$3
  local height=$4
  _POST -d "{\"x\": $x, \"y\": $y, \"width\": $width, \"height\": $height}" "${BASE_URL}/window/rect" | jq -r '.value'
}

maximize_window() {
  _POST "${BASE_URL}/window/maximize" | jq -r '.value'
}

minimize_window() {
  _POST "${BASE_URL}/window/minimize" | jq -r '.value'
}

fullscreen_window() {
  _POST "${BASE_URL}/window/fullscreen" | jq -r '.value'
}

##############################
# Actions
##############################

# Perform actions (low-level)
# https://www.w3.org/TR/webdriver/#perform-actions
perform_actions() {
  local actions_json="$1"
  _POST -d "$actions_json" "${BASE_URL}/actions" >/dev/null
}

# Release all actions
release_actions() {
  _DELETE "${BASE_URL}/actions" >/dev/null
}

# ---- Mouse Actions (convenience wrappers) ----

# Move mouse to element
mouse_move_to() {
  local element_id="$1"
  local actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":{\"ELEMENT\":\"${element_id}\"},\"x\":0,\"y\":0}]}]}"
  perform_actions "$actions"
}

# Double click on element
double_click() {
  local element_id="$1"
  local actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":{\"ELEMENT\":\"${element_id}\"},\"x\":0,\"y\":0},{\"type\":\"pointerDown\",\"button\":0},{\"type\":\"pointerUp\",\"button\":0},{\"type\":\"pointerDown\",\"button\":0},{\"type\":\"pointerUp\",\"button\":0}]}]}"
  perform_actions "$actions"
}

# Right click (context menu) on element
right_click() {
  local element_id="$1"
  local actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":{\"ELEMENT\":\"${element_id}\"},\"x\":0,\"y\":0},{\"type\":\"pointerDown\",\"button\":2},{\"type\":\"pointerUp\",\"button\":2}]}]}"
  perform_actions "$actions"
}

# Hover over element (alias for mouse_move_to)
hover() {
  mouse_move_to "$1"
}

# Drag and drop from source element to target element
drag_and_drop() {
  local source_id="$1"
  local target_id="$2"
  local actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":{\"ELEMENT\":\"${source_id}\"},\"x\":0,\"y\":0},{\"type\":\"pointerDown\",\"button\":0},{\"type\":\"pause\",\"duration\":200},{\"type\":\"pointerMove\",\"duration\":500,\"origin\":{\"ELEMENT\":\"${target_id}\"},\"x\":0,\"y\":0},{\"type\":\"pause\",\"duration\":100},{\"type\":\"pointerUp\",\"button\":0}]}]}"
  perform_actions "$actions"
}

# ---- Keyboard Actions (convenience wrappers) ----

# Press and release a key
key_press() {
  local key="$1"
  local actions="{\"actions\":[{\"type\":\"key\",\"id\":\"keyboard\",\"actions\":[{\"type\":\"keyDown\",\"value\":\"${key}\"},{\"type\":\"keyUp\",\"value\":\"${key}\"}]}]}"
  perform_actions "$actions"
}

# Hold a key down
key_down() {
  local key="$1"
  local actions="{\"actions\":[{\"type\":\"key\",\"id\":\"keyboard\",\"actions\":[{\"type\":\"keyDown\",\"value\":\"${key}\"}]}]}"
  perform_actions "$actions"
}

# Release a key
key_up() {
  local key="$1"
  local actions="{\"actions\":[{\"type\":\"key\",\"id\":\"keyboard\",\"actions\":[{\"type\":\"keyUp\",\"value\":\"${key}\"}]}]}"
  perform_actions "$actions"
}

# Send key combination (e.g., send_key_combo "\uE009" "a" for Ctrl+A)
# Common modifier keys: \uE009=Ctrl, \uE008=Shift, \uE00A=Alt, \uE03D=Meta
send_key_combo() {
  local modifier="$1"
  local key="$2"
  local actions="{\"actions\":[{\"type\":\"key\",\"id\":\"keyboard\",\"actions\":[{\"type\":\"keyDown\",\"value\":\"${modifier}\"},{\"type\":\"keyDown\",\"value\":\"${key}\"},{\"type\":\"keyUp\",\"value\":\"${key}\"},{\"type\":\"keyUp\",\"value\":\"${modifier}\"}]}]}"
  perform_actions "$actions"
}

##############################
# Element State (Display)
##############################

is_element_displayed() {
  local elementId=$1
  _GET "${BASE_URL}/element/${elementId}/displayed" | jq -r '.value'
}

##############################
# Wait / Retry
##############################

# Compare two numbers (supports float if bc is available, integer-only fallback)
_compare_lt() {
  local a=$1
  local b=$2
  if command -v bc >/dev/null 2>&1; then
    [ "$(echo "$a < $b" | bc)" -eq 1 ]
  else
    [ "${a%.*}" -lt "${b%.*}" ]
  fi
}

# Add two numbers (supports float if bc is available, integer-only fallback)
_add() {
  local a=$1
  local b=$2
  if command -v bc >/dev/null 2>&1; then
    echo "$a + $b" | bc
  else
    echo $(( ${a%.*} + ${b%.*} ))
  fi
}

# Wait until an element is found
# usage: wait_for_element "css selector" "#my-element" [timeout_sec] [interval_sec]
wait_for_element() {
  local property="$1"
  local value="$2"
  local timeout="${3:-10}"
  local interval="${4:-0.5}"
  local elapsed=0
  local element=""

  while _compare_lt "$elapsed" "$timeout"; do
    element=$(find_element "$property" "$value" 2>/dev/null)
    if [ -n "$element" ] && [ "$element" != "null" ]; then
      echo "$element"
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  echo "[shellnium] Timeout: element not found ($property: $value) after ${timeout}s" >&2
  return 1
}

# Wait until an element is displayed and enabled (clickable)
# usage: wait_for_clickable "css selector" "#my-button" [timeout_sec] [interval_sec]
wait_for_clickable() {
  local property="$1"
  local value="$2"
  local timeout="${3:-10}"
  local interval="${4:-0.5}"
  local elapsed=0
  local element=""

  while _compare_lt "$elapsed" "$timeout"; do
    element=$(find_element "$property" "$value" 2>/dev/null)
    if [ -n "$element" ] && [ "$element" != "null" ]; then
      local displayed
      local enabled
      displayed=$(is_element_displayed "$element" 2>/dev/null)
      enabled=$(is_element_enabled "$element" 2>/dev/null)
      if [ "$displayed" = "true" ] && [ "$enabled" = "true" ]; then
        echo "$element"
        return 0
      fi
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  echo "[shellnium] Timeout: element not clickable ($property: $value) after ${timeout}s" >&2
  return 1
}

# Wait until specific text appears in the page source
# usage: wait_for_text "some text" [timeout_sec] [interval_sec]
wait_for_text() {
  local text="$1"
  local timeout="${2:-10}"
  local interval="${3:-0.5}"
  local elapsed=0

  while _compare_lt "$elapsed" "$timeout"; do
    local source
    source=$(get_page_source 2>/dev/null)
    if echo "$source" | grep -q "$text"; then
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  echo "[shellnium] Timeout: text not found ('$text') after ${timeout}s" >&2
  return 1
}

# Wait until the current URL matches a pattern (grep regex)
# usage: wait_for_url "example\\.com/dashboard" [timeout_sec] [interval_sec]
wait_for_url() {
  local pattern="$1"
  local timeout="${2:-10}"
  local interval="${3:-0.5}"
  local elapsed=0

  while _compare_lt "$elapsed" "$timeout"; do
    local url
    url=$(get_current_url 2>/dev/null)
    if echo "$url" | grep -q "$pattern"; then
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  echo "[shellnium] Timeout: URL did not match ('$pattern') after ${timeout}s" >&2
  return 1
}

# Retry a command up to N times
# usage: retry <max_attempts> <interval_sec> <command> [args...]
retry() {
  local max_attempts="$1"
  local interval="$2"
  shift 2
  local attempt=1
  local result=""

  while [ "$attempt" -le "$max_attempts" ]; do
    result=$("$@" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$result" ] && [ "$result" != "null" ]; then
      echo "$result"
      return 0
    fi
    if [ "$attempt" -lt "$max_attempts" ]; then
      sleep "$interval"
    fi
    attempt=$((attempt + 1))
  done

  echo "[shellnium] Retry failed after ${max_attempts} attempts: $*" >&2
  return 1
}
