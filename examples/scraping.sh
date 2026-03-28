#!/usr/bin/env bash

# =============================================================================
# scraping.sh - Web Scraping Example
# =============================================================================
# Demonstrates how to extract data from a web page using Shellnium.
# This example navigates to the Hacker News front page and extracts
# the top story titles and their URLs.
#
# Usage:
#   bash examples/scraping.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

main() {
    local url="https://news.ycombinator.com/"
    echo "Navigating to ${url} ..."
    navigate_to "$url"

    # Extract the page title
    local title
    title=$(get_title)
    echo "Page title: ${title}"
    echo "---"

    # Find all story title links on the page
    local elements
    elements=$(find_elements 'css selector' '.titleline > a')

    local count=0
    for element in $elements; do
        if [ "$count" -ge 10 ]; then
            break
        fi
        count=$((count + 1))

        local text href
        text=$(get_text "$element")
        href=$(get_attribute "$element" 'href')
        echo "${count}. ${text}"
        echo "   URL: ${href}"
    done

    echo "---"
    echo "Extracted ${count} stories."

    # Clean up
    delete_session
}

main
