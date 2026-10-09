#!/usr/bin/env bash

ROOT=${SHELLNIUM_DRIVER_URL:-http://localhost:9515}

# Logging goes to stderr, so that stdout only carries results.
# SHELLNIUM_LOG_LEVEL is one of debug, info, error (the default shows errors
# and info) or none. SHELLNIUM_DEBUG=true is the same as debug.
_log_enabled() {
  local level="${SHELLNIUM_LOG_LEVEL:-info}"
  if [ "${SHELLNIUM_DEBUG:-}" = "true" ]; then
    level="debug"
  fi
  case "$1" in
    debug) [ "$level" = "debug" ] ;;
    info)  [ "$level" = "debug" ] || [ "$level" = "info" ] ;;
    error) [ "$level" != "none" ] ;;
  esac
}

# Debug logging - enable with SHELLNIUM_DEBUG=true or SHELLNIUM_LOG_LEVEL=debug
_shellnium_log() {
  if _log_enabled debug; then
    echo "[shellnium] $*" >&2
  fi
}

_shellnium_error() {
  if _log_enabled error; then
    echo "[shellnium] $*" >&2
  fi
}

# With SHELLNIUM_OUTPUT=json every function prints one JSON object:
# {"ok":true,"value":...} on success (value is omitted when there is nothing
# to return) and {"ok":false,"error":"...","message":"..."} on failure. The
# exit code is the same as in the default plain output.
_json_mode() {
  [ "${SHELLNIUM_OUTPUT:-}" = "json" ]
}

# Run a function with plain output, whatever SHELLNIUM_OUTPUT says. For the
# functions that build on other functions.
_plain() {
  SHELLNIUM_OUTPUT='' "$@"
}

# Report success, with no value or with the given string as value.
_ok() {
  if _json_mode; then
    if [ $# -eq 0 ]; then
      echo '{"ok":true}'
    else
      jq -cn --arg value "$1" '{ok: true, value: $value}'
    fi
  elif [ $# -gt 0 ]; then
    printf '%s\n' "$1"
  fi
}

# Report a failure and return 1.
# usage: _fail "<error>" "<message>"
_fail() {
  _shellnium_error "$2"
  if _json_mode; then
    jq -cn --arg error "$1" --arg message "$2" '{ok: false, error: $error, message: $message}'
  fi
  return 1
}

# Check WebDriver error response and surface error messages to stderr.
# No response at all (the driver is not running, the session is gone) is an
# error too.
_check_error() {
  local response="$1"
  local error
  if [ -z "$response" ]; then
    _fail "no response" "Error: no response from the driver"
    return 1
  fi
  error=$(printf '%s\n' "$response" | jq -r '.value.error? // empty' 2>/dev/null)
  if [ -n "$error" ]; then
    local message
    message=$(printf '%s\n' "$response" | jq -r '.value.message? // empty' 2>/dev/null)
    _shellnium_error "Error: $error - $message"
    if _json_mode; then
      jq -cn --arg error "$error" --arg message "$message" '{ok: false, error: $error, message: $message}'
    fi
    return 1
  fi
  return 0
}

# Check the response of a command that returns nothing.
_done() {
  _check_error "$1" || return 1
  _ok
}

# Print the value of a response, or fail if it is a WebDriver error.
# usage: _value "$response" [jq filter]
_value() {
  local response="$1"
  local filter="${2:-.value}"
  _check_error "$response" || return 1
  if _json_mode; then
    printf '%s\n' "$response" | jq -c "{ok: true, value: (${filter})}"
  else
    printf '%s\n' "$response" | jq -r "$filter"
  fi
}

# Same for a response whose value is a list: one item per line, or the list
# itself in JSON mode.
_values() {
  local response="$1"
  _check_error "$response" || return 1
  if _json_mode; then
    printf '%s\n' "$response" | jq -c '{ok: true, value: .value}'
  else
    printf '%s\n' "$response" | jq -r '.value[]'
  fi
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

# Print the element(s) of a find-element response.
_emit_element() {
  if _json_mode; then
    printf '%s\n' "$1" | _element_id | jq -R '{ok: true, value: .}' | jq -c .
  else
    printf '%s\n' "$1" | _element_id
  fi
}

_emit_elements() {
  if _json_mode; then
    printf '%s\n' "$1" | jq -c --arg key "$W3C_ELEMENT_KEY" '{ok: true, value: [.value[] | (.[$key] // .ELEMENT)]}'
  else
    printf '%s\n' "$1" | _element_ids
  fi
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
  _value "$response" '.value.sessionId // .sessionId'
}

delete_session() {
  local response
  response=$(_DELETE "${BASE_URL}")
  _done "$response"
}

get_all_cookies() {
  local response
  response=$(_GET "${BASE_URL}/cookie")
  _values "$response"
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
  _done "$response"
}

delete_cookie() {
  local name=$1
  local response
  response=$(_DELETE "${BASE_URL}/cookie/${name}")
  _done "$response"
}

delete_all_cookies() {
  local response
  response=$(_DELETE "${BASE_URL}/cookie")
  _done "$response"
}

##############################
# Navigate
##############################

navigate_to() {
  local url=$1
  local payload response
  payload=$(jq -n --arg url "$url" '{url: $url}')
  response=$(_POST -d "$payload" "${BASE_URL}/url")
  _done "$response"
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
  _done "$response"
}

forward() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/forward")
  _done "$response"
}

refresh() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/refresh")
  _done "$response"
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
  _done "$response"
}

set_timeout_script() {
  local script=$1
  local response
  response=$(_POST -d "{\"script\": $script}" "${BASE_URL}/timeouts")
  _done "$response"
}

set_timeout_pageLoad() {
  local pageLoad=$1
  local response
  response=$(_POST -d "{\"pageLoad\": $pageLoad}" "${BASE_URL}/timeouts")
  _done "$response"
}

set_timeout_implicit() {
  local implicit=$1
  local response
  response=$(_POST -d "{\"implicit\": $implicit}" "${BASE_URL}/timeouts")
  _done "$response"
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
  _emit_element "$response"
}

find_elements() {
  local property=$1
  local value=$2
  local payload response
  payload=$(_locator "$property" "$value")
  response=$(_POST -d "$payload" "${BASE_URL}/elements")
  _check_error "$response" || return 1
  _emit_elements "$response"
}

find_element_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  local payload response
  payload=$(_locator "$property" "$value")
  response=$(_POST -d "$payload" "${BASE_URL}/element/${elementId}/element")
  _check_error "$response" || return 1
  _emit_element "$response"
}

find_elements_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  local payload response
  payload=$(_locator "$property" "$value")
  response=$(_POST -d "$payload" "${BASE_URL}/element/${elementId}/elements")
  _check_error "$response" || return 1
  _emit_elements "$response"
}

get_active_element() {
  local response
  response=$(_GET "${BASE_URL}/element/active")
  _check_error "$response" || return 1
  _emit_element "$response"
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
  _done "$response"
}

send_alert_text() {
  local value=$1
  local payload response
  payload=$(jq -n --arg value "$value" '{text: $value}')
  response=$(_POST -d "$payload" "${BASE_URL}/alert/text")
  _done "$response"
}

click() {
  local elementId=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/element/${elementId}/click")
  _done "$response"
}

element_clear() {
  local elementId=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/element/${elementId}/clear")
  _done "$response"
}

##############################
# Document
##############################

get_source() {
  local response
  response=$(_GET "${BASE_URL}/source")
  if _json_mode; then
    _value "$response"
  else
    _check_error "$response" || return 1
    printf '%s\n' "$response"
  fi
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
  if _json_mode; then
    _value "$response"
  else
    _check_error "$response" || return 1
    printf '%s\n' "$response"
  fi
}

element_screenshot() {
  local elementId=$1
  local file=${2:-./screenshot.png}
  local response
  response=$(_GET "${BASE_URL}/element/${elementId}/screenshot")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | jq -r '.value' | base64 -d > "$file"
  _ok
}

screenshot() {
  local file=${1:-./screenshot.png}
  local response
  response=$(_GET "${BASE_URL}/screenshot")
  _check_error "$response" || return 1
  printf '%s\n' "$response" | jq -r '.value' | base64 -d > "$file"
  _ok
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
  _values "$response"
}

delete_window() {
  local response
  response=$(_DELETE "${BASE_URL}/window")
  _done "$response"
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
  _done "$response"
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
    _done "$response"
    return
  fi

  # is element
  response=$(_POST -d "{\"id\":$(_element_ref "$id")}" "${BASE_URL}/frame")
  if _plain _check_error "$response" 2>/dev/null; then
    _ok
    return 0
  fi

  # is the id (or name) attribute of a frame
  local frame
  frame=$(_plain find_element 'css selector' "[id=\"$id\"],[name=\"$id\"]") || {
    _fail "no such frame" "Error: no such frame - $id"
    return 1
  }
  response=$(_POST -d "{\"id\":$(_element_ref "$frame")}" "${BASE_URL}/frame")
  _done "$response"
}

switch_to_parent_frame() {
  local response
  response=$(_POST -d '{}' "${BASE_URL}/frame/parent")
  _done "$response"
}

dismiss_alert() {
  local handle=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/alert/dismiss")
  _done "$response"
}

accept_alert() {
  local handle=$1
  local response
  response=$(_POST -d '{}' "${BASE_URL}/alert/accept")
  _done "$response"
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
  _done "$response"
}

# Release all actions
release_actions() {
  local response
  response=$(_DELETE "${BASE_URL}/actions")
  _done "$response"
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
    element=$(_plain find_element "$property" "$value" 2>/dev/null)
    if [ -n "$element" ] && [ "$element" != "null" ]; then
      _ok "$element"
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  _fail "timeout" "Timeout: element not found ($property: $value) after ${timeout}s"
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
    element=$(_plain find_element "$property" "$value" 2>/dev/null)
    if [ -n "$element" ] && [ "$element" != "null" ]; then
      local displayed
      local enabled
      displayed=$(_plain is_element_displayed "$element" 2>/dev/null)
      enabled=$(_plain is_element_enabled "$element" 2>/dev/null)
      if [ "$displayed" = "true" ] && [ "$enabled" = "true" ]; then
        _ok "$element"
        return 0
      fi
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  _fail "timeout" "Timeout: element not clickable ($property: $value) after ${timeout}s"
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
    source=$(_plain get_page_source 2>/dev/null)
    if printf '%s\n' "$source" | grep -q "$text"; then
      _ok
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  _fail "timeout" "Timeout: text not found ('$text') after ${timeout}s"
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
    url=$(_plain get_current_url 2>/dev/null)
    if printf '%s\n' "$url" | grep -q "$pattern"; then
      _ok
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  _fail "timeout" "Timeout: URL did not match ('$pattern') after ${timeout}s"
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
    url=$(_plain get_current_url 2>/dev/null)
    if printf '%s\n' "$url" | grep -qF -- "$text"; then
      _ok
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  _fail "timeout" "Timeout: URL did not contain '$text' after ${timeout}s"
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
    title=$(_plain get_title 2>/dev/null)
    if printf '%s\n' "$title" | grep -qF -- "$text"; then
      _ok
      return 0
    fi
    sleep "$interval"
    elapsed=$(_add "$elapsed" "$interval")
  done

  _fail "timeout" "Timeout: title did not contain '$text' after ${timeout}s"
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

# usage: _assert_equals "<what>" "<actual>" "<expected>"
_assert_equals() {
  if [ "$2" = "$3" ]; then
    _ok
  else
    _fail "assertion failed" "Assertion failed: $1 is '$2', expected '$3'"
  fi
}

# usage: _assert_contains "<what>" "<actual>" "<expected part>"
_assert_contains() {
  case "$2" in
    *"$3"*) _ok ;;
    *) _fail "assertion failed" "Assertion failed: $1 is '$2', expected it to contain '$3'" ;;
  esac
}

# usage: assert_url "https://example.com/dashboard"
assert_url() {
  local actual
  actual=$(_plain get_current_url) || { _fail "assertion failed" "Assertion failed: could not read the URL"; return 1; }
  _assert_equals "URL" "$actual" "$1"
}

# usage: assert_url_contains "/dashboard"
assert_url_contains() {
  local actual
  actual=$(_plain get_current_url) || { _fail "assertion failed" "Assertion failed: could not read the URL"; return 1; }
  _assert_contains "URL" "$actual" "$1"
}

# usage: assert_title "Dashboard"
assert_title() {
  local actual
  actual=$(_plain get_title) || { _fail "assertion failed" "Assertion failed: could not read the title"; return 1; }
  _assert_equals "title" "$actual" "$1"
}

# usage: assert_title_contains "Dash"
assert_title_contains() {
  local actual
  actual=$(_plain get_title) || { _fail "assertion failed" "Assertion failed: could not read the title"; return 1; }
  _assert_contains "title" "$actual" "$1"
}

# usage: assert_element_text "$element" "Success"
assert_element_text() {
  local actual
  actual=$(_plain get_text "$1") || { _fail "assertion failed" "Assertion failed: could not read the element text"; return 1; }
  _assert_equals "element text" "$actual" "$2"
}

# usage: assert_element_text_contains "$element" "Succ"
assert_element_text_contains() {
  local actual
  actual=$(_plain get_text "$1") || { _fail "assertion failed" "Assertion failed: could not read the element text"; return 1; }
  _assert_contains "element text" "$actual" "$2"
}

# usage: assert_element_exists 'css selector' '.success'
assert_element_exists() {
  local elements
  elements=$(_plain find_elements "$1" "$2" 2>/dev/null)
  if [ -n "$elements" ]; then
    _ok
  else
    _fail "assertion failed" "Assertion failed: no element matches ($1: $2)"
  fi
}

# usage: assert_element_not_exists 'css selector' '.error'
assert_element_not_exists() {
  local elements
  elements=$(_plain find_elements "$1" "$2" 2>/dev/null)
  if [ -z "$elements" ]; then
    _ok
  else
    _fail "assertion failed" "Assertion failed: an element matches ($1: $2)"
  fi
}

##############################
# Page Introspection
##############################
# Discover what is on a page without knowing its selectors beforehand. Every
# function prints JSON, and every element comes with a "selector" that can be
# handed to find_element 'css selector'.

# Helpers shared by the introspection scripts.
_INTROSPECTION_HELPERS='
function clean(text) { return (text || "").replace(/\s+/g, " ").trim(); }
function visible(e) {
  var r = e.getBoundingClientRect(), c = getComputedStyle(e);
  return r.width > 0 && r.height > 0 && c.visibility !== "hidden" && c.display !== "none";
}
function hasUniqueId(e) {
  return e.id && document.querySelectorAll("#" + CSS.escape(e.id)).length === 1;
}
function selector(e) {
  var parts = [];
  while (e && e.nodeType === 1 && e !== document.documentElement) {
    if (hasUniqueId(e)) { parts.unshift("#" + CSS.escape(e.id)); break; }
    var n = 1, s = e;
    while ((s = s.previousElementSibling)) { if (s.tagName === e.tagName) { n++; } }
    parts.unshift(e.tagName.toLowerCase() + ":nth-of-type(" + n + ")");
    e = e.parentElement;
  }
  return parts.join(" > ");
}
function label(e) {
  if (e.labels && e.labels.length) { return clean(e.labels[0].innerText); }
  return clean(e.getAttribute("aria-label") || e.title || "");
}
function compact(o) {
  Object.keys(o).forEach(function (k) { if (o[k] === "" || o[k] === null || o[k] === undefined) { delete o[k]; } });
  return o;
}
'

# Run a script and print its result as compact JSON.
# usage: _exec_json "$script" [json array of arguments]
_exec_json() {
  local payload response
  payload=$(jq -n --arg script "$1" --argjson args "${2:-[]}" '{script: $script, args: $args}')
  response=$(_POST -d "$payload" "${BASE_URL}/execute/sync")
  if _json_mode; then
    _value "$response"
  else
    _check_error "$response" || return 1
    printf '%s\n' "$response" | jq -c '.value'
  fi
}

# Visible elements a user could click: links, buttons and the like.
# usage: get_clickable_elements [max_elements]
get_clickable_elements() {
  _exec_json "${_INTROSPECTION_HELPERS}"'
    var max = arguments[0];
    var found = document.querySelectorAll("a[href], area[href], button, summary, input[type=submit], input[type=button], input[type=reset], input[type=image], [role=button], [role=link], [onclick]");
    var out = [];
    for (var i = 0; i < found.length && out.length < max; i++) {
      var e = found[i];
      if (!visible(e) || e.disabled) { continue; }
      out.push(compact({
        tag: e.tagName.toLowerCase(),
        text: clean(e.innerText || e.value || e.getAttribute("aria-label") || e.title || e.alt).slice(0, 120),
        id: e.id,
        name: e.getAttribute("name"),
        type: e.getAttribute("type"),
        href: e.href && typeof e.href === "string" ? e.href : null,
        selector: selector(e)
      }));
    }
    return out;' "[${1:-200}]"
}

# Fields of the forms on the page. Passwords are never included.
# usage: get_form_fields
get_form_fields() {
  _exec_json "${_INTROSPECTION_HELPERS}"'
    var found = document.querySelectorAll("input, select, textarea");
    var skipped = ["hidden", "submit", "button", "reset", "image"];
    var out = [];
    for (var i = 0; i < found.length; i++) {
      var e = found[i], tag = e.tagName.toLowerCase();
      var type = tag === "input" ? (e.getAttribute("type") || "text").toLowerCase() : tag;
      if (skipped.indexOf(type) >= 0) { continue; }
      var field = {
        tag: tag,
        type: type,
        name: e.getAttribute("name"),
        id: e.id,
        label: label(e),
        placeholder: e.getAttribute("placeholder"),
        value: type === "password" || type === "checkbox" || type === "radio" ? null : e.value,
        selector: selector(e)
      };
      if (type === "checkbox" || type === "radio") { field.checked = e.checked; field.option = e.value; }
      if (tag === "select") {
        field.options = Array.prototype.map.call(e.options, function (o) {
          return compact({value: o.value, text: clean(o.text), selected: o.selected || null});
        });
      }
      if (e.required) { field.required = true; }
      if (e.disabled) { field.disabled = true; }
      if (!visible(e)) { field.visible = false; }
      out.push(compact(field));
    }
    return out;'
}

# Overview of the page: title, URL, headings, the beginning of its text and
# its links.
# usage: get_page_summary [max_text_chars] [max_links]
get_page_summary() {
  _exec_json "${_INTROSPECTION_HELPERS}"'
    var maxText = arguments[0], maxLinks = arguments[1];
    var headings = [], links = [];
    var hs = document.querySelectorAll("h1, h2, h3");
    for (var i = 0; i < hs.length && headings.length < 30; i++) {
      if (visible(hs[i]) && clean(hs[i].innerText)) {
        headings.push({level: Number(hs[i].tagName.charAt(1)), text: clean(hs[i].innerText).slice(0, 120)});
      }
    }
    var as = document.querySelectorAll("a[href]");
    for (var j = 0; j < as.length && links.length < maxLinks; j++) {
      if (visible(as[j]) && clean(as[j].innerText)) {
        links.push({text: clean(as[j].innerText).slice(0, 80), href: as[j].href, selector: selector(as[j])});
      }
    }
    var text = clean(document.body ? document.body.innerText : "");
    return {
      title: document.title,
      url: location.href,
      headings: headings,
      text: text.slice(0, maxText),
      textTruncated: text.length > maxText,
      links: links,
      linksTotal: as.length,
      forms: document.forms.length,
      fields: document.querySelectorAll("input:not([type=hidden]), select, textarea").length
    };' "[${1:-2000}, ${2:-50}]"
}

# Everything about one element: tag, text, attributes, state and position.
# usage: get_element_info "$element"
get_element_info() {
  _exec_json "${_INTROSPECTION_HELPERS}"'
    var e = arguments[0], attributes = {}, r = e.getBoundingClientRect();
    for (var i = 0; i < e.attributes.length; i++) {
      attributes[e.attributes[i].name] = e.attributes[i].value;
    }
    if (e.type === "password") { delete attributes.value; }
    return compact({
      tag: e.tagName.toLowerCase(),
      text: clean(e.innerText).slice(0, 500),
      value: e.type === "password" || typeof e.value !== "string" ? null : e.value,
      attributes: attributes,
      displayed: visible(e),
      enabled: !e.disabled,
      checked: typeof e.checked === "boolean" ? e.checked : null,
      rect: {x: Math.round(r.x), y: Math.round(r.y), width: Math.round(r.width), height: Math.round(r.height)},
      children: e.children.length,
      selector: selector(e)
    });' "[$(_element_ref "$1")]"
}
