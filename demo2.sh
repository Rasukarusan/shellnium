#!/usr/bin/env bash
options=",\"chromeOptions\": { \"args\": [\"--headless\"] }"
source ./selenium.sh

main() {
    screen_clear
    navigate_to 'https://google.co.jp'

    local searchBox=$(find_element 'name' 'q')
    set_background_image

    # 入力している感を出すため1文字ずつ入力
    local words=('タ' 'ピ' 'オ' 'カ')
    for word in ${words[@]}; do
        send_keys $searchBox $word
        set_background_image
    done

    # ENTER
    send_keys $searchBox '\n'
    set_background_image

    for i in `seq 0 100 1000`; do
        exec_sync_script "window.scroll(0,$i)"
        set_background_image
    done
    screen_clear
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
    local screenshotPath=$(pwd)/image.jpg
    screenshot $screenshotPath
    iterm_set_background_image $screenshotPath
}

screen_clear() {
    clear
    iterm_set_background_image ''
}

main
