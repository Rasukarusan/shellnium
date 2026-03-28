#!/usr/bin/env bash

# =============================================================================
# login.sh - Login Automation with Cookie Handling
# =============================================================================
# Demonstrates how to automate a login flow and inspect cookies.
# Uses a locally generated HTML login page.
#
# Usage:
#   bash examples/login.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

COOKIE_FILE="/tmp/shellnium_cookies.json"

_create_login_page() {
    local tmpfile
    tmpfile=$(mktemp /tmp/shellnium-login-XXXXXX.html)
    cat > "$tmpfile" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Login Page</title>
<style>
  body { font-family: sans-serif; max-width: 400px; margin: 60px auto; }
  h2 { text-align: center; }
  label { display: block; margin-top: 12px; font-weight: bold; }
  input[type="text"], input[type="password"] {
    width: 100%; padding: 8px; margin-top: 4px; box-sizing: border-box;
  }
  button { width: 100%; padding: 10px; margin-top: 16px; cursor: pointer;
           background: #1976d2; color: white; border: none; font-size: 16px; }
  #flash { padding: 12px; margin-top: 16px; border-radius: 4px; display: none; }
  .success { background: #c8e6c9; color: #2e7d32; }
  .error { background: #ffcdd2; color: #c62828; }
</style>
</head>
<body>
<h2>Login</h2>
<form id="login-form" onsubmit="event.preventDefault(); doLogin();">
  <label for="username">Username</label>
  <input type="text" id="username" name="username" />
  <label for="password">Password</label>
  <input type="password" id="password" name="password" />
  <button type="submit">Login</button>
</form>
<div id="flash"></div>
<script>
function doLogin() {
  var user = document.getElementById('username').value;
  var pass = document.getElementById('password').value;
  var flash = document.getElementById('flash');
  if (user === 'tomsmith' && pass === 'SuperSecretPassword!') {
    flash.textContent = 'You logged into a secure area!';
    flash.className = 'success';
    flash.style.display = 'block';
    document.cookie = 'session=abc123; path=/';
    document.cookie = 'user=' + user + '; path=/';
    location.hash = '#/secure';
  } else {
    flash.textContent = 'Your username is invalid!';
    flash.className = 'error';
    flash.style.display = 'block';
  }
}
</script>
</body>
</html>
HTMLEOF
    echo "$tmpfile"
}

save_cookies() {
    echo "Saving cookies to ${COOKIE_FILE} ..."
    get_all_cookies > "$COOKIE_FILE"
    echo "Cookies saved."
}

main() {
    local html_file
    html_file=$(_create_login_page)
    trap "rm -f '$html_file'" EXIT

    local url="file://${html_file}"
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
    login_btn=$(find_element 'xpath' "//button[@type='submit']")
    click "$login_btn"
    echo "Clicked login button."

    sleep 1

    # Check if login was successful
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
