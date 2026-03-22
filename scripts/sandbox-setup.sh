#!/usr/bin/env bash
# Claude Code on the Web（クラウドサンドボックス）環境の自動セットアップスクリプト
# SessionStart Hook から呼び出されることを想定
#
# 環境判定:
#   CLAUDE_CODE_REMOTE=true  → Claude Code on the Web のクラウド環境
#   SANDBOX=1                → 手動で強制実行する場合
#
# 機能:
#   - Docker デーモン起動
#   - ShellCheck によるシェルスクリプトの静的解析
#   - Bats によるテスト実行
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="/tmp/shellnium-setup"
mkdir -p "$LOG_DIR"

# カラー出力
green() { echo -e "\033[32m✓ $*\033[0m"; }
yellow() { echo -e "\033[33m⏳ $*\033[0m"; }
red() { echo -e "\033[31m✗ $*\033[0m"; }
info() { echo -e "\033[36mℹ $*\033[0m"; }

# ==============================================================================
# 1. Claude Code on the Web 環境判定
# ==============================================================================
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ] && [ -z "${SANDBOX:-}" ]; then
  info "Claude Code on the Web 環境ではありません。SANDBOX=1 を設定して強制実行できます。"
  exit 0
fi

# ==============================================================================
# 2. iptables を legacy に切り替え（Docker 用）
# ==============================================================================
if command -v update-alternatives &>/dev/null; then
  yellow "iptables を legacy モードに切り替え中..."
  sudo update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || true
  sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true
  green "iptables 設定完了"
fi

# ==============================================================================
# 3. Docker デーモン起動
# ==============================================================================
if ! docker info &>/dev/null; then
  yellow "Docker デーモンを起動中..."
  sudo -E dockerd --iptables=false --bridge=none --storage-driver=vfs &>"$LOG_DIR/dockerd.log" &
  # デーモン起動待ち（最大30秒）
  for i in $(seq 1 30); do
    if docker info &>/dev/null; then
      break
    fi
    sleep 1
  done
  if docker info &>/dev/null; then
    green "Docker デーモン起動完了"
  else
    red "Docker デーモンの起動に失敗しました。ログ: $LOG_DIR/dockerd.log"
    exit 1
  fi
else
  green "Docker デーモンは既に起動済み"
fi

# ==============================================================================
# 4. Docker イメージのビルド
# ==============================================================================
yellow "Docker イメージをビルド中..."
cd "$PROJECT_ROOT"
if docker build -t shellnium:local . 2>"$LOG_DIR/docker-build.log"; then
  green "Docker イメージビルド完了"
else
  red "Docker イメージのビルドに失敗しました。ログ: $LOG_DIR/docker-build.log"
  cat "$LOG_DIR/docker-build.log" >&2
  exit 1
fi

# ==============================================================================
# 5. ShellCheck（静的解析）
# ==============================================================================
yellow "ShellCheck を実行中..."
SHELLCHECK_EXIT=0
docker run --rm -v "$PROJECT_ROOT:/app:ro" shellnium:local shellcheck 2>"$LOG_DIR/shellcheck.log" || SHELLCHECK_EXIT=$?
if [ "$SHELLCHECK_EXIT" -eq 0 ]; then
  green "ShellCheck: すべてのスクリプトが正常"
else
  red "ShellCheck: 問題が見つかりました（exit code: $SHELLCHECK_EXIT）"
  cat "$LOG_DIR/shellcheck.log" >&2
fi

# ==============================================================================
# 6. Bats テスト実行
# ==============================================================================
yellow "Bats テストを実行中..."
BATS_EXIT=0
docker run --rm -v "$PROJECT_ROOT:/app:ro" shellnium:local test 2>"$LOG_DIR/bats.log" || BATS_EXIT=$?
if [ "$BATS_EXIT" -eq 0 ]; then
  green "Bats テスト: すべてパス"
else
  red "Bats テスト: 失敗あり（exit code: $BATS_EXIT）"
  cat "$LOG_DIR/bats.log" >&2
fi

# ==============================================================================
# 完了
# ==============================================================================
echo ""
if [ "$SHELLCHECK_EXIT" -eq 0 ] && [ "$BATS_EXIT" -eq 0 ]; then
  green "サンドボックスセットアップ完了！すべてのチェックに成功しました。"
else
  yellow "サンドボックスセットアップ完了（一部チェックに失敗があります）"
  exit 1
fi
