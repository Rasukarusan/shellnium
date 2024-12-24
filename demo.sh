#!/usr/bin/env bash
source ./lib/selenium.sh

main() {
    # Open the page.
    navigate_to 'https://www.google.com'

    # get the element of the search box.
    local searchBox=$(find_element 'name' 'q')

    # Input to the search box and enter.
    send_keys $searchBox "panda\n"

    # Wait for a few seconds to allow the search results to load and be visible.
    sleep 2

    # close the session
    delete_session
}

main
