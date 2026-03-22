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

### Linting

```bash
# ShellCheck on library files
shellcheck -s bash lib/*.sh

# All scripts (lib + setup scripts)
shellcheck -s bash lib/*.sh scripts/*.sh
```

### Testing

```bash
# Run all Bats tests (includes syntax + ShellCheck validation)
bats --recursive tests/
```

### Docker

```bash
# Build image
docker build -t shellnium:local .

# Run demo in headless mode
docker run --rm --shm-size=2g shellnium:local demo.sh

# Run ShellCheck + tests inside container
docker run --rm shellnium:local shellcheck
docker run --rm shellnium:local test
```

### Claude Code on the Web での開発

クラウドサンドボックス環境（Claude Code on the Web）では ShellCheck・Bats・Docker がプリインストールされていないため、最初にセットアップが必要。

```bash
# 1. 環境セットアップ（ShellCheck + Bats インストール、Docker デーモン起動）
SANDBOX=1 bash scripts/sandbox-setup.sh

# 2. リント（ShellCheck）
shellcheck -s bash -e SC1091 lib/*.sh

# 3. テスト（Bats）
bats --recursive tests/

# 4. Docker でコンテナ内テスト（オプション）
docker build -t shellnium:local .
docker run --rm shellnium:local test
docker run --rm shellnium:local shellcheck
```

**注意点:**
- `scripts/sandbox-setup.sh` は環境変数 `CLAUDE_CODE_REMOTE=true` または `SANDBOX=1` で実行される
- Docker デーモンは起動できるが、**`docker build` はネットワーク制限（DNS解決不可）で失敗する**。コンテナ内から外部リポジトリ（`deb.debian.org` 等）にアクセスできない
- そのため Docker テストは CI（GitHub Actions）で実行し、サンドボックスでは ShellCheck と Bats をホスト側で直接実行する
- Docker は `--storage-driver=vfs` で起動される（サンドボックスの制約）
- iptables は legacy モードに切り替えられる（Docker 起動に必要）
- セットアップログは `/tmp/shellnium-setup/` に出力される

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
