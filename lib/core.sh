#!/usr/bin/env bash

ROOT=${SHELLNIUM_DRIVER_URL:-http://localhost:9515}

# Debug logging - enable with SHELLNIUM_DEBUG=true
_shellnium_log() {
  if [ "${SHELLNIUM_DEBUG:-}" = "true" ]; then
    echo "[shellnium] $*" >&2
  fi
}

# Check WebDriver error response and surface error messages to stderr.
# No response at all (the driver is not running, the session is gone) is an
# error too.
_check_error() {
  local response="$1"
  local error
  if [ -z "$response" ]; then
    echo "[shellnium] Error: no response from the driver" >&2
    return 1
  fi
  error=$(printf '%s\n' "$response" | jq -r '.value.error? // empty' 2>/dev/null)
  if [ -n "$error" ]; then
    local message
    message=$(printf '%s\n' "$response" | jq -r '.value.message? // empty' 2>/dev/null)
    echo "[shellnium] Error: $error - $message" >&2
    return 1
  fi
  return 0
}

# Print the value of a response, or fail if it is a WebDriver error.
# usage: _value "$response" [jq filter]
_value() {
  local response="$1"
  local filter="${2:-.value}"
  _check_error "$response" || return 1
  printf '%s\n' "$response" | jq -r "$filter"
}

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
  _shellnium_log "GET $1"
  local response
  response=$(curl -s -X GET "$@")
  _shellnium_log "Response: $response"
  printf '%s\n' "$response"
}

_POST() {
  _shellnium_log "POST ${*: -1}"
  local response
  response=$(curl -s -X POST -H "Content-Type: application/json" "$@")
  _shellnium_log "Response: $response"
  printf '%s\n' "$response"
}

_DELETE() {
  _shellnium_log "DELETE $1"
  local response
  response=$(curl -s -X DELETE "$@")
  _shellnium_log "Response: $response"
  printf '%s\n' "$response"
}

##############################
# Element references
##############################

# Key under which the W3C WebDriver protocol returns an element reference.
# https://www.w3.org/TR/webdriver/#elements
W3C_ELEMENT_KEY="element-6066-11e4-a52e-4f735466cecf"

# Read the element id(s) out of a find-element response. Drivers that still
# answer in the legacy JSON Wire format use the "ELEMENT" key instead.
_element_id() {
  jq -r --arg key "$W3C_ELEMENT_KEY" '.value | (.[$key] // .ELEMENT)'
}

_element_ids() {
  jq -r --arg key "$W3C_ELEMENT_KEY" '.value[] | (.[$key] // .ELEMENT)'
}

# Build the JSON reference to an element, as expected in request payloads.
_element_ref() {
  jq -cn --arg key "$W3C_ELEMENT_KEY" --arg id "$1" '{($key): $id, ELEMENT: $id}'
}

##############################
# Session
##############################

is_ready() {
  _GET "${ROOT}/status" | jq -r '.value.ready'
}

# JSON list of the given strings
_json_array() {
  if [ $# -eq 0 ]; then
    echo '[]'
  else
    printf '%s\n' "$@" | jq -R . | jq -sc .
  fi
}

# Capabilities for Chrome. Extra arguments are passed to the browser.
_chrome_capabilities() {
  # Always include anti-automation-detection flags
  local allArgs=(
    "--disable-blink-features=AutomationControlled"
    "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    "--window-size=1920,1080"
    "$@"
  )

  # Append headless flag when SHELLNIUM_HEADLESS is enabled
  if [ "${SHELLNIUM_HEADLESS:-}" = "true" ] || [ "${SHELLNIUM_HEADLESS:-}" = "1" ]; then
    allArgs+=("--headless=new")
  fi

  # Point to downloaded chrome-headless-shell binary if set
  jq -n --argjson args "$(_json_array "${allArgs[@]}")" --arg binary "${SHELLNIUM_CHROME_BIN:-}" '{
    capabilities: {
      alwaysMatch: {
        browserName: "chrome",
        "goog:chromeOptions": ({
          args: $args,
          excludeSwitches: ["enable-automation", "enable-logging"],
          useAutomationExtension: false
        } + (if $binary == "" then {} else {binary: $binary} end))
      }
    }
  }'
}

# Capabilities for Firefox. Extra arguments are passed to the browser.
_firefox_capabilities() {
  # Firefox keeps the first value of a repeated argument, so the defaults go
  # last and can be overridden.
  local allArgs=("$@" "-width" "1920" "-height" "1080")

  if [ "${SHELLNIUM_HEADLESS:-}" = "true" ] || [ "${SHELLNIUM_HEADLESS:-}" = "1" ]; then
    allArgs+=("-headless")
  fi

  jq -n --argjson args "$(_json_array "${allArgs[@]}")" --arg binary "${SHELLNIUM_FIREFOX_BIN:-}" '{
    capabilities: {
      alwaysMatch: {
        browserName: "firefox",
        "moz:firefoxOptions": ({args: $args} + (if $binary == "" then {} else {binary: $binary} end))
      }
    }
  }'
}

new_session() {
  local capabilities response
  case "${SHELLNIUM_BROWSER:-chrome}" in
    firefox) capabilities=$(_firefox_capabilities "$@") ;;
    *)       capabilities=$(_chrome_capabilities "$@") ;;
  esac

  response=$(_POST -d "$capabilities" "${ROOT}/session")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | jq -r '.value.sessionId // .sessionId'
}

delete_session() {
  local response
  response=$(_DELETE "${BASE_URL}")
  _check_error "$response"
}

get_all_cookies() {
  local response
  response=$(_GET "${BASE_URL}/cookie")
  _value "$response" '.value[]'
}

get_named_cookie() {
  local name=$1
  local response
  response=$(_GET "${BASE_URL}/cookie/${name}")
  _value "$response"
}

add_cookie() {
  local cookie=$1
  local value="{\"cookie\": ${cookie}}"
  local response
  response=$(_POST -d "$value" "${BASE_URL}/cookie")
  _check_error "$response"
}

delete_cookie() {
  local name=$1
  local response
  response=$(_DELETE "${BASE_URL}/cookie/${name}")
  _check_error "$response"
}

delete_all_cookies() {
  local response
  response=$(_DELETE "${BASE_URL}/cookie")
  _check_error "$response"
}

##############################
# Navigate
##############################

navigate_to() {
  local url=$1
  local payload response
  payload=$(jq -n --arg url "$url" '{url: $url}')
  response=$(_POST -d "$payload" "${BASE_URL}/url")
  _check_error "$response"
}

get_current_url() {
  local response
  response=$(_GET "${BASE_URL}/url")
  _value "$response"
}

get_title() {
  local response
  response=$(_GET "${BASE_URL}/title")
  _value "$response"
}

back() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/back")
  _check_error "$response"
}

forward() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/forward")
  _check_error "$response"
}

refresh() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/refresh")
  _check_error "$response"
}

##############################
# Timeouts
##############################
get_timeouts() {
  local response
  response=$(_GET "${BASE_URL}/timeouts")
  _value "$response"
}

set_timeouts() {
  local script=$1
  local pageLoad=$2
  local implicit=$3
  local response
  response=$(_POST -d "{\"script\": $script, \"pageLoad\": $pageLoad, \"implicit\": $implicit}" "${BASE_URL}/timeouts")
  _check_error "$response"
}

set_timeout_script() {
  local script=$1
  local response
  response=$(_POST -d "{\"script\": $script}" "${BASE_URL}/timeouts")
  _check_error "$response"
}

set_timeout_pageLoad() {
  local pageLoad=$1
  local response
  response=$(_POST -d "{\"pageLoad\": $pageLoad}" "${BASE_URL}/timeouts")
  _check_error "$response"
}

set_timeout_implicit() {
  local implicit=$1
  local response
  response=$(_POST -d "{\"implicit\": $implicit}" "${BASE_URL}/timeouts")
  _check_error "$response"
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
# The W3C protocol only knows "css selector", "link text", "partial link
# text", "tag name" and "xpath". The other strategies are expressed as CSS.
_locator() {
  jq -n --arg using "$1" --arg value "$2" '
    def quoted: "\"" + ($value | gsub("\\\\"; "\\\\") | gsub("\""; "\\\"")) + "\"";
    if   $using == "id"         then {using: "css selector", value: ("[id=" + quoted + "]")}
    elif $using == "name"       then {using: "css selector", value: ("[name=" + quoted + "]")}
    elif $using == "class name" then {using: "css selector", value: ("." + $value)}
    else {using: $using, value: $value}
    end'
}

find_element() {
  local property=$1
  local value=$2
  local payload response
  payload=$(_locator "$property" "$value")
  response=$(_POST -d "$payload" "${BASE_URL}/element")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | _element_id
}

find_elements() {
  local property=$1
  local value=$2
  local payload response
  payload=$(_locator "$property" "$value")
  response=$(_POST -d "$payload" "${BASE_URL}/elements")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | _element_ids
}

find_element_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  local payload response
  payload=$(_locator "$property" "$value")
  response=$(_POST -d "$payload" "${BASE_URL}/element/${elementId}/element")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | _element_id
}

find_elements_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  local payload response
  payload=$(_locator "$property" "$value")
  response=$(_POST -d "$payload" "${BASE_URL}/element/${elementId}/elements")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | _element_ids
}

get_active_element() {
  local response
  response=$(_GET "${BASE_URL}/element/active")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | _element_id
}

get_alert_text() {
  local response
  response=$(_GET "${BASE_URL}/alert/text")
  _value "$response"
}

##############################
# Element State
##############################

# Selenium-style attribute lookup. The W3C "Get Element Attribute" command
# only returns what is written in the HTML, so the current value of an input
# or the state of a checkbox would be lost. This mirrors what the drivers did
# in legacy mode (and what Selenium clients still do): prefer the live
# property, and fall back to the attribute.
_GET_ATTRIBUTE_SCRIPT='
var e = arguments[0], n = arguments[1], l = n.toLowerCase();
var booleans = ["async", "autofocus", "autoplay", "checked", "controls", "default", "defer", "disabled", "hidden", "loop", "multiple", "muted", "novalidate", "open", "readonly", "required", "reversed", "selected"];
var aliases = {"class": "className", "readonly": "readOnly"};
if (l === "style") { return e.style.cssText; }
if (l === "selected" || l === "checked") {
  var on = e.tagName === "OPTION" ? e.selected : e.checked;
  return on ? "true" : null;
}
if (booleans.indexOf(l) >= 0) {
  return (e.hasAttribute(n) || e[aliases[l] || n] === true) ? "true" : null;
}
if ((e.tagName === "A" && l === "href") || (e.tagName === "IMG" && l === "src")) {
  return e.hasAttribute(n) ? e[l] : null;
}
var p = e[aliases[n] || n];
if (p === null || p === undefined || typeof p === "object" || typeof p === "function") {
  return e.getAttribute(n);
}
return String(p);'

get_attribute() {
  local elementId=$1
  local name=$2
  local payload
  payload=$(jq -n --arg script "$_GET_ATTRIBUTE_SCRIPT" --argjson element "$(_element_ref "$elementId")" --arg name "$name" \
    '{script: $script, args: [$element, $name]}')
  local response
  response=$(_POST -d "$payload" "${BASE_URL}/execute/sync")
  _value "$response"
}

# The attribute exactly as written in the HTML, or null when it is absent.
# https://www.w3.org/TR/webdriver/#get-element-attribute
get_dom_attribute() {
  local elementId=$1
  local name=$2
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/attribute/${name}")
  _value "$response"
}

get_property() {
  local elementId=$1
  local name=$2
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/property/${name}")
  _value "$response"
}

get_css_value() {
  local elementId=$1
  local propertyName=$2
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/css/${propertyName}")
  _value "$response"
}

get_text() {
  local elementId=$1
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/text")
  _value "$response"
}

get_tag_name() {
  local elementId=$1
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/name")
  _value "$response"
}

get_rect() {
  local elementId=$1
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/rect")
  _value "$response"
}

get_page_source() {
  local response
  response=$(_GET "${BASE_URL}/source")
  _value "$response"
}

is_element_enabled() {
  local elementId=$1
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/enabled")
  _value "$response"
}

##############################
# Element Interaction
##############################

send_keys() {
  local elementId=$1
  local value=$2
  local payload response
  payload=$(jq -n --arg value "$value" '{text: $value, value: [$value]}')
  response=$(_POST -d "$payload" "${BASE_URL}/element/${elementId}/value")
  _check_error "$response"
}

send_alert_text() {
  local value=$1
  local payload response
  payload=$(jq -n --arg value "$value" '{text: $value}')
  response=$(_POST -d "$payload" "${BASE_URL}/alert/text")
  _check_error "$response"
}

click() {
  local elementId=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/element/${elementId}/click")
  _check_error "$response"
}

element_clear() {
  local elementId=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/element/${elementId}/clear")
  _check_error "$response"
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
  local response
  response=$(_POST -d "$payload" "${BASE_URL}/execute/sync")
  _check_error "$response" || return 1
  printf '%s\n' "$response"
}

element_screenshot() {
  local elementId=$1
  local file=${2:-./screenshot.png}
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/screenshot")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | jq -r '.value' | base64 -d > "$file"
}

screenshot() {
  local file=${1:-./screenshot.png}
  local response
  response=$(_GET "${BASE_URL}/screenshot")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | jq -r '.value' | base64 -d > "$file"
}


##############################
# Context
##############################

get_window_handle() {
  local response
  response=$(_GET "${BASE_URL}/window")
  _value "$response"
}

get_window_handles() {
  local response
  response=$(_GET "${BASE_URL}/window/handles")
  _value "$response" '.value[]'
}

delete_window() {
  local response
  response=$(_DELETE "${BASE_URL}/window")
  _check_error "$response"
}

new_window() {
  local type=$1 # 'tab' or 'window'
  local response
  response=$(_POST -d "{\"type\":\"$type\"}" "${BASE_URL}/window/new")
  _value "$response" '.value.handle'
}

switch_to_window() {
  local handle=$1
  local response
  response=$(_POST -d "{\"handle\":\"$handle\",\"name\":\"$handle\"}" "${BASE_URL}/window")
  _check_error "$response"
}

#
# param is
#   - element
#   - integer
#   - id
#
switch_to_frame() {
  local id=$1
  local response

  # is integer
  if [[ "$id" =~ ^[0-9]+$ ]]; then
    response=$(_POST -d "{\"id\":$id}" "${BASE_URL}/frame")
    _check_error "$response"
    return
  fi

  # is element
  response=$(_POST -d "{\"id\":$(_element_ref "$id")}" "${BASE_URL}/frame")
  if _check_error "$response" 2>/dev/null; then
    return 0
  fi

  # is the id (or name) attribute of a frame
  local frame
  frame=$(find_element 'css selector' "[id=\"$id\"],[name=\"$id\"]") || return 1
  response=$(_POST -d "{\"id\":$(_element_ref "$frame")}" "${BASE_URL}/frame")
  _check_error "$response"
}

switch_to_parent_frame() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/frame/parent")
  _check_error "$response"
}

dismiss_alert() {
  local handle=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/alert/dismiss")
  _check_error "$response"
}

accept_alert() {
  local handle=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/alert/accept")
  _check_error "$response"
}

get_window_rect() {
  local response
  response=$(_GET "${BASE_URL}/window/rect")
  _value "$response"
}

set_window_rect() {
  local x=$1
  local y=$2
  local width=$3
  local height=$4
  local response
  response=$(_POST -d "{\"x\": $x, \"y\": $y, \"width\": $width, \"height\": $height}" "${BASE_URL}/window/rect")
  _value "$response"
}

maximize_window() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/window/maximize")
  _value "$response"
}

minimize_window() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/window/minimize")
  _value "$response"
}

fullscreen_window() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/window/fullscreen")
  _value "$response"
}

##############################
# Actions
##############################

# Perform actions (low-level)
# https://www.w3.org/TR/webdriver/#perform-actions
perform_actions() {
  local actions_json="$1"
  local response
  response=$(_POST -d "$actions_json" "${BASE_URL}/actions")
  _check_error "$response"
}

# Release all actions
release_actions() {
  local response
  response=$(_DELETE "${BASE_URL}/actions")
  _check_error "$response"
}

# ---- Mouse Actions (convenience wrappers) ----

# Move mouse to element
mouse_move_to() {
  local element_id="$1"
  local actions origin
  origin=$(_element_ref "$element_id")
  actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":${origin},\"x\":0,\"y\":0}]}]}"
  perform_actions "$actions"
}

# Double click on element
double_click() {
  local element_id="$1"
  local actions origin
  origin=$(_element_ref "$element_id")
  actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":${origin},\"x\":0,\"y\":0},{\"type\":\"pointerDown\",\"button\":0},{\"type\":\"pointerUp\",\"button\":0},{\"type\":\"pointerDown\",\"button\":0},{\"type\":\"pointerUp\",\"button\":0}]}]}"
  perform_actions "$actions"
}

# Right click (context menu) on element
right_click() {
  local element_id="$1"
  local actions origin
  origin=$(_element_ref "$element_id")
  actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":${origin},\"x\":0,\"y\":0},{\"type\":\"pointerDown\",\"button\":2},{\"type\":\"pointerUp\",\"button\":2}]}]}"
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
  local actions origin_source origin_target
  origin_source=$(_element_ref "$source_id")
  origin_target=$(_element_ref "$target_id")
  actions="{\"actions\":[{\"type\":\"pointer\",\"id\":\"mouse\",\"parameters\":{\"pointerType\":\"mouse\"},\"actions\":[{\"type\":\"pointerMove\",\"duration\":100,\"origin\":${origin_source},\"x\":0,\"y\":0},{\"type\":\"pointerDown\",\"button\":0},{\"type\":\"pause\",\"duration\":200},{\"type\":\"pointerMove\",\"duration\":500,\"origin\":${origin_target},\"x\":0,\"y\":0},{\"type\":\"pause\",\"duration\":100},{\"type\":\"pointerUp\",\"button\":0}]}]}"
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
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/displayed")
  _value "$response"
}

##############################
# Wait / Retry
##############################

# Compare two numbers, which may have decimals
_compare_lt() {
  awk -v a="$1" -v b="$2" 'BEGIN { exit !(a < b) }'
}

# Add two numbers, which may have decimals
_add() {
  awk -v a="$1" -v b="$2" 'BEGIN { print a + b }'
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
      printf '%s\n' "$element"
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
        printf '%s\n' "$element"
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
    if printf '%s\n' "$source" | grep -q "$text"; then
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
    if printf '%s\n' "$url" | grep -q "$pattern"; then
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  echo "[shellnium] Timeout: URL did not match ('$pattern') after ${timeout}s" >&2
  return 1
}

# Wait until the current URL contains a string
# usage: wait_for_url_contains "/dashboard" [timeout_sec] [interval_sec]
wait_for_url_contains() {
  local text="$1"
  local timeout="${2:-10}"
  local interval="${3:-0.5}"
  local elapsed=0

  while _compare_lt "$elapsed" "$timeout"; do
    local url
    url=$(get_current_url 2>/dev/null)
    if printf '%s\n' "$url" | grep -qF -- "$text"; then
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  echo "[shellnium] Timeout: URL did not contain '$text' after ${timeout}s" >&2
  return 1
}

# Wait until the page title contains a string
# usage: wait_for_title_contains "Dashboard" [timeout_sec] [interval_sec]
wait_for_title_contains() {
  local text="$1"
  local timeout="${2:-10}"
  local interval="${3:-0.5}"
  local elapsed=0

  while _compare_lt "$elapsed" "$timeout"; do
    local title
    title=$(get_title 2>/dev/null)
    if printf '%s\n' "$title" | grep -qF -- "$text"; then
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  echo "[shellnium] Timeout: title did not contain '$text' after ${timeout}s" >&2
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
    if result=$("$@" 2>/dev/null) && [ -n "$result" ] && [ "$result" != "null" ]; then
      printf '%s\n' "$result"
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

##############################
# Assertions
##############################
# Check that an action had the intended effect. They print nothing and return
# 0 when the check holds; otherwise they explain the difference on stderr and
# return 1.

_assert_fail() {
  echo "[shellnium] Assertion failed: $1" >&2
  return 1
}

# usage: assert_url "https://example.com/dashboard"
assert_url() {
  local expected="$1"
  local actual
  actual=$(get_current_url) || return 1
  [ "$actual" = "$expected" ] || _assert_fail "URL is '$actual', expected '$expected'"
}

# usage: assert_url_contains "/dashboard"
assert_url_contains() {
  local expected="$1"
  local actual
  actual=$(get_current_url) || return 1
  case "$actual" in
    *"$expected"*) return 0 ;;
  esac
  _assert_fail "URL is '$actual', expected it to contain '$expected'"
}

# usage: assert_title "Dashboard"
assert_title() {
  local expected="$1"
  local actual
  actual=$(get_title) || return 1
  [ "$actual" = "$expected" ] || _assert_fail "title is '$actual', expected '$expected'"
}

# usage: assert_title_contains "Dash"
assert_title_contains() {
  local expected="$1"
  local actual
  actual=$(get_title) || return 1
  case "$actual" in
    *"$expected"*) return 0 ;;
  esac
  _assert_fail "title is '$actual', expected it to contain '$expected'"
}

# usage: assert_element_text "$element" "Success"
assert_element_text() {
  local elementId="$1"
  local expected="$2"
  local actual
  actual=$(get_text "$elementId") || return 1
  [ "$actual" = "$expected" ] || _assert_fail "element text is '$actual', expected '$expected'"
}

# usage: assert_element_text_contains "$element" "Succ"
assert_element_text_contains() {
  local elementId="$1"
  local expected="$2"
  local actual
  actual=$(get_text "$elementId") || return 1
  case "$actual" in
    *"$expected"*) return 0 ;;
  esac
  _assert_fail "element text is '$actual', expected it to contain '$expected'"
}

# usage: assert_element_exists 'css selector' '.success'
assert_element_exists() {
  local property="$1"
  local value="$2"
  local elements
  elements=$(find_elements "$property" "$value" 2>/dev/null)
  [ -n "$elements" ] || _assert_fail "no element matches ($property: $value)"
}

# usage: assert_element_not_exists 'css selector' '.error'
assert_element_not_exists() {
  local property="$1"
  local value="$2"
  local elements
  elements=$(find_elements "$property" "$value" 2>/dev/null)
  [ -z "$elements" ] || _assert_fail "an element matches ($property: $value)"
}
