#!/usr/bin/env bash

# =============================================================================
# screenshot_batch.sh - Batch Screenshot Example
# =============================================================================
# Takes screenshots of multiple URLs and saves them to a specified directory.
# Useful for visual regression testing or archiving web pages.
#
# Usage:
#   bash examples/screenshot_batch.sh [--headless]
#
# Output:
#   Screenshots are saved to ./screenshots/ directory.
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

# List of URLs to capture
URLS=(
    "https://example.com"
    "https://httpbin.org"
    "https://news.ycombinator.com"
)

OUTPUT_DIR="${SCRIPT_DIR}/screenshots"

main() {
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    echo "Screenshots will be saved to: ${OUTPUT_DIR}"
    echo "---"

    local count=0
    local total=${#URLS[@]}

    for url in "${URLS[@]}"; do
        count=$((count + 1))

        # Generate a filename from the URL
        local filename
        filename=$(echo "$url" | sed 's|https\?://||; s|[^a-zA-Z0-9]|_|g')
        filename="${filename}.png"

        echo "[${count}/${total}] Capturing: ${url}"
        navigate_to "$url"

        # Wait for page to load
        sleep 1

        local title
        title=$(get_title)
        echo "  Title: ${title}"

        # Take screenshot
        screenshot "${OUTPUT_DIR}/${filename}"
        echo "  Saved: ${OUTPUT_DIR}/${filename}"
        echo ""
    done

    echo "---"
    echo "Batch complete. ${count} screenshots saved to ${OUTPUT_DIR}/"

    # Clean up
    delete_session
}

main
