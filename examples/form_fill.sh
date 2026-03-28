#!/usr/bin/env bash

# =============================================================================
# form_fill.sh - Form Auto-Fill Example
# =============================================================================
# Demonstrates how to locate form fields, fill them in, and submit a form.
# Uses a locally generated HTML form page.
#
# Usage:
#   bash examples/form_fill.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

_create_form_page() {
    local tmpfile
    tmpfile=$(mktemp /tmp/shellnium-form-XXXXXX.html)
    cat > "$tmpfile" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Order Form</title>
<style>
  body { font-family: sans-serif; max-width: 500px; margin: 40px auto; }
  label { display: block; margin-top: 12px; font-weight: bold; }
  input[type="text"], input[type="tel"], input[type="email"], textarea {
    width: 100%; padding: 6px; margin-top: 4px; box-sizing: border-box;
  }
  .radio-group, .checkbox-group { margin-top: 4px; }
  button { margin-top: 16px; padding: 8px 20px; }
  #result { margin-top: 20px; padding: 12px; background: #e8f5e9; display: none; }
</style>
</head>
<body>
<h1>Order Form</h1>
<form id="order-form" onsubmit="event.preventDefault(); showResult();">
  <label for="custname">Customer Name</label>
  <input type="text" id="custname" name="custname" />

  <label for="custtel">Telephone</label>
  <input type="tel" id="custtel" name="custtel" />

  <label for="custemail">E-mail</label>
  <input type="email" id="custemail" name="custemail" />

  <label>Pizza Size</label>
  <div class="radio-group">
    <label><input type="radio" name="size" value="small" /> Small</label>
    <label><input type="radio" name="size" value="medium" /> Medium</label>
    <label><input type="radio" name="size" value="large" /> Large</label>
  </div>

  <label>Toppings</label>
  <div class="checkbox-group">
    <label><input type="checkbox" name="topping" value="cheese" /> Cheese</label>
    <label><input type="checkbox" name="topping" value="pepperoni" /> Pepperoni</label>
    <label><input type="checkbox" name="topping" value="mushroom" /> Mushroom</label>
  </div>

  <label for="comments">Delivery Instructions</label>
  <textarea id="comments" name="comments" rows="3"></textarea>

  <button type="submit" id="submit-btn">Submit Order</button>
</form>
<div id="result"></div>
<script>
function showResult() {
  var form = document.getElementById('order-form');
  var data = new FormData(form);
  var entries = [];
  for (var pair of data.entries()) { entries.push(pair[0] + ': ' + pair[1]); }
  var el = document.getElementById('result');
  el.textContent = 'Order submitted! ' + entries.join(', ');
  el.style.display = 'block';
}
</script>
</body>
</html>
HTMLEOF
    echo "$tmpfile"
}

main() {
    local html_file
    html_file=$(_create_form_page)
    trap "rm -f '$html_file'" EXIT

    local url="file://${html_file}"
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
    submit_btn=$(find_element 'id' 'submit-btn')
    click "$submit_btn"
    echo "Form submitted!"

    sleep 1

    # Show result
    local result
    result=$(find_element 'id' 'result')
    echo "Result: $(get_text "$result")"

    # Clean up
    delete_session
}

main
