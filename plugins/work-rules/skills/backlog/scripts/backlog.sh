#!/bin/bash
# Backlog を読み取り専用で参照する入口。通信は backlog_api.py が GET だけで行う。
# 使い方: backlog.sh help
# API キーは macOS のキーチェーン（サービス名 claude-backlog、アカウント名はスペースのドメイン）に置く。
# キーをコマンドの引数に載せない。
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd -P)"
API="$DIR/backlog_api.py"
SERVICE="claude-backlog"

usage() {
  cat <<'EOF'
使い方: backlog.sh <サブコマンド> ...

  auth status [<domain>]
      キーチェーンへの登録の有無と、自分のユーザー情報の API（users/myself）が通るかを表示する（ユーザー名だけを表示する）。
      ドメインを省くと、登録を記録したドメインをすべて確かめる。
  auth add <domain>
      利用者が端末で API キーを入力して登録する（入力は表示されない）。Claude は実行しない。
  auth import <domain> --from-service <サービス名> --from-account <アカウント名>
      キーチェーンの別の項目に置いた API キーを claude-backlog の項目へ写す（移行用。値は表示しない）。
      写し元の値が「<ドメイン> <API キー>」の形ならドメインを照合してキーだけを写す。
  projects <domain>
      参照できるプロジェクトの一覧を表示する。
  issues <domain> --project <KEY> [--keyword <語>] [--status <状態名[,状態名...]|未完了>] [--count N]
      課題を最終更新の新しい順に表示する（既定 20 件、上限 500 件）。
  issue <domain> <課題キー>
      件名・状態・担当・期限・本文・全コメントを Markdown で表示する。
  comments <domain> <課題キー>
      全コメントを古い順に表示する。

<domain> は example.backlog.com / example.backlog.jp の形で指定する。
終了コード: 0 成功 / 1 失敗 / 2 引数の誤り / 3 認証の失敗・未登録 / 4 見つからない
EOF
}

run_api() { exec /usr/bin/env python3 -I "$API" "$@"; }

auth_add() {
  local domain="${1:-}"
  if [ "$#" -ne 1 ] || [ -z "$domain" ]; then
    echo "ERROR: 使い方: backlog.sh auth add <domain>" >&2
    exit 2
  fi
  domain="$(printf '%s' "$domain" | tr 'A-Z' 'a-z')"
  if ! printf '%s' "$domain" | grep -Eq '^[a-z0-9]([a-z0-9-]*[a-z0-9])?\.(backlog\.com|backlog\.jp|backlogtool\.com)$'; then
    echo "ERROR: スペースのドメインを解釈できない: $domain" >&2
    exit 2
  fi
  if [ ! -t 0 ]; then
    echo "ERROR: auth add は端末から利用者が実行する（API キーを対話で入力するため）。" >&2
    exit 2
  fi
  echo "Backlog の「個人設定 > API」で発行した API キーを入力する（入力は表示されない。確認のため2回求められる）。" >&2
  # -w を末尾に置くと、security が値を対話で尋ねる。値はコマンドの引数に載らない。
  security add-generic-password -U -s "$SERVICE" -a "$domain" -w
  /usr/bin/env python3 -I "$API" auth record "$domain"
  /usr/bin/env python3 -I "$API" auth status "$domain"
}

[ "$#" -ge 1 ] || { usage; exit 2; }
case "$1" in
  help | -h | --help) usage ;;
  auth)
    case "${2:-}" in
      add) shift 2; auth_add "$@" ;;
      status | import) run_api "$@" ;;
      *) echo "ERROR: auth のサブコマンドは status / add / import のいずれかを指定する。" >&2; exit 2 ;;
    esac
    ;;
  projects | issues | issue | comments) run_api "$@" ;;
  *) echo "ERROR: サブコマンドが不正: $1（backlog.sh help で一覧を表示する）" >&2; exit 2 ;;
esac
