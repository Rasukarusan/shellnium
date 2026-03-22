#!/usr/bin/env bash

ROOT=${SHELLNIUM_DRIVER_URL:-http://localhost:9515}

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
  _POST -d '{"url":"'"${url}"'"}' "${BASE_URL}/url" >/dev/null
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
  _POST -d "{\"using\":\"$property\", \"value\": \"$value\"}" "${BASE_URL}/element" | jq -r '.value.ELEMENT'
}

find_elements() {
  local property=$1
  local value=$2
  _POST -d "{\"using\":\"$property\", \"value\": \"$value\"}" "${BASE_URL}/elements" | jq -r '.value[].ELEMENT'
}

find_element_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  _POST -d "{\"using\":\"$property\", \"value\": \"$value\"}" "${BASE_URL}/element/${elementId}/element" | jq -r '.value.ELEMENT'
}

find_elements_from_element() {
  local elementId=$1
  local property=$2
  local value=$3
  _POST -d "{\"using\":\"$property\", \"value\": \"$value\"}" "${BASE_URL}/element/${elementId}/elements" | jq -r '.value[].ELEMENT'
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
  _POST -d "{\"value\": [\"${value}\"]}" "${BASE_URL}/element/${elementId}/value" >/dev/null
}

send_alert_text() {
  local value=$1
  _POST -d "{\"value\": [\"${value}\"]}" "${BASE_URL}/alert/text" >/dev/null
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
