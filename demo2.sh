#!/usr/bin/env bash

# Resolve location of current script, in case it's executed from another folder.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/lib/selenium.sh" --headless

main() {
    screen_clear
    navigate_to 'https://www.google.com/?gl=us&hl=en&gws_rd=cr&pws=0'

    local searchBox=$(find_element 'name' 'q')
    set_background_image

    # Enter one character at a time to give the feeling of typing
    local words=('d' 'o' 'g' '\n')
    for word in ${words[@]}; do
        send_keys $searchBox $word
        set_background_image $word
    done

    for i in `seq 0 100 1000`; do
        exec_script "window.scroll(0,$i)"
        set_background_image $i
    done

    screen_clear
    delete_session
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
    local screenshotPath="$(pwd)/demo-image-${1}.jpg"
    screenshot $screenshotPath
    iterm_set_background_image $screenshotPath
}

screen_clear() {
    clear
    iterm_set_background_image ''
}

main
