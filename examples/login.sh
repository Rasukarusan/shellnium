#!/usr/bin/env bash

# =============================================================================
# login.sh - Login Automation with Cookie Handling
# =============================================================================
# Demonstrates how to automate a login flow and inspect cookies.
# Uses the-internet.herokuapp.com's login page as a safe test target.
#
# Usage:
#   bash examples/login.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

COOKIE_FILE="/tmp/shellnium_cookies.json"

save_cookies() {
    echo "Saving cookies to ${COOKIE_FILE} ..."
    get_all_cookies | jq -s '.' > "$COOKIE_FILE"
    echo "Cookies saved."
}

main() {
    local url="https://the-internet.herokuapp.com/login"
    echo "Navigating to ${url} ..."
    navigate_to "$url"

    echo "Page title: $(get_title)"

    # Enter username
    local username_field
    username_field=$(find_element 'id' 'username')
    send_keys "$username_field" "tomsmith"
    echo "Entered username: tomsmith"

    # Enter password
    local password_field
    password_field=$(find_element 'id' 'password')
    send_keys "$password_field" "SuperSecretPassword!"
    echo "Entered password: ****"

    # Click login button
    local login_btn
    login_btn=$(find_element 'css selector' 'button[type="submit"]')
    click "$login_btn"
    echo "Clicked login button."

    sleep 2

    # Check if login was successful by looking at the URL or flash message
    local current_url
    current_url=$(get_current_url)
    echo "Current URL: ${current_url}"

    local flash
    flash=$(find_element 'id' 'flash')
    local flash_text
    flash_text=$(get_text "$flash")
    echo "Flash message: ${flash_text}"

    # Save cookies after login
    save_cookies

    # Display saved cookies
    echo "---"
    echo "Saved cookies:"
    cat "$COOKIE_FILE"

    # Clean up
    delete_session
    echo "---"
    echo "Done. Cookies saved to ${COOKIE_FILE}"
}

main
