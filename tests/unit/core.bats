#!/usr/bin/env bats

setup() {
  load '../test_helper'

  # Track curl calls instead of executing them
  CURL_LOG="${BATS_TEST_TMPDIR}/curl_calls.log"
  > "$CURL_LOG"

  # Mock curl to log calls and return valid JSON
  curl() {
    echo "$@" >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "mock-element-id"}, "sessionId": "mock-session-id"}'
  }
  export -f curl
}

teardown() {
  unset -f curl 2>/dev/null || true
}

# =====================
# HTTP method tests
# =====================

@test "_GET sends GET request to the given URL" {
  _GET "http://example.com/test"
  run cat "$CURL_LOG"
  [[ "$output" == *"-X GET"* ]]
  [[ "$output" == *"http://example.com/test"* ]]
}

@test "_POST sends POST request with Content-Type header" {
  _POST -d '{"key":"value"}' "http://example.com/test"
  run cat "$CURL_LOG"
  [[ "$output" == *"-X POST"* ]]
  [[ "$output" == *"Content-Type: application/json"* ]]
  [[ "$output" == *"http://example.com/test"* ]]
}

@test "_DELETE sends DELETE request to the given URL" {
  _DELETE "http://example.com/test"
  run cat "$CURL_LOG"
  [[ "$output" == *"-X DELETE"* ]]
  [[ "$output" == *"http://example.com/test"* ]]
}

# =====================
# find_element tests
# =====================

@test "find_element builds correct JSON payload with css selector" {
  # Override curl to capture -d argument
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-123"}}'
  }
  export -f curl

  find_element 'css selector' '.my-class'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "css selector"'* ]]
  [[ "$output" == *'"value": ".my-class"'* ]]
}

@test "find_element builds correct JSON payload with xpath" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-456"}}'
  }
  export -f curl

  find_element 'xpath' '//div[@id="main"]'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "xpath"'* ]]
  [[ "$output" == *'//div[@id='* ]]
  [[ "$output" == *'main'* ]]
}

@test "find_element expresses the id strategy as a css selector" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-789"}}'
  }
  export -f curl

  find_element 'id' 'my-element'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "css selector"'* ]]
  [[ "$output" == *'"value": "[id=\"my-element\"]"'* ]]
}

@test "find_element expresses the name strategy as a css selector" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-name"}}'
  }
  export -f curl

  find_element 'name' 'username'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "css selector"'* ]]
  [[ "$output" == *'"value": "[name=\"username\"]"'* ]]
}

@test "find_element builds correct JSON payload with tag name" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-tag"}}'
  }
  export -f curl

  find_element 'tag name' 'input'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "tag name"'* ]]
  [[ "$output" == *'"value": "input"'* ]]
}

@test "find_element builds correct JSON payload with link text" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-link"}}'
  }
  export -f curl

  find_element 'link text' 'Click Here'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "link text"'* ]]
  [[ "$output" == *'"value": "Click Here"'* ]]
}

@test "find_element builds correct JSON payload with partial link text" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-partial"}}'
  }
  export -f curl

  find_element 'partial link text' 'Click'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "partial link text"'* ]]
  [[ "$output" == *'"value": "Click"'* ]]
}

@test "find_element posts to correct endpoint" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-url"}}'
  }
  export -f curl

  find_element 'id' 'test'
  run cat "$CURL_LOG"
  [[ "$output" == *"${BASE_URL}/element"* ]]
}

# =====================
# find_elements tests
# =====================

@test "find_elements posts to /elements endpoint" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": [{"ELEMENT": "e1"}, {"ELEMENT": "e2"}]}'
  }
  export -f curl

  find_elements 'css selector' 'div'
  run cat "$CURL_LOG"
  [[ "$output" == *"${BASE_URL}/elements"* ]]
}

# =====================
# find_element_from_element tests
# =====================

@test "find_element_from_element posts to correct endpoint with parent element" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "child-elem"}}'
  }
  export -f curl

  find_element_from_element 'parent-id' 'css selector' '.child'
  run cat "$CURL_LOG"
  [[ "$output" == *"${BASE_URL}/element/parent-id/element"* ]]
  [[ "$output" == *'"using": "css selector"'* ]]
  [[ "$output" == *'"value": ".child"'* ]]
}

# =====================
# exec_script JSON escaping tests
# =====================

@test "exec_script properly escapes double quotes in JavaScript" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": null}'
  }
  export -f curl

  exec_script 'return document.querySelector("div")'
  run cat "$CURL_LOG"
  # The script should be JSON-escaped (jq -Rs wraps it)
  [[ "$output" == *'"script":'* ]]
  [[ "$output" == *'"args":'* ]]
}

@test "exec_script handles newlines in JavaScript" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": null}'
  }
  export -f curl

  exec_script $'var x = 1;\nreturn x;'
  run cat "$CURL_LOG"
  [[ "$output" == *'"script":'* ]]
}

@test "exec_script passes arguments when provided" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": null}'
  }
  export -f curl

  exec_script 'return arguments[0]' 'hello'
  run cat "$CURL_LOG"
  [[ "$output" == *'"args": ["hello"]'* ]]
}

@test "exec_script uses empty args array when no argument given" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": null}'
  }
  export -f curl

  exec_script 'return 1'
  run cat "$CURL_LOG"
  [[ "$output" == *'"args": []'* ]]
}

# =====================
# navigate_to tests
# =====================

@test "navigate_to sends correct URL in payload" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  navigate_to 'https://example.com'
  run cat "$CURL_LOG"
  [[ "$output" == *'"url": "https://example.com"'* ]]
  [[ "$output" == *"${BASE_URL}/url"* ]]
}

# =====================
# send_keys tests
# =====================

@test "send_keys sends correct payload to element endpoint" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  send_keys 'elem-123' 'hello world'
  run cat "$CURL_LOG"
  [[ "$output" == *'"hello world"'* ]]
  [[ "$output" == *"${BASE_URL}/element/elem-123/value"* ]]
}

# =====================
# ROOT variable tests
# =====================

@test "ROOT defaults to http://localhost:9515 when SHELLNIUM_DRIVER_URL is not set" {
  unset SHELLNIUM_DRIVER_URL
  source "${SHELLNIUM_DIR}/lib/core.sh"
  [[ "$ROOT" == "http://localhost:9515" ]]
}

@test "ROOT uses SHELLNIUM_DRIVER_URL when set" {
  export SHELLNIUM_DRIVER_URL="http://custom:1234"
  source "${SHELLNIUM_DIR}/lib/core.sh"
  [[ "$ROOT" == "http://custom:1234" ]]
  unset SHELLNIUM_DRIVER_URL
}

# new_session binary clause tests
# =====================

@test "new_session includes binary field when SHELLNIUM_CHROME_BIN is set" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"sessionId": "test-session"}'
  }
  export -f curl

  SHELLNIUM_CHROME_BIN="/tmp/chrome-headless-shell"
  new_session
  run cat "$CURL_LOG"
  [[ "$output" == *'"binary": "/tmp/chrome-headless-shell"'* ]]
  unset SHELLNIUM_CHROME_BIN
}

@test "new_session omits binary field when SHELLNIUM_CHROME_BIN is empty" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"sessionId": "test-session"}'
  }
  export -f curl

  SHELLNIUM_CHROME_BIN=""
  new_session
  run cat "$CURL_LOG"
  [[ "$output" != *'"binary"'* ]]
}

# =====================
# Actions API tests
# =====================

@test "perform_actions sends POST to /actions endpoint" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  perform_actions '{"actions":[{"type":"key","id":"kb","actions":[]}]}'
  run cat "$CURL_LOG"
  [[ "$output" == *"POST"* ]]
  [[ "$output" == *"${BASE_URL}/actions"* ]]
}

@test "release_actions sends DELETE to /actions endpoint" {
  release_actions
  run cat "$CURL_LOG"
  [[ "$output" == *"-X DELETE"* ]]
  [[ "$output" == *"${BASE_URL}/actions"* ]]
}

@test "mouse_move_to sends pointerMove action with element origin" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  mouse_move_to 'elem-abc'
  run cat "$CURL_LOG"
  [[ "$output" == *'"type":"pointer"'* ]]
  [[ "$output" == *'"pointerType":"mouse"'* ]]
  [[ "$output" == *'"type":"pointerMove"'* ]]
  [[ "$output" == *'"ELEMENT":"elem-abc"'* ]]
}

@test "double_click sends two pointerDown/pointerUp pairs" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  double_click 'elem-dbl'
  run cat "$CURL_LOG"
  [[ "$output" == *'"ELEMENT":"elem-dbl"'* ]]
  # Two pointerDown actions (button 0)
  [[ "$output" == *'"type":"pointerDown","button":0'* ]]
  [[ "$output" == *'"type":"pointerUp","button":0'* ]]
}

@test "right_click sends pointerDown/pointerUp with button 2" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  right_click 'elem-rc'
  run cat "$CURL_LOG"
  [[ "$output" == *'"ELEMENT":"elem-rc"'* ]]
  [[ "$output" == *'"type":"pointerDown","button":2'* ]]
  [[ "$output" == *'"type":"pointerUp","button":2'* ]]
}

@test "hover delegates to mouse_move_to" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  hover 'elem-hover'
  run cat "$CURL_LOG"
  [[ "$output" == *'"type":"pointerMove"'* ]]
  [[ "$output" == *'"ELEMENT":"elem-hover"'* ]]
}

@test "drag_and_drop sends pointerMove, pointerDown, pointerMove, pointerUp" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  drag_and_drop 'src-elem' 'tgt-elem'
  run cat "$CURL_LOG"
  [[ "$output" == *'"ELEMENT":"src-elem"'* ]]
  [[ "$output" == *'"ELEMENT":"tgt-elem"'* ]]
  [[ "$output" == *'"type":"pointerDown","button":0'* ]]
  [[ "$output" == *'"type":"pointerUp","button":0'* ]]
}

@test "key_press sends keyDown followed by keyUp" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  key_press 'a'
  run cat "$CURL_LOG"
  [[ "$output" == *'"type":"key"'* ]]
  [[ "$output" == *'"type":"keyDown","value":"a"'* ]]
  [[ "$output" == *'"type":"keyUp","value":"a"'* ]]
}

@test "key_down sends only keyDown action" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  key_down 'b'
  run cat "$CURL_LOG"
  [[ "$output" == *'"type":"keyDown","value":"b"'* ]]
  # Should NOT contain keyUp
  [[ "$output" != *'"type":"keyUp"'* ]]
}

@test "key_up sends only keyUp action" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  key_up 'c'
  run cat "$CURL_LOG"
  [[ "$output" == *'"type":"keyUp","value":"c"'* ]]
  # Should NOT contain keyDown
  [[ "$output" != *'"type":"keyDown"'* ]]
}

@test "send_key_combo sends modifier keyDown, key keyDown, key keyUp, modifier keyUp" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{}'
  }
  export -f curl

  send_key_combo "$KEY_CONTROL" 'a'
  run cat "$CURL_LOG"
  [[ "$output" == *'"type":"key"'* ]]
  [[ "$output" == *"keyDown"* ]]
  [[ "$output" == *"keyUp"* ]]
}

# =====================
# Key constants tests
# =====================

@test "KEY_ENTER has correct W3C value (U+E007)" {
  [[ "$KEY_ENTER" == "$(printf '\xee\x80\x87')" ]]
}

@test "KEY_TAB has correct W3C value (U+E004)" {
  [[ "$KEY_TAB" == "$(printf '\xee\x80\x84')" ]]
}

@test "KEY_ESCAPE has correct W3C value (U+E00C)" {
  [[ "$KEY_ESCAPE" == "$(printf '\xee\x80\x8c')" ]]
}

@test "KEY_BACKSPACE has correct W3C value (U+E003)" {
  [[ "$KEY_BACKSPACE" == "$(printf '\xee\x80\x83')" ]]
}

@test "KEY_CONTROL has correct W3C value (U+E009)" {
  [[ "$KEY_CONTROL" == "$(printf '\xee\x80\x89')" ]]
}

@test "KEY_SHIFT has correct W3C value (U+E008)" {
  [[ "$KEY_SHIFT" == "$(printf '\xee\x80\x88')" ]]
}

@test "KEY_ALT has correct W3C value (U+E00A)" {
  [[ "$KEY_ALT" == "$(printf '\xee\x80\x8a')" ]]
}

@test "KEY_META has correct W3C value (U+E03D)" {
  [[ "$KEY_META" == "$(printf '\xee\x80\xbd')" ]]
}

@test "KEY_ARROW_DOWN has correct W3C value (U+E015)" {
  [[ "$KEY_ARROW_DOWN" == "$(printf '\xee\x80\x95')" ]]
}

@test "KEY_F1 has correct W3C value (U+E031)" {
  [[ "$KEY_F1" == "$(printf '\xee\x80\xb1')" ]]
}

@test "KEY_F12 has correct W3C value (U+E03C)" {
  [[ "$KEY_F12" == "$(printf '\xee\x80\xbc')" ]]
}

# =====================
# Wait helpers
# =====================

@test "_compare_lt compares decimal numbers" {
  _compare_lt 0.4 1
  _compare_lt 0.2 0.5
  ! _compare_lt 1 1
  ! _compare_lt 1.2 1
}

@test "_add adds decimal numbers" {
  [ "$(_add 0 0.2)" = "0.2" ]
  [ "$(_add 0.8 0.2)" = "1" ]
  [ "$(_add 9.5 0.5)" = "10" ]
}

@test "wait_for_element times out with an interval below one second" {
  find_element() { return 1; }
  sleep() { echo "slept" >> "${BATS_TEST_TMPDIR}/sleeps.log"; }

  run wait_for_element 'id' 'never' 1 0.25
  [ "$status" -eq 1 ]
  [[ "$output" == *"Timeout"* ]]
  [ "$(wc -l < "${BATS_TEST_TMPDIR}/sleeps.log")" -eq 4 ]
}

# =====================
# zsh compatibility
# =====================

@test "responses with backslashes survive under zsh" {
  command -v zsh >/dev/null 2>&1 || skip "zsh is not installed"

  run zsh -c '
    source "$1/lib/core.sh"
    BASE_URL="http://localhost:9515/session/test"
    curl() { printf "%s" "{\"value\":\"line1\\nline2 \\\\ end\"}"; }
    get_page_source
  ' zsh "$SHELLNIUM_DIR"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "line1" ]
  [ "${lines[1]}" = 'line2 \ end' ]
}

@test "screenshot does not clobber PATH under zsh" {
  command -v zsh >/dev/null 2>&1 || skip "zsh is not installed"

  run zsh -c '
    source "$1/lib/core.sh"
    BASE_URL="http://localhost:9515/session/test"
    curl() { printf "%s" "{\"value\":\"aGVsbG8=\"}"; }
    screenshot "$2/shot.png" && element_screenshot elem "$2/element.png"
    cat "$2/shot.png" "$2/element.png"
  ' zsh "$SHELLNIUM_DIR" "$BATS_TEST_TMPDIR"
  [ "$status" -eq 0 ]
  [ "$output" = "hellohello" ]
}

# =====================
# W3C protocol
# =====================

# Log every curl argument on its own line and answer with $MOCK_RESPONSE.
_mock_curl() {
  export MOCK_RESPONSE="$1"
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo "$MOCK_RESPONSE"
  }
  export -f curl
}

@test "find_element expresses the class name strategy as a css selector" {
  _mock_curl '{"value": {"ELEMENT": "elem-class"}}'

  find_element 'class name' 'btn-primary'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "css selector"'* ]]
  [[ "$output" == *'"value": ".btn-primary"'* ]]
}

@test "_locator escapes quotes and backslashes in id values" {
  run _locator 'id' 'a"b\c'
  [ "$(echo "$output" | jq -r '.value')" = '[id="a\"b\\c"]' ]
}

@test "_locator leaves W3C strategies untouched" {
  run _locator 'xpath' '//div[@id="x"]'
  [ "$(echo "$output" | jq -r '.using')" = 'xpath' ]
  [ "$(echo "$output" | jq -r '.value')" = '//div[@id="x"]' ]
}

@test "find_element reads the id from a W3C element reference" {
  _mock_curl '{"value": {"element-6066-11e4-a52e-4f735466cecf": "w3c-elem"}}'

  run find_element 'css selector' 'h1'
  [ "$status" -eq 0 ]
  [ "$output" = "w3c-elem" ]
}

@test "find_element still reads the id from a legacy ELEMENT reference" {
  _mock_curl '{"value": {"ELEMENT": "legacy-elem"}}'

  run find_element 'css selector' 'h1'
  [ "$status" -eq 0 ]
  [ "$output" = "legacy-elem" ]
}

@test "find_elements reads every id from W3C element references" {
  _mock_curl '{"value": [{"element-6066-11e4-a52e-4f735466cecf": "a"}, {"element-6066-11e4-a52e-4f735466cecf": "b"}]}'

  run find_elements 'css selector' 'li'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "a" ]
  [ "${lines[1]}" = "b" ]
}

@test "find_element fails on a W3C error response" {
  _mock_curl '{"value": {"error": "no such element", "message": "Unable to locate element"}}'

  run find_element 'css selector' '.missing'
  [ "$status" -eq 1 ]
  [[ "$output" == *"no such element"* ]]
}

@test "get_active_element reads the id from a W3C element reference" {
  _mock_curl '{"value": {"element-6066-11e4-a52e-4f735466cecf": "active-elem"}}'

  run get_active_element
  [ "$output" = "active-elem" ]
}

@test "new_session sends W3C capabilities" {
  _mock_curl '{"value": {"sessionId": "w3c-session", "capabilities": {}}}'

  new_session
  run cat "$CURL_LOG"
  [[ "$output" == *'"capabilities"'* ]]
  [[ "$output" == *'"alwaysMatch"'* ]]
  [[ "$output" == *'"goog:chromeOptions"'* ]]
  [[ "$output" != *'"desiredCapabilities"'* ]]
}

@test "new_session reads the session id from a W3C response" {
  _mock_curl '{"value": {"sessionId": "w3c-session", "capabilities": {}}}'

  run new_session
  [ "$status" -eq 0 ]
  [ "$output" = "w3c-session" ]
}

@test "new_session still reads the session id from a legacy response" {
  _mock_curl '{"sessionId": "legacy-session", "status": 0, "value": {}}'

  run new_session
  [ "$status" -eq 0 ]
  [ "$output" = "legacy-session" ]
}

@test "new_session fails when the driver refuses the session" {
  _mock_curl '{"value": {"error": "session not created", "message": "no chrome binary"}}'

  run new_session
  [ "$status" -eq 1 ]
  [[ "$output" == *"session not created"* ]]
}

@test "new_session passes extra arguments and the headless flag to the browser" {
  _mock_curl '{"value": {"sessionId": "s"}}'

  SHELLNIUM_HEADLESS=true new_session --lang=es
  run cat "$CURL_LOG"
  [[ "$output" == *'"--lang=es"'* ]]
  [[ "$output" == *'"--headless=new"'* ]]
}

@test "send_keys sends the text field required by W3C" {
  _mock_curl '{"value": null}'

  send_keys 'elem-1' 'hello'
  run cat "$CURL_LOG"
  [[ "$output" == *'"text": "hello"'* ]]
  [[ "$output" == *'/element/elem-1/value'* ]]
}

@test "send_alert_text sends the text field required by W3C" {
  _mock_curl '{"value": null}'

  send_alert_text 'hello'
  run cat "$CURL_LOG"
  [[ "$output" == *'"text": "hello"'* ]]
  [[ "$output" == *'/alert/text'* ]]
}

@test "click sends an empty JSON object as body" {
  _mock_curl '{"value": null}'

  click 'elem-1'
  run cat "$CURL_LOG"
  [[ "$output" == *'{}'* ]]
  [[ "$output" == *'/element/elem-1/click'* ]]
}

@test "switch_to_window sends the W3C handle field" {
  _mock_curl '{"value": null}'

  switch_to_window 'window-1'
  run cat "$CURL_LOG"
  [[ "$output" == *'"handle":"window-1"'* ]]
}

@test "switch_to_frame sends an integer as a frame index" {
  _mock_curl '{"value": null}'

  switch_to_frame 2
  run cat "$CURL_LOG"
  [[ "$output" == *'{"id":2}'* ]]
}

@test "switch_to_frame sends an element as a W3C element reference" {
  _mock_curl '{"value": null}'

  switch_to_frame 'frame-elem'
  run cat "$CURL_LOG"
  [[ "$output" == *'"element-6066-11e4-a52e-4f735466cecf":"frame-elem"'* ]]
  [[ "$output" == *'/frame'* ]]
}

@test "switch_to_frame falls back to the frame id or name attribute" {
  # Switching to "my-frame" as an element reference fails, so the frame is
  # looked up by its id/name attribute and switched to as an element.
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    if [[ "$*" == *'/element'* ]]; then
      echo '{"value": {"element-6066-11e4-a52e-4f735466cecf": "found-frame"}}'
    elif [[ "$*" == *'"my-frame"'* ]]; then
      echo '{"value": {"error": "no such element", "message": "bad element"}}'
    else
      echo '{"value": null}'
    fi
  }
  export -f curl

  run switch_to_frame 'my-frame'
  [ "$status" -eq 0 ]
  run cat "$CURL_LOG"
  [[ "$output" == *'[id=\"my-frame\"],[name=\"my-frame\"]'* ]]
  [[ "$output" == *'"element-6066-11e4-a52e-4f735466cecf":"found-frame"'* ]]
}

@test "mouse_move_to uses a W3C element reference as origin" {
  _mock_curl '{"value": null}'

  mouse_move_to 'elem-abc'
  run cat "$CURL_LOG"
  [[ "$output" == *'"element-6066-11e4-a52e-4f735466cecf":"elem-abc"'* ]]
}

@test "get_attribute asks the browser for the live value of the attribute" {
  _mock_curl '{"value": "typed text"}'

  run get_attribute 'elem-1' 'value'
  [ "$output" = "typed text" ]
  run cat "$CURL_LOG"
  [[ "$output" == *'/execute/sync'* ]]
  [[ "$output" == *'"element-6066-11e4-a52e-4f735466cecf": "elem-1"'* ]]
  [[ "$output" == *'"value"'* ]]
}

@test "get_dom_attribute uses the W3C attribute endpoint" {
  _mock_curl '{"value": "initial"}'

  run get_dom_attribute 'elem-1' 'value'
  [ "$output" = "initial" ]
  run cat "$CURL_LOG"
  [[ "$output" == *'/element/elem-1/attribute/value'* ]]
}

# =====================
# Browser selection
# =====================

@test "new_session asks for chrome by default" {
  _mock_curl '{"value": {"sessionId": "s"}}'

  unset SHELLNIUM_BROWSER
  new_session
  run cat "$CURL_LOG"
  [[ "$output" == *'"browserName": "chrome"'* ]]
  [[ "$output" != *'moz:firefoxOptions'* ]]
}

@test "new_session asks for firefox when SHELLNIUM_BROWSER=firefox" {
  _mock_curl '{"value": {"sessionId": "s"}}'

  SHELLNIUM_BROWSER=firefox new_session
  run cat "$CURL_LOG"
  [[ "$output" == *'"browserName": "firefox"'* ]]
  [[ "$output" == *'"moz:firefoxOptions"'* ]]
  [[ "$output" != *'goog:chromeOptions'* ]]
}

@test "_firefox_capabilities adds -headless when SHELLNIUM_HEADLESS is enabled" {
  SHELLNIUM_HEADLESS=true run _firefox_capabilities
  [ "$(echo "$output" | jq -r '.capabilities.alwaysMatch["moz:firefoxOptions"].args | index("-headless") != null')" = "true" ]

  SHELLNIUM_HEADLESS="" run _firefox_capabilities
  [ "$(echo "$output" | jq -r '.capabilities.alwaysMatch["moz:firefoxOptions"].args | index("-headless") != null')" = "false" ]
}

@test "_firefox_capabilities puts user arguments before the defaults" {
  run _firefox_capabilities -width 800
  [ "$(echo "$output" | jq -c '.capabilities.alwaysMatch["moz:firefoxOptions"].args[0:2]')" = '["-width","800"]' ]
}

@test "_firefox_capabilities includes binary only when SHELLNIUM_FIREFOX_BIN is set" {
  SHELLNIUM_FIREFOX_BIN="/opt/firefox/firefox" run _firefox_capabilities
  [ "$(echo "$output" | jq -r '.capabilities.alwaysMatch["moz:firefoxOptions"].binary')" = "/opt/firefox/firefox" ]

  SHELLNIUM_FIREFOX_BIN="" run _firefox_capabilities
  [ "$(echo "$output" | jq -r '.capabilities.alwaysMatch["moz:firefoxOptions"] | has("binary")')" = "false" ]
}

@test "_chrome_capabilities keeps arguments with spaces and quotes intact" {
  run _chrome_capabilities '--user-agent=My "quoted" agent'
  [ "$(echo "$output" | jq -r '.capabilities.alwaysMatch["goog:chromeOptions"].args[-1]')" = '--user-agent=My "quoted" agent' ]
}

@test "_json_array returns an empty list without arguments" {
  run _json_array
  [ "$output" = "[]" ]
}

# =====================
# Exit codes
# =====================

@test "_check_error fails when the driver gives no response" {
  run _check_error ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"no response from the driver"* ]]
}

@test "_value prints the value of a successful response" {
  run _value '{"value": "hello"}'
  [ "$status" -eq 0 ]
  [ "$output" = "hello" ]
}

@test "_value applies the given filter" {
  run _value '{"value": {"handle": "w1"}}' '.value.handle'
  [ "$output" = "w1" ]
}

@test "getters return 1 and print nothing but the error on a WebDriver error" {
  _mock_curl '{"value": {"error": "invalid session id", "message": "gone"}}'

  local fn
  for fn in get_title get_current_url get_page_source get_window_handle get_window_handles get_all_cookies get_timeouts get_alert_text get_window_rect get_active_element; do
    run "$fn"
    [ "$status" -eq 1 ]
    [ "$output" = "[shellnium] Error: invalid session id - gone" ]
  done
}

@test "element getters return 1 on a WebDriver error" {
  _mock_curl '{"value": {"error": "stale element reference", "message": "old"}}'

  local fn
  for fn in get_text get_tag_name get_rect is_element_enabled is_element_displayed; do
    run "$fn" 'elem-1'
    [ "$status" -eq 1 ]
    [[ "$output" == *"stale element reference"* ]]
  done
  run get_attribute 'elem-1' 'value'
  [ "$status" -eq 1 ]
  run get_property 'elem-1' 'value'
  [ "$status" -eq 1 ]
  run get_css_value 'elem-1' 'color'
  [ "$status" -eq 1 ]
}

@test "getters return 1 when the driver is not reachable" {
  curl() { return 7; }
  export -f curl

  run get_title
  [ "$status" -eq 1 ]
  [[ "$output" == *"no response from the driver"* ]]
}

@test "get_named_cookie returns 1 when the cookie does not exist" {
  _mock_curl '{"value": {"error": "no such cookie", "message": "none"}}'

  run get_named_cookie 'missing'
  [ "$status" -eq 1 ]
}

@test "screenshot returns 1 and writes no file on a WebDriver error" {
  _mock_curl '{"value": {"error": "invalid session id", "message": "gone"}}'

  run screenshot "${BATS_TEST_TMPDIR}/shot.png"
  [ "$status" -eq 1 ]
  [ ! -e "${BATS_TEST_TMPDIR}/shot.png" ]
}

@test "perform_actions returns 1 on a WebDriver error" {
  _mock_curl '{"value": {"error": "move target out of bounds", "message": "outside"}}'

  run perform_actions '{"actions":[]}'
  [ "$status" -eq 1 ]
  [[ "$output" == *"move target out of bounds"* ]]
}

@test "delete_window and new_window report WebDriver errors" {
  _mock_curl '{"value": {"error": "no such window", "message": "closed"}}'

  run delete_window
  [ "$status" -eq 1 ]
  run new_window tab
  [ "$status" -eq 1 ]
}

@test "getters still succeed on a normal response" {
  _mock_curl '{"value": "Example Domain"}'

  run get_title
  [ "$status" -eq 0 ]
  [ "$output" = "Example Domain" ]
}

# =====================
# wait_for_url_contains / wait_for_title_contains
# =====================

@test "wait_for_url_contains succeeds once the URL contains the text" {
  get_current_url() { echo "https://example.com/dashboard?tab=1"; }
  sleep() { :; }

  run wait_for_url_contains "/dashboard?tab" 1 0.25
  [ "$status" -eq 0 ]
}

@test "wait_for_url_contains treats the text literally and times out" {
  get_current_url() { echo "https://example.com/login"; }
  sleep() { :; }

  run wait_for_url_contains "log.n" 1 0.25
  [ "$status" -eq 1 ]
  [[ "$output" == *"Timeout"* ]]
}

@test "wait_for_title_contains succeeds once the title contains the text" {
  get_title() { echo "My Dashboard - App"; }
  sleep() { :; }

  run wait_for_title_contains "Dashboard" 1 0.25
  [ "$status" -eq 0 ]
}

@test "wait_for_title_contains times out when the title never matches" {
  get_title() { echo "Login"; }
  sleep() { :; }

  run wait_for_title_contains "Dashboard" 1 0.25
  [ "$status" -eq 1 ]
  [[ "$output" == *"Timeout"* ]]
}
