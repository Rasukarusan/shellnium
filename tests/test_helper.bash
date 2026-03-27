# Common setup for all tests
SHELLNIUM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source core functions without starting a session
source "${SHELLNIUM_DIR}/lib/core.sh"

# Mock BASE_URL for unit tests
export BASE_URL="http://localhost:9515/session/test-session-id"
