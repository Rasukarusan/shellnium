#!/usr/bin/env bash
set -e

CMD="${1:-demo.sh}"
shift 2>/dev/null || true

# Run bats tests
if [ "$CMD" = "test" ] || [ "$CMD" = "bats" ]; then
    exec bats /opt/shellnium/tests/ "$@"
fi

# Run shellcheck
if [ "$CMD" = "shellcheck" ] || [ "$CMD" = "lint" ]; then
    exec shellcheck -s bash /opt/shellnium/lib/*.sh "$@"
fi

# If the script path is not absolute, look for it in /opt/shellnium or /app
if [[ "$CMD" != /* ]]; then
    if [ -f "/opt/shellnium/$CMD" ]; then
        CMD="/opt/shellnium/$CMD"
    elif [ -f "/app/$CMD" ]; then
        CMD="/app/$CMD"
    fi
fi

if [ ! -f "$CMD" ]; then
    echo "Error: Script not found: $CMD" >&2
    exit 1
fi

# Pass SHELLNIUM_CHROME_OPTS as Chrome flags and any extra arguments
echo "[shellnium] Running: $(basename "$CMD")"
bash "$CMD" $SHELLNIUM_CHROME_OPTS "$@"
echo "[shellnium] Done (exit code: $?)"
