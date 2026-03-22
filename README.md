<p align="center">
  <a href="https://shellnium-site.vercel.app/" target="_blank">
    <img widht="500" height="auto" src="https://user-images.githubusercontent.com/17779386/112637471-8a785780-8e81-11eb-898f-c51e9deaba15.png">
  </a>
<br />

<img alt="" src="https://flat.badgen.net/github/stars/Rasukarusan/shellnium">
<a aria-label="License" href="https://github.com/Rasukarusan/shellnium/blob/master/LICENSE">
  <img alt="" src="https://flat.badgen.net/github/license/Rasukarusan/shellnium">
</a>
<img alt="" src="https://github.com/Rasukarusan/shellnium/actions/workflows/ci.yml/badge.svg">
</p>

# Shellnium

Shellnium is the Selenium WebDriver for Bash.
You can automate browser actions simply from your terminal.
**All you need is Bash or Zsh.**

```sh
#!/usr/bin/env bash
source ./selenium.sh

main() {
    # Open the URL
    navigate_to 'https://google.com'

    # Get the search box
    local searchBox=$(find_element 'name' 'q')

    # send keys
    send_keys $searchBox "panda\n"
}

main
```

<img src="https://shellnium-site.vercel.app/demo.gif" width="700" height="auto">

## Documentation

https://shellnium-site.vercel.app

If you learn by watching videos, check out this screencast by [@gotbletu](https://github.com/gotbletu) to explore `shellnium` features.

[![shellnium - Automate The Web Using Shell Scripts - Linux SHELL SCRIPT](https://img.youtube.com/vi/Q10dcPjmRTI/0.jpg)](https://www.youtube.com/watch?v=Q10dcPjmRTI)

## Installation

```bash
git clone https://github.com/Rasukarusan/shellnium.git
cd shellnium
```

### Requirements

- **bash** (4.0+) or **zsh**
- **curl**
- **[jq](https://stedolan.github.io/jq/)**
- **Google Chrome** / **Chromium**
- **[ChromeDriver](https://googlechromelabs.github.io/chrome-for-testing/)** (must match your Chrome version)

#### Install dependencies

**macOS:**
```bash
brew install jq
brew install --cask chromedriver
```

**Ubuntu / Debian:**
```bash
sudo apt-get install -y jq chromium-chromedriver
```

**Arch Linux:**
```bash
sudo pacman -S jq chromium
```

## Quick Start

```bash
# 1. Start ChromeDriver
chromedriver --port=9515

# 2. Run a demo script
bash demo.sh
```

You can pass Chrome options like `--headless`:
```sh
bash demo.sh --headless --lang=es
```

### Custom ChromeDriver URL

By default, Shellnium connects to `http://localhost:9515`. You can override this with an environment variable:

```bash
export SHELLNIUM_DRIVER_URL=http://localhost:4444
bash demo.sh
```

### Version Matching

Make sure your Chrome and ChromeDriver major versions match:
```bash
# Check Chrome version
google-chrome --version        # Linux
# /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version  # macOS

# Check ChromeDriver version
chromedriver --version
```

## Methods

Shellnium provides the following methods. See [document](https://shellnium-site.vercel.app) or [core.sh](https://github.com/Rasukarusan/shellnium/blob/master/lib/core.sh) for details.

### Session

- `is_ready`
- `new_session`
- `delete_session`
- `get_all_cookies` / `get_named_cookie` / `add_cookie` / `delete_cookie` / `delete_all_cookies`

### Navigate

- `navigate_to` / `get_current_url` / `get_title`
- `back` / `forward` / `refresh`

### Timeouts

- `get_timeouts` / `set_timeouts`
- `set_timeout_script` / `set_timeout_pageLoad` / `set_timeout_implicit`

### Element Retrieval

- `find_element` / `find_elements`
- `find_element_from_element` / `find_elements_from_element`
- `get_active_element`

### Element State

- `get_attribute` / `get_property` / `get_css_value`
- `get_text` / `get_tag_name` / `get_rect`
- `is_element_enabled`

### Element Interaction

- `send_keys` / `click` / `element_clear`

### Document

- `get_source` / `exec_script`
- `screenshot` / `element_screenshot`

### Context

- `get_window_handle` / `get_window_handles`
- `new_window` / `delete_window` / `switch_to_window`
- `switch_to_frame` / `switch_to_parent_frame`
- `get_window_rect` / `set_window_rect`
- `maximize_window` / `minimize_window` / `fullscreen_window`

### Alerts

- `get_alert_text` / `send_alert_text`
- `accept_alert` / `dismiss_alert`

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Article

English
https://dev.to/rasukarusan/shellnium-simple-selnium-webdriver-for-bash-1a9k

Japanese
https://qiita.com/Rasukarusan/items/70a54bd38c71a07ff7bd

## Example

<img src="https://shellnium-site.vercel.app/demo2.gif" width="700" height="auto">

```sh
bash demo2.sh
```
`demo2.sh` requires iTerm2 and macOS.

This script is headless and displays ChromeDriver's behavior as iTerm's background with AppleScript.

## Reference

- [W3C WebDriver Specification](https://www.w3.org/TR/webdriver/)

## LICENSE

MIT
