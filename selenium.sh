#!/usr/bin/env bash
GET='curl -s -X GET'
POST='curl -s -X POST -H "Content-Type: application/json"'
ROOT=http://localhost:9515

is_ready() {
    $GET ${ROOT}/status | jq -r '.value.ready'
}

get_version_google_chrome() {
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version
}

get_version_chromedriver() {
  chromedriver --version
}

if [ "$(is_ready)" != 'true' ]; then
    echo "[ERROR] chromedriver is not running."
    exit
fi

chromeOptions=$(for i in $@; do printf "\"${i}\",";done | sed 's/,$//')

sessionId=$(curl -s -X POST -H 'Content-Type: application/json' \
    -d '{
            "desiredCapabilities": {
                "browserName":"chrome",
                "chromeOptions": {"args": ['${chromeOptions}'] }
            }
        }' \
    ${ROOT}/session | jq -r '.sessionId')
BASE_URL=${ROOT}/session/$sessionId

delete_session() {
    curl -s -X DELETE ${BASE_URL} > /dev/null
}

navigate_to() {
    local url=$1
    $POST -d '{"url":"'${url}'"}' ${BASE_URL}/url >/dev/null
}

find_element() {
    local property=$1
    local value=$2
    $POST -d '{"using":"'$property'", "value": "'$value'"}' ${BASE_URL}/element | jq -r '.value.ELEMENT'
}

send_keys() {
    local elementId=$1
    local value=$2
    $POST -d "{\"value\": [\"${value}\"]}" ${BASE_URL}/element/${elementId}/value >/dev/null
}

click() {
    local elementId=$1
    $POST ${BASE_URL}/element/${elementId}/click >/dev/null
}

screenshot() {
    local path=${1:-./screenshot.png}
    $GET ${BASE_URL}/screenshot | jq -r '.value' | base64 -d > $path
}

exec_sync_script() {
    $POST -d '{"script": "'$1'", "args":['"$2"']}' ${BASE_URL}/execute/sync >/dev/null
}
