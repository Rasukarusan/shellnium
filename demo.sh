#!/usr/bin/env bash
source ./selenium.sh

main() {
    # Open the apage.
    navigate_to 'https://google.co.jp'

    # get the element of the search box.
    local searchBox=$(find_element 'name' 'q')

    # Input to the search box and enter.
    send_keys $searchBox "panda\n"

    delete_session
}

main
