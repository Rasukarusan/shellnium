#!/usr/bin/env bash

# =============================================================================
# multi_tab.sh - Multiple Tab Operations Example
# =============================================================================
# Demonstrates how to open multiple browser tabs, switch between them,
# and collect information from each tab.
#
# Usage:
#   bash examples/multi_tab.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

main() {
    echo "=== Multi-Tab Operations Demo ==="
    echo ""

    # Navigate to the first page in the initial tab
    echo "[Tab 1] Opening example.com ..."
    navigate_to "https://example.com"
    local tab1_handle
    tab1_handle=$(get_window_handle)
    local tab1_title
    tab1_title=$(get_title)
    echo "[Tab 1] Title: ${tab1_title}"
    echo "[Tab 1] Handle: ${tab1_handle}"
    echo ""

    # Open a second tab
    echo "[Tab 2] Opening new tab ..."
    local tab2_handle
    tab2_handle=$(new_window 'tab')
    switch_to_window "$tab2_handle"
    navigate_to "https://httpbin.org"
    sleep 1
    local tab2_title
    tab2_title=$(get_title)
    echo "[Tab 2] Title: ${tab2_title}"
    echo "[Tab 2] Handle: ${tab2_handle}"
    echo ""

    # Open a third tab
    echo "[Tab 3] Opening new tab ..."
    local tab3_handle
    tab3_handle=$(new_window 'tab')
    switch_to_window "$tab3_handle"
    navigate_to "https://news.ycombinator.com"
    sleep 1
    local tab3_title
    tab3_title=$(get_title)
    echo "[Tab 3] Title: ${tab3_title}"
    echo "[Tab 3] Handle: ${tab3_handle}"
    echo ""

    # List all open tabs
    echo "--- All open tabs ---"
    local handles
    handles=$(get_window_handles)
    local tab_num=0
    for handle in $handles; do
        tab_num=$((tab_num + 1))
        switch_to_window "$handle"
        local title
        title=$(get_title)
        local url
        url=$(get_current_url)
        echo "  Tab ${tab_num}: ${title} (${url})"
    done
    echo ""

    # Switch back to the first tab
    echo "Switching back to Tab 1 ..."
    switch_to_window "$tab1_handle"
    echo "Current tab title: $(get_title)"
    echo ""

    # Close the third tab
    echo "Closing Tab 3 ..."
    switch_to_window "$tab3_handle"
    delete_window
    echo ""

    # Switch back to tab 1 after closing tab 3
    switch_to_window "$tab1_handle"

    # List remaining tabs
    echo "--- Remaining tabs ---"
    handles=$(get_window_handles)
    tab_num=0
    for handle in $handles; do
        tab_num=$((tab_num + 1))
        switch_to_window "$handle"
        echo "  Tab ${tab_num}: $(get_title)"
    done

    echo ""
    echo "Done."

    # Clean up
    delete_session
}

main
