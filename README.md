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

    # Send keys and press Enter
    send_keys $searchBox "panda${KEY_ENTER}"
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
- **[unzip](https://infozip.sourceforge.net/UnZip.html)**
- **Google Chrome** / **Chromium**

ChromeDriver is **automatically downloaded and managed** by Shellnium. You don't need to install it manually.

#### Install dependencies

**macOS:**
```bash
brew install jq
```

**Ubuntu / Debian:**
```bash
sudo apt-get install -y jq unzip
```

**Arch Linux:**
```bash
sudo pacman -S jq unzip
```

## Quick Start

```bash
# Just run it — ChromeDriver is set up automatically!
bash demo.sh
```

## Development

For local development and agent-driven verification, use the standardized `make` targets:

```bash
# Run the standard Docker-first verification pipeline
make ci
```

`make ci` runs local syntax checks, then runs ShellCheck and Bats inside Docker. You do not need local `shellcheck` or `bats` installations.

If you want to run demos locally, install the optional runtime dependencies:

```bash
make bootstrap
```

Available targets:

- `make syntax` - bash syntax checks for tracked scripts
- `make lint` - ShellCheck on library, example, and helper scripts
- `make test` - Bats unit and syntax tests
- `make smoke` - headless browser smoke example
- `make docker-test` - lint and test in Docker
- `make docker-smoke` - smoke test in Docker
- `make ci-local` - local lint and test for users who already have the tools installed

If you are using an AI coding agent, start with the instructions in [`AGENTS.md`](AGENTS.md).

### Docker

Run Shellnium instantly without installing Chrome or ChromeDriver locally:

```bash
# Run the demo
docker run --rm --shm-size=2g ghcr.io/rasukarusan/shellnium demo.sh

# Run your own script
docker run --rm --shm-size=2g -v ./my_script.sh:/app/my_script.sh ghcr.io/rasukarusan/shellnium my_script.sh

# Using docker compose
docker compose run --rm shellnium
```

Or build locally:

```bash
docker build -t shellnium .
docker run --rm --shm-size=2g shellnium demo.sh
```

You can also run ShellCheck and unit tests inside the container:

```bash
# Run the container-based verification flow
make docker-test
```

You can pass Chrome options like `--headless`:
```sh
bash demo.sh --headless --lang=es
```

ChromeDriver is automatically downloaded to `~/.cache/shellnium/` and started on port 9515. When your script finishes, ChromeDriver is stopped automatically.

### Configuration

| Environment Variable | Default | Description |
|---|---|---|
| `SHELLNIUM_HEADLESS` | (unset) | Set to `true` or `1` to enable headless mode (no visible browser window) |
| `SHELLNIUM_DRIVER_URL` | `http://localhost:9515` | Custom ChromeDriver URL (disables auto-setup) |
| `SHELLNIUM_PORT` | `9515` | Port for auto-started ChromeDriver |
| `SHELLNIUM_CACHE_DIR` | `~/.cache/shellnium` | Cache directory for downloaded ChromeDriver |

### Headless Mode

Headless mode runs Chrome without a visible browser window, which is essential for CI/CD pipelines and server-side automation.

```bash
# Enable headless mode via environment variable
SHELLNIUM_HEADLESS=true bash demo.sh

# Or export it for the entire session
export SHELLNIUM_HEADLESS=true
bash demo.sh
```

You can also pass `--headless` directly as a Chrome option (e.g., `bash demo.sh --headless`), but the environment variable is recommended for CI/CD environments.

#### GitHub Actions Example

```yaml
name: Browser Automation
on: [push]

jobs:
  automate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: sudo apt-get install -y jq unzip google-chrome-stable
      - name: Run automation script
        env:
          SHELLNIUM_HEADLESS: true
        run: bash demo.sh
```

## Examples

The [`examples/`](examples/) directory contains practical scripts demonstrating common use cases:

| Script | Description |
|---|---|
| [scraping.sh](examples/scraping.sh) | Extract data from web pages (scrapes Hacker News top stories) |
| [form_fill.sh](examples/form_fill.sh) | Auto-fill and submit HTML forms |
| [login.sh](examples/login.sh) | Automate login flow with cookie saving |
| [screenshot_batch.sh](examples/screenshot_batch.sh) | Take screenshots of multiple URLs in batch |
| [ci_smoke_test.sh](examples/ci_smoke_test.sh) | CI/CD smoke test suite with pass/fail reporting |
| [multi_tab.sh](examples/multi_tab.sh) | Open, switch between, and manage multiple browser tabs |

Run any example:
```bash
# With browser window
bash examples/scraping.sh

# Headless mode
bash examples/scraping.sh --headless
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

### Key Constants

Use these constants with `send_keys` to send special keys:

```bash
send_keys $element "hello${KEY_ENTER}"    # Type "hello" then press Enter
send_keys $element "${KEY_TAB}"           # Press Tab
```

| Constant | Key |
|---|---|
| `KEY_BACKSPACE` | Backspace |
| `KEY_TAB` | Tab |
| `KEY_RETURN` | Return |
| `KEY_ENTER` | Enter |
| `KEY_SHIFT` | Shift |
| `KEY_CONTROL` | Control |
| `KEY_ALT` | Alt |
| `KEY_ESCAPE` | Escape |
| `KEY_SPACE` | Space |
| `KEY_ARROW_LEFT` / `KEY_ARROW_UP` / `KEY_ARROW_RIGHT` / `KEY_ARROW_DOWN` | Arrow keys |

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

### Actions

Perform low-level mouse and keyboard actions using the [W3C WebDriver Actions API](https://www.w3.org/TR/webdriver/#actions).

- `perform_actions` / `release_actions` — low-level actions API
- **Mouse:** `mouse_move_to` / `double_click` / `right_click` / `hover` / `drag_and_drop`
- **Keyboard:** `key_press` / `key_down` / `key_up` / `send_key_combo`

Key constants are available for keyboard actions (e.g., `$KEY_CONTROL`, `$KEY_SHIFT`, `$KEY_ENTER`, `$KEY_TAB`, `$KEY_ESCAPE`, `$KEY_ARROW_DOWN`, etc.).

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
