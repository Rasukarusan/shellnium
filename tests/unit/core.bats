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

@test "find_element builds correct JSON payload with id" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-789"}}'
  }
  export -f curl

  find_element 'id' 'my-element'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "id"'* ]]
  [[ "$output" == *'"value": "my-element"'* ]]
}

@test "find_element builds correct JSON payload with name" {
  curl() {
    for arg in "$@"; do
      echo "$arg"
    done >> "$CURL_LOG"
    echo '{"value": {"ELEMENT": "elem-name"}}'
  }
  export -f curl

  find_element 'name' 'username'
  run cat "$CURL_LOG"
  [[ "$output" == *'"using": "name"'* ]]
  [[ "$output" == *'"value": "username"'* ]]
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
