#!/usr/bin/env bash

ROOT=http://localhost:9515
POST='curl -s -X POST -H "Content-Type: application/json"'
PATH_SCREENSHOT=$(pwd)/image.jpg

get_session_id() {
    $POST -d '{
        "desiredCapabilities": {
            "browserName": "chrome",
            "chromeOptions": {
                "args": [ "--headless" ]
            }
        }
    }' \
    ${ROOT}/session| jq -r '.sessionId'
}
SESSION_ID=$(get_session_id)
BASE_URL=${ROOT}/session/${SESSION_ID}

rect() {
    $POST -d '{"height": 1000,"width":200, "x":0, "y":0}' $BASE_URL/window/rect >/dev/null
}

navigate_to() { local url=$1
    $POST -d '{"url":"'${url}'"}' ${BASE_URL}/url >/dev/null
}

find_element() {
    local property=$1
    local value=$2
    $POST -d '{"using":"'$property'", "value": "'$value'"}' ${BASE_URL}/element | jq -r '.value.ELEMENT'
}

find_elements() {
    local property=$1
    local value=$2
    echo  "$property"
    $POST -d '{"using":"'$property'", "value": "'$value'"}' ${BASE_URL}/elements
}

# []のリスト型で渡すこと
# \nでENTERの効果がある
send_keys() {
    local elementId=$1
    local value=$2
    $POST -d '{"value": ["'$value'"]}' ${BASE_URL}/element/${elementId}/value >/dev/null
}

click() {
    local elementId=$1
    $POST ${BASE_URL}/element/${elementId}/click >/dev/null
}

screenshot() {
    curl -s -X GET $BASE_URL/screenshot | jq -r '.value' | base64 -d > $PATH_SCREENSHOT
}

exec_sync_script() {
    $POST -d '{"script": "'$1'", "args":[]}' ${BASE_URL}/execute/sync >/dev/null
}

iterm_set_background_image() {
osascript << EOF
    tell application "iTerm"
        activate
        set _current_session to current session of current window
        tell _current_session
            set background image to "$1"
        end tell
    end tell
EOF
}

set_background_image() {
    iterm_set_background_image $PATH_SCREENSHOT
}

screen_clear() {
    clear
    iterm_set_background_image ''
}

main() {
    screen_clear
    navigate_to 'https://google.co.jp'

    local searchBox=$(find_element 'name' 'q')
    screenshot && set_background_image

    local words=('タ' 'ピ' 'オ' 'カ')
    for word in ${words[@]}; do
        send_keys $searchBox $word
        screenshot && set_background_image
    done

    send_keys $searchBox '\n'
    screenshot && set_background_image

    for i in `seq 0 100 1000`; do
        exec_sync_script "window.scroll(0,$i)"
        screenshot && set_background_image
    done
}

main
