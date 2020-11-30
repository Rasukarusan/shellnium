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
`demo2.sh` is required iTerm2 and MacOS.

This script is headless and display chromedriver's behavior as iTerm's background.
The above GIF is `demo2.sh`.

You can add chrome options. e.g. `--headless`.
```sh
$ sh demo.sh --headless --lang=es
```


## Requirements

- jq

## Methods

Shellnium provides the following methods.
Document is [here]() or please see [core.sh](https://github.com/Rasukarusan/shellnium/blob/master/lib/core.sh).

### Session

- is_ready
- new_session
- delete_session

### Navigate

- navigate_to
- get_current_url
- get_title
- back
- forward
- refresh

### Timeouts

- get_timeouts
- set_timeouts
- set_timeout_script
- set_timeout_pageLoad
- set_timeout_implicit

### Element Retrieval

- find_element
- find_elements
- find_element_from_element
- find_elements_from_element
- get_active_element

### Element State

- get_attribute
- get_property
- get_css_value
- get_text
- get_tag_name
- get_rect
- is_element_enabled

### Element Interaction

- send_keys
- click
- element_clear

### Document

- exec_script
- screenshot

### Context

- get_window_handle
- get_window_handles
- delete_window
- new_window
- switch_to_window
- get_window_rect
- set_window_rect
- maximize_window
- minimize_window
- fullscreen_window

## Article

https://qiita.com/Rasukarusan/items/70a54bd38c71a07ff7bd

## Reference

- [WebDriver](https://www.w3.org/TR/webdriver/)

## LICENSE

MIT
