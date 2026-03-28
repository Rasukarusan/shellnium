#!/usr/bin/env bash

# =============================================================================
# scraping.sh - Web Scraping Example
# =============================================================================
# Demonstrates how to extract data from a web page using Shellnium.
# This example scrapes a locally generated news listing page.
#
# Usage:
#   bash examples/scraping.sh [--headless]
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

_create_news_page() {
    local tmpfile
    tmpfile=$(mktemp /tmp/shellnium-scrape-XXXXXX.html)
    cat > "$tmpfile" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Tech News</title>
<style>
  body { font-family: sans-serif; max-width: 700px; margin: 20px auto; background: #fafafa; }
  h1 { color: #ff6600; }
  .story { padding: 4px 0; }
  .titleline a { color: #000; text-decoration: none; font-size: 14px; }
  .titleline a:hover { text-decoration: underline; }
  .meta { font-size: 11px; color: #828282; }
</style>
</head>
<body>
<h1>Tech News</h1>
<table>
  <tr class="story"><td class="titleline"><a href="https://example.com/article1">Bash scripting best practices for 2026</a></td></tr>
  <tr class="meta"><td>42 points | 15 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article2">WebDriver protocol explained simply</a></td></tr>
  <tr class="meta"><td>38 points | 12 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article3">Why shell automation is underrated</a></td></tr>
  <tr class="meta"><td>55 points | 23 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article4">jq tips and tricks for JSON processing</a></td></tr>
  <tr class="meta"><td>31 points | 8 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article5">Building a CI pipeline with shell scripts</a></td></tr>
  <tr class="meta"><td>27 points | 10 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article6">Understanding ChromeDriver internals</a></td></tr>
  <tr class="meta"><td>44 points | 19 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article7">Curl tricks every developer should know</a></td></tr>
  <tr class="meta"><td>61 points | 25 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article8">Selenium vs Playwright vs Shellnium</a></td></tr>
  <tr class="meta"><td>89 points | 42 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article9">How to test without external dependencies</a></td></tr>
  <tr class="meta"><td>33 points | 14 comments</td></tr>
  <tr class="story"><td class="titleline"><a href="https://example.com/article10">Terminal-first development workflow</a></td></tr>
  <tr class="meta"><td>47 points | 18 comments</td></tr>
</table>
</body>
</html>
HTMLEOF
    echo "$tmpfile"
}

main() {
    local html_file
    html_file=$(_create_news_page)
    trap "rm -f '$html_file'" EXIT

    local url="file://${html_file}"
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
