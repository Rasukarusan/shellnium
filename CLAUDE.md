# CLAUDE.md

## Project Overview

Shellnium is a Selenium WebDriver implementation for Bash/Zsh. It enables browser automation directly from the terminal using W3C WebDriver protocol over curl + jq.

## Repository Structure

- `lib/` — Core library (core.sh, setup.sh, selenium.sh, util.sh)
- `tests/` — Bats test suite (unit tests + syntax/shellcheck validation)
- `examples/` — Practical usage examples (scraping, form fill, login, etc.)
- `demo.sh`, `demo2.sh`, `demo3.sh` — Demo scripts
- `scripts/` — CI/sandbox setup scripts

## Common Commands

### Bootstrap

```bash
# Install optional local runtime dependencies for running demos on the host
make bootstrap
```

### Linting

```bash
# ShellCheck on repository shell scripts
make lint
```

### Testing

```bash
# Run the standard Docker-first verification pipeline
make ci

# Run lint and tests locally only if the host already has shellcheck and bats
make ci-local
```

### Docker

```bash
# Build image
make docker-build

# Run ShellCheck + tests inside container
make docker-test

# Run browser smoke test inside container
make docker-smoke
```

### Claude Code on the Web

ShellCheck and Bats are not pre-installed in the cloud sandbox environment (Claude Code on the Web). Run the setup script first.

```bash
# 1. Setup (install ShellCheck + Bats)
SANDBOX=1 bash scripts/sandbox-setup.sh

# 2. Standard verification
make ci
```

**Notes:**
- `scripts/sandbox-setup.sh` runs when the env var `CLAUDE_CODE_REMOTE=true` or `SANDBOX=1` is set
- Docker is unavailable in the sandbox due to network restrictions. Run Docker tests in CI (GitHub Actions) instead
- Setup logs are written to `/tmp/shellnium-setup/`

## Code Style

- Quote all variable expansions: `"${var}"` not `$var`
- Use `local` for function-scoped variables
- Use snake_case for function names
- No stray `echo` debug output
- Shell dialect: Bash (`-s bash` for ShellCheck)
- Exclude SC1091 (source not followed) in ShellCheck: `shellcheck -s bash -e SC1091`

## Architecture Notes

- `lib/selenium.sh` is the entry point — scripts `source ./selenium.sh` to load the library
- `lib/core.sh` implements W3C WebDriver commands via curl (GET/POST/DELETE to ChromeDriver)
- `lib/setup.sh` handles automatic ChromeDriver download and lifecycle management
- ChromeDriver is auto-downloaded to `~/.cache/shellnium/` and started on port 9515
- CI runs ShellCheck + Bats via GitHub Actions (`.github/workflows/ci.yml`)
- `Makefile` is the canonical automation entrypoint for humans and agents
