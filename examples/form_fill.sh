#!/usr/bin/env bash

# =============================================================================
# form_fill.sh - Form Auto-Fill Example
# =============================================================================
# Demonstrates how to locate form fields, fill them in, and submit a form.
# Uses httpbin.org's form page as a safe, public test endpoint.
#
# Usage:
#   bash examples/form_fill.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

main() {
    local url="https://httpbin.org/forms/post"
    echo "Navigating to ${url} ..."
    navigate_to "$url"

    echo "Page title: $(get_title)"

    # Fill in the customer name field
    local custname
    custname=$(find_element 'name' 'custname')
    send_keys "$custname" "John Doe"
    echo "Filled: custname = John Doe"

    # Fill in the telephone field
    local telephone
    telephone=$(find_element 'name' 'custtel')
    send_keys "$telephone" "123-456-7890"
    echo "Filled: custtel = 123-456-7890"

    # Fill in the email field
    local email
    email=$(find_element 'name' 'custemail')
    send_keys "$email" "john@example.com"
    echo "Filled: custemail = john@example.com"

    # Select a pizza size (radio button)
    local size
    size=$(find_element 'xpath' "//input[@name='size' and @value='medium']")
    click "$size"
    echo "Selected: size = medium"

    # Check a topping (checkbox)
    local topping
    topping=$(find_element 'xpath' "//input[@name='topping' and @value='cheese']")
    click "$topping"
    echo "Checked: topping = cheese"

    # Fill in delivery instructions
    local instructions
    instructions=$(find_element 'name' 'comments')
    send_keys "$instructions" "Please ring the doorbell."
    echo "Filled: comments = Please ring the doorbell."

    # Submit the form
    local submit_btn
    submit_btn=$(find_element 'xpath' "//button[@type='submit']")
    click "$submit_btn"
    echo "Form submitted!"

    sleep 2
    echo "Current URL after submit: $(get_current_url)"

    # Clean up
    delete_session
}

main
