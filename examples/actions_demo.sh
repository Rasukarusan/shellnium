#!/usr/bin/env bash

# Actions API demo - test keyboard and mouse actions with verification
# Usage: ./examples/actions_demo.sh [--headless]

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh" "$@"

PASS=0
FAIL=0

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "    PASS: $label"
        ((PASS++))
    else
        echo "    FAIL: $label (expected='$expected', actual='$actual')"
        ((FAIL++))
    fi
}

# Inline test page with input, buttons, and draggable box
TEST_PAGE='data:text/html,<!DOCTYPE html>
<html><body style="margin:40px;font-family:sans-serif">
<h3 id="title">Actions API Test Page</h3>
<input id="input1" type="text" style="width:300px;padding:8px;font-size:16px" />
<br><br>
<button id="btn1" onmouseenter="this.dataset.hovered=1"
  oncontextmenu="event.preventDefault();this.dataset.rightclicked=1"
  ondblclick="this.dataset.dblclicked=1">Test Button</button>
<br><br>
<div id="box" style="width:80px;height:80px;background:coral;position:absolute;top:250px;left:50px;cursor:grab;border-radius:8px"></div>
<div id="target" style="width:120px;height:120px;border:3px dashed gray;position:absolute;top:250px;left:300px;border-radius:8px"></div>
<div id="log" style="margin-top:200px;color:gray"></div>
<script>
var box=document.getElementById("box"),dragging=false,ox=0,oy=0;
box.addEventListener("mousedown",function(e){dragging=true;ox=e.clientX-box.offsetLeft;oy=e.clientY-box.offsetTop});
document.addEventListener("mousemove",function(e){if(dragging){box.style.left=(e.clientX-ox)+"px";box.style.top=(e.clientY-oy)+"px"}});
document.addEventListener("mouseup",function(){if(dragging){dragging=false;box.dataset.dropped=1}});
</script></body></html>'

main() {
    echo "=== Actions API Demo ==="
    navigate_to "$TEST_PAGE"
    sleep 1

    # [1] key_press - Enter key
    echo ""
    echo "[1] key_press: type text and press Enter to submit"
    local input=$(find_element 'id' 'input1')
    send_keys "$input" "hello"
    # Attach a keydown listener that records Enter
    exec_script 'document.getElementById("input1").addEventListener("keydown",function(e){if(e.key==="Enter")this.dataset.enterPressed="1"})' >/dev/null
    key_press "$KEY_ENTER"
    sleep 0.5
    local enterPressed=$(exec_script 'return document.getElementById("input1").dataset.enterPressed || ""' | jq -r '.value')
    assert_eq "Enter key was received" "1" "$enterPressed"

    # [2] send_key_combo - Ctrl+A to select all, then overwrite
    echo ""
    echo "[2] send_key_combo: Cmd/Ctrl+A to select all and replace text"
    click "$input"
    # macOS uses Cmd+A, Linux/Windows uses Ctrl+A
    if [[ "$(uname)" == "Darwin" ]]; then
        send_key_combo "$KEY_META" "a"
    else
        send_key_combo "$KEY_CONTROL" "a"
    fi
    send_keys "$input" "replaced"
    sleep 0.5
    local inputVal=$(get_attribute "$input" 'value')
    assert_eq "Text replaced via Ctrl+A" "replaced" "$inputVal"

    # [3] hover - mouseenter event
    echo ""
    echo "[3] hover: mouseenter fires on button"
    local btn=$(find_element 'id' 'btn1')
    hover "$btn"
    sleep 0.5
    local hovered=$(exec_script 'return document.getElementById("btn1").dataset.hovered || ""' | jq -r '.value')
    assert_eq "Button received mouseenter" "1" "$hovered"

    # [4] right_click - contextmenu event
    echo ""
    echo "[4] right_click: contextmenu fires on button"
    right_click "$btn"
    sleep 0.5
    local rightClicked=$(exec_script 'return document.getElementById("btn1").dataset.rightclicked || ""' | jq -r '.value')
    assert_eq "Button received contextmenu" "1" "$rightClicked"
    key_press "$KEY_ESCAPE"

    # [5] double_click - dblclick event
    echo ""
    echo "[5] double_click: dblclick fires on button"
    double_click "$btn"
    sleep 0.5
    local dblClicked=$(exec_script 'return document.getElementById("btn1").dataset.dblclicked || ""' | jq -r '.value')
    assert_eq "Button received dblclick" "1" "$dblClicked"

    # [6] drag_and_drop - box position changes
    echo ""
    echo "[6] drag_and_drop: box moves to target"
    local boxEl=$(find_element 'id' 'box')
    local targetEl=$(find_element 'id' 'target')
    local beforeLeft=$(exec_script 'return document.getElementById("box").offsetLeft' | jq -r '.value')
    drag_and_drop "$boxEl" "$targetEl"
    sleep 1
    local afterLeft=$(exec_script 'return document.getElementById("box").offsetLeft' | jq -r '.value')
    if [[ "$afterLeft" -gt "$beforeLeft" ]]; then
        echo "    PASS: Box moved (left: $beforeLeft -> $afterLeft)"
        ((PASS++))
    else
        echo "    FAIL: Box did not move (left: $beforeLeft -> $afterLeft)"
        ((FAIL++))
    fi

    # [7] key_down / key_up - Shift held for uppercase
    echo ""
    echo "[7] key_down/key_up: Shift held produces uppercase"
    # Clear input and type with Shift held
    click "$input"
    send_key_combo "$KEY_CONTROL" "a"
    send_keys "$input" ""
    exec_script 'document.getElementById("input1").value=""' >/dev/null
    click "$input"
    key_down "$KEY_SHIFT"
    key_press "h"
    key_press "e"
    key_press "l"
    key_press "l"
    key_press "o"
    key_up "$KEY_SHIFT"
    sleep 0.5
    local upperVal=$(get_attribute "$input" 'value')
    assert_eq "Shift+typing produces uppercase" "HELLO" "$upperVal"

    # [8] release_actions - clears held modifier
    echo ""
    echo "[8] release_actions: clears held keys"
    exec_script 'document.getElementById("input1").value=""' >/dev/null
    click "$input"
    key_down "$KEY_SHIFT"
    release_actions
    # Type after release - should be lowercase since Shift was released
    key_press "a"
    sleep 0.5
    local releasedVal=$(get_attribute "$input" 'value')
    assert_eq "After release_actions, typing is lowercase" "a" "$releasedVal"

    # ---- Summary ----
    echo ""
    echo "=== Results: $PASS passed, $FAIL failed ==="
    delete_session

    [[ "$FAIL" -eq 0 ]]
}

main
