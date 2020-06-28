#!/usr/bin/env bash
get_session_id() {
    curl -s -X POST -H 'Content-Type: application/json' \
        -d '{
            "desiredCapabilities": {
                "browserName": "chrome"
            }
        }' \
        ${ROOT}/session | jq -r '.sessionId'
}

ROOT=http://localhost:9515
SESSION_ID=$(get_session_id)
BASE_URL=${ROOT}/session/${SESSION_ID}


navigate_to() {
    local url=$1
    curl -s -X POST -H 'Content-Type: application/json' -d '{"url":"'${url}'"}' ${BASE_URL}/url
}

find_element() {
    local property=$1
    local value=$2
    curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"using":"'$property'", "value": "'$value'"}' ${BASE_URL}/element | jq -r '.value.ELEMENT'
}

send_keys() {
    local elementId=$1
    local value=$2
    curl -s -X POST -H 'Content-Type: application/json' \
    -d '{"value": ["'$value'"]}' ${BASE_URL}/element/${elementId}/value >/dev/null
}

