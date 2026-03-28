#!/usr/bin/env bash

# =============================================================================
# wait_demo.sh - Wait / Retry Functions Demo
# =============================================================================
# Demonstrates wait_for_element, wait_for_clickable, wait_for_text,
# wait_for_url, and retry using a local HTML page with delayed elements.
#
# Usage:
#   bash examples/wait_demo.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

# Generate the test HTML as a temp file to avoid path resolution issues
_create_test_html() {
    local tmpfile
    tmpfile=$(mktemp /tmp/shellnium-wait-demo-XXXXXX.html)
    cat > "$tmpfile" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Shellnium Wait Demo</title>
<style>
  body { font-family: sans-serif; max-width: 600px; margin: 40px auto; }
  .hidden { display: none; }
  button { padding: 8px 16px; cursor: pointer; margin: 4px; }
  #delayed-box { background: #e0f7fa; padding: 16px; border-radius: 8px; }
  #lazy-button { background: #c8e6c9; }
  #result-text { color: #1b5e20; font-weight: bold; }
  #status { margin-top: 16px; color: #666; }
</style>
</head>
<body>

<h1>Wait Demo</h1>
<p>This page adds elements dynamically to test Shellnium's wait functions.</p>

<!-- 1. wait_for_element: element appears after 3 seconds -->
<section>
  <h2>1. Delayed Element (3s)</h2>
  <div id="delayed-container"></div>
</section>

<!-- 2. wait_for_clickable: button appears disabled, becomes enabled after 2s -->
<section>
  <h2>2. Clickable Button (disabled -> enabled)</h2>
  <button id="lazy-button" disabled>Loading...</button>
</section>

<!-- 3. wait_for_text: text injected after 4s -->
<section>
  <h2>3. Dynamic Text (4s)</h2>
  <div id="text-area"></div>
</section>

<!-- 4. wait_for_url: URL hash changes after clicking a button -->
<section>
  <h2>4. URL Change</h2>
  <button id="navigate-btn" onclick="setTimeout(function(){ location.hash='#dashboard'; }, 1500)">
    Go to Dashboard
  </button>
</section>

<!-- 5. retry: flaky counter that succeeds on the 3rd call -->
<section>
  <h2>5. Flaky Counter (retry)</h2>
  <div id="flaky-counter" data-count="0"></div>
</section>

<div id="status">Waiting for events...</div>

<script>
  // 1. Inject a box after 3 seconds
  setTimeout(function() {
    var box = document.createElement('div');
    box.id = 'delayed-box';
    box.textContent = 'I appeared after 3 seconds!';
    document.getElementById('delayed-container').appendChild(box);
  }, 3000);

  // 2. Enable button after 2 seconds
  setTimeout(function() {
    var btn = document.getElementById('lazy-button');
    btn.disabled = false;
    btn.textContent = 'Click Me!';
  }, 2000);

  // 3. Inject text after 4 seconds
  setTimeout(function() {
    var area = document.getElementById('text-area');
    area.innerHTML = '<span id="result-text">Data loaded successfully!</span>';
  }, 4000);

  // 5. Flaky counter: increments on each read; returns empty until count >= 3
  var flakyCount = 0;
  setInterval(function() {
    flakyCount++;
    var el = document.getElementById('flaky-counter');
    el.setAttribute('data-count', flakyCount);
    if (flakyCount >= 3) {
      el.textContent = 'ready:' + flakyCount;
    }
  }, 1000);
</script>

</body>
</html>
HTMLEOF
    echo "$tmpfile"
}

main() {
    local html_file
    html_file=$(_create_test_html)
    trap "rm -f '$html_file'" EXIT

    local html_path="file://${html_file}"
    echo "Navigating to ${html_path} ..."
    navigate_to "$html_path"
    echo "Page title: $(get_title)"
    echo ""

    # --- 1. wait_for_element ---
    echo "=== 1. wait_for_element ==="
    echo "Waiting for #delayed-box (appears after 3s) ..."
    local box
    if box=$(wait_for_element 'css selector' '#delayed-box' 10); then
        echo "  Found! text = $(get_text "$box")"
    else
        echo "  FAILED: element not found"
    fi
    echo ""

    # --- 2. wait_for_clickable ---
    echo "=== 2. wait_for_clickable ==="
    echo "Waiting for #lazy-button to become clickable ..."
    local btn
    if btn=$(wait_for_clickable 'css selector' '#lazy-button' 10); then
        echo "  Clickable! text = $(get_text "$btn")"
        click "$btn"
        echo "  Clicked the button."
    else
        echo "  FAILED: button not clickable"
    fi
    echo ""

    # --- 3. wait_for_text ---
    echo "=== 3. wait_for_text ==="
    echo "Waiting for 'Data loaded successfully!' (appears after 4s) ..."
    if wait_for_text "Data loaded successfully!" 10; then
        echo "  Found the text!"
    else
        echo "  FAILED: text not found"
    fi
    echo ""

    # --- 4. wait_for_url ---
    echo "=== 4. wait_for_url ==="
    echo "Clicking navigate button and waiting for URL to contain '#dashboard' ..."
    local nav_btn
    nav_btn=$(find_element 'css selector' '#navigate-btn')
    click "$nav_btn"
    if wait_for_url "#dashboard" 10; then
        echo "  URL matched! current = $(get_current_url)"
    else
        echo "  FAILED: URL did not match"
    fi
    echo ""

    # --- 5. retry ---
    echo "=== 5. retry ==="
    echo "Retrying to get #flaky-counter text (succeeds when count >= 3) ..."
    local counter_text
    if counter_text=$(retry 5 1 get_text "$(find_element 'css selector' '#flaky-counter')"); then
        echo "  Got text: ${counter_text}"
    else
        echo "  FAILED: retry exhausted"
    fi
    echo ""

    echo "All demos completed."
    delete_session
}

main
