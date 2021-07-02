<p align="center">
<img widht="500" height="auto" src="https://user-images.githubusercontent.com/17779386/112637471-8a785780-8e81-11eb-898f-c51e9deaba15.png">
<br />

<img alt="" src="https://flat.badgen.net/github/stars/Rasukarusan/shellnium">
<a aria-label="License" href="https://github.com/Rasukarusan/shellnium/blob/master/LICENSE">
  <img alt="" src="https://flat.badgen.net/github/license/Rasukarusan/shellnium">
</a>
</p>

# Shellnium

Shellnium is the selenium WebDriver for Bash.  
You can exec selenium simply on your terminal.
**All you need is Bash or Zsh.**

![demo](https://user-images.githubusercontent.com/17779386/85990922-aacbd080-ba2d-11ea-8e88-cc9b79075b31.gif)

If you learn by watching videos, check out this screencast by [@gotbletu](https://github.com/gotbletu) to explore `shellnium` features.

[![shellnium - Automate The Web Using Shell Scripts - Linux SHELL SCRIPT](https://img.youtube.com/vi/Q10dcPjmRTI/0.jpg)](https://www.youtube.com/watch?v=Q10dcPjmRTI)

## Bash WebDriver

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

## Usage

### 1. Run ChromeDriver
```sh
$ chromedriver
```
If you don't install `chromedriver`, you can install by `homebrew`.
```sh
brew install chromedriver
```

**Make sure you have the right version of ChromeDriver and GoogleChrome.**
```sh
# check the version of Google Chrome
# ex. MacOS
$ /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version
Google Chrome 89.0.4389.82

# check the version of ChromeDriver
$ chromedriver --version
ChromeDriver 89.0.4389.23 (61b08ee2c50024bab004e48d2b1b083cdbdac579-refs/branch-heads/4389@{#294})
```

### 2. Exec demo.sh
```sh
$ git clone git@github.com:Rasukarusan/shellnium.git
$ cd shellnium
$ sh demo.sh
```

You can add chrome options. e.g. `--headless`.
```sh
$ sh demo.sh --headless --lang=es
```

### Bonus Script
```sh
$ sh demo2.sh
```
`demo2.sh` is required iTerm2 and Mac OS.

This script is headless and display chromedriver's behavior as iTerm's background.
The above GIF is `demo2.sh`.


## Requirements

- jq

## Methods

Shellnium provides the following methods.
Document is [here](https://github.com/Rasukarusan/shellnium/blob/master/doc.md) or please see [core.sh](https://github.com/Rasukarusan/shellnium/blob/master/lib/core.sh).

### セッション

- is_ready
- new_session
- delete_session
- get_cookies
- set_cookies

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

English
https://dev.to/rasukarusan/shellnium-simple-selnium-webdriver-for-bash-1a9k

Japanese
https://qiita.com/Rasukarusan/items/70a54bd38c71a07ff7bd

## Reference

- [WebDriver](https://www.w3.org/TR/webdriver/)

## LICENSE

MIT
