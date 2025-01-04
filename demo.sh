#!/usr/bin/env bash

# Resolve location of current script, in case it's executed from another folder.
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/lib/selenium.sh"

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
