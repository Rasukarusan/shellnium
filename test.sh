#!/usr/bin/env bash
source ./selenium.sh

main() {
    curl -s -X POST -H 'Content-Type: application/json' -d '{"width": 750,"height": 1000}' ${BASE_URL}/window/rect
    # Googleのトップページに遷移
    navigate_to 'https://google.co.jp'

    # 検索ボックスの要素を取得
    local searchBox=$(find_element 'name' 'q')

    # 検索ボックスに入力＆検索実行
    send_keys $searchBox "タピオカ\n"
}

main

