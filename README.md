# Shellnium

Shellnium is the selenium webdriver for Bash.
You can exec selenium simply on your terminal.

![demo](https://user-images.githubusercontent.com/17779386/85990922-aacbd080-ba2d-11ea-8e88-cc9b79075b31.gif)

## Bash Webdriver

```sh
#!/usr/bin/env bash
source ./selenium.sh

main() {
    # Open the URL
    navigate_to 'https://google.co.jp'

    # Get the search box
    local searchBox=$(find_element 'name' 'q')

    # send keys
    send_keys $searchBox "animal\n"
}

main
```

## Demo

```sh
$ git clone git@github.com:Rasukarusan/shellnium.git
$ cd shellnium
$ sh demo.sh

# or
$ sh demo2.sh
```

You can add chrome options. e.g. `--headless`.
```sh
$ sh demo.sh --headless --lang=es
```

`demo2.sh` is required iTerm2 and MacOS.

This script is headless and display chromedriver's behavior as iTerm's background.
The above GIF is `demo2.sh`.

## Requirements

- jq

## Todo

The bash webdriver `selenium.sh` is incomplete.
Here's what `selenium.sh` can currently do

- delete session
- open url
- find element
- send keys
- click element
- take a screenshot
- exec javascript

## Article

https://qiita.com/Rasukarusan/items/70a54bd38c71a07ff7bd

## Reference

- [WebDriver](https://www.w3.org/TR/webdriver/)

## LICENSE

MIT
