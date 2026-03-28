#!/usr/bin/env bash

# =============================================================================
# screenshot_batch.sh - Batch Screenshot Example
# =============================================================================
# Takes screenshots of multiple pages and saves them to a specified directory.
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

_create_screenshot_pages() {
    local tmpdir
    tmpdir=$(mktemp -d /tmp/shellnium-screenshots-XXXXXX)

    cat > "${tmpdir}/homepage.html" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Home Page</title>
<style>
  body { font-family: sans-serif; text-align: center; padding: 80px;
         background: linear-gradient(135deg, #667eea, #764ba2); color: white; }
  h1 { font-size: 3em; }
</style>
</head>
<body>
<h1>Welcome Home</h1>
<p>This is the landing page.</p>
</body>
</html>
HTMLEOF

    cat > "${tmpdir}/dashboard.html" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Dashboard</title>
<style>
  body { font-family: sans-serif; padding: 40px; background: #f5f5f5; }
  .card { background: white; border-radius: 8px; padding: 20px; margin: 10px;
          display: inline-block; width: 200px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
  .card h3 { margin-top: 0; }
  .number { font-size: 2em; color: #1976d2; }
</style>
</head>
<body>
<h1>Dashboard</h1>
<div class="card"><h3>Users</h3><div class="number">1,234</div></div>
<div class="card"><h3>Revenue</h3><div class="number">$56K</div></div>
<div class="card"><h3>Orders</h3><div class="number">892</div></div>
</body>
</html>
HTMLEOF

    cat > "${tmpdir}/about.html" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>About Us</title>
<style>
  body { font-family: sans-serif; max-width: 600px; margin: 40px auto;
         background: #fffde7; padding: 20px; }
  h1 { color: #f57f17; }
</style>
</head>
<body>
<h1>About Us</h1>
<p>We are a team building browser automation tools for the terminal.</p>
<p>Our mission is to make web testing accessible from any shell.</p>
</body>
</html>
HTMLEOF

    echo "$tmpdir"
}

OUTPUT_DIR="${SCRIPT_DIR}/../tmp/screenshots"

main() {
    local pages_dir
    pages_dir=$(_create_screenshot_pages)
    trap "rm -rf '$pages_dir'" EXIT

    local PAGES=(
        "file://${pages_dir}/homepage.html"
        "file://${pages_dir}/dashboard.html"
        "file://${pages_dir}/about.html"
    )

    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    echo "Screenshots will be saved to: ${OUTPUT_DIR}"
    echo "---"

    local count=0
    local total=${#PAGES[@]}

    for url in "${PAGES[@]}"; do
        count=$((count + 1))

        # Generate a filename from the HTML filename
        local filename
        filename=$(basename "$url" .html).png

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
