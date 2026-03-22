#!/usr/bin/env bash

# =============================================================================
# ci_smoke_test.sh - CI/CD Smoke Test Example
# =============================================================================
# A minimal smoke test suite that can be integrated into CI/CD pipelines.
# Checks if critical pages load correctly and contain expected content.
# Exits with code 0 on success, 1 on any failure.
#
# Usage:
#   bash examples/ci_smoke_test.sh --headless
#
# Environment variables:
#   BASE_SITE_URL  - Base URL to test (default: https://example.com)
# =============================================================================

SCRIPT_DIR="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]:-${0}}")")" &>/dev/null && pwd)"
source "${SCRIPT_DIR}/../lib/selenium.sh"

BASE_SITE_URL="${BASE_SITE_URL:-https://example.com}"

PASSED=0
FAILED=0

# Run a single test case
# Arguments: test_name, url_path, expected_title_substring
run_test() {
    local test_name=$1
    local url_path=$2
    local expected=$3

    local full_url="${BASE_SITE_URL}${url_path}"
    printf "  %-40s" "${test_name}..."

    navigate_to "$full_url"
    sleep 1

    local title
    title=$(get_title)

    if echo "$title" | grep -qi "$expected"; then
        echo "PASS (title: ${title})"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL (expected '${expected}' in title, got '${title}')"
        FAILED=$((FAILED + 1))
    fi
}

# Check that a page returns non-empty content
check_page_loads() {
    local test_name=$1
    local url_path=$2

    local full_url="${BASE_SITE_URL}${url_path}"
    printf "  %-40s" "${test_name}..."

    navigate_to "$full_url"
    sleep 1

    local source
    source=$(get_source | jq -r '.value')

    if [ -n "$source" ] && [ ${#source} -gt 100 ]; then
        echo "PASS (page loaded, ${#source} chars)"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL (page empty or too small)"
        FAILED=$((FAILED + 1))
    fi
}

main() {
    echo "========================================"
    echo "  Smoke Test Suite"
    echo "  Target: ${BASE_SITE_URL}"
    echo "========================================"
    echo ""

    echo "Running tests..."
    echo ""

    # Test 1: Homepage loads and has expected title
    run_test "Homepage title check" "/" "Example Domain"

    # Test 2: Homepage has content
    check_page_loads "Homepage content check" "/"

    # Test 3: Check a specific element exists on the page
    printf "  %-40s" "Homepage has heading..."
    navigate_to "${BASE_SITE_URL}/"
    sleep 1
    local heading
    heading=$(find_element 'tag name' 'h1')
    local heading_text
    heading_text=$(get_text "$heading")
    if [ -n "$heading_text" ]; then
        echo "PASS (h1: ${heading_text})"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL (no h1 found)"
        FAILED=$((FAILED + 1))
    fi

    # Print summary
    echo ""
    echo "========================================"
    echo "  Results: ${PASSED} passed, ${FAILED} failed"
    echo "========================================"

    # Clean up
    delete_session

    # Exit with appropriate code for CI
    if [ "$FAILED" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

main
