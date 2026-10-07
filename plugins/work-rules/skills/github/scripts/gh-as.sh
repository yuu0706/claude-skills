#!/bin/bash
# 指定したアカウントのトークンで gh を1回だけ実行する。gh 全体の有効なアカウントは切り替えない。
# 使い方: gh-as.sh <アカウント> <gh の引数...>
#   例: gh-as.sh example-user issue list -R example-user/example-repo --limit 1
# トークンは gh auth token --user で受け取り、環境変数 GH_TOKEN でこのコマンドにだけ渡す。表示しない。
# 読み取り専用の道具として、書き込みに当たる明らかな呼び出しは拒む（拒否は完全ではない。最終的な判断は呼び出す側が行う）。
# 終了コード: gh の終了コード / 2 引数の誤り・拒否 / 3 アカウントのトークンを取得できない
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "使い方: gh-as.sh <アカウント> <gh の引数...>" >&2
  exit 2
fi
account="$1"
shift
case "$account" in
  '' | -* | *[!A-Za-z0-9-]*) echo "ERROR: アカウント名が不正: $account" >&2; exit 2 ;;
esac

deny() { echo "ERROR: 書き込みに当たる呼び出しは扱わない: gh $*" >&2; exit 2; }

# 書き込みに当たるサブコマンドを拒む。
case "${1:-} ${2:-}" in
  "auth "* | "config set"* | "secret "* | "variable "* | "ssh-key "* | "gpg-key "*) deny "$@" ;;
  "issue create"* | "issue edit"* | "issue close"* | "issue reopen"* | "issue delete"* | "issue comment"* | \
  "issue lock"* | "issue unlock"* | "issue pin"* | "issue unpin"* | "issue transfer"* | "issue develop"*) deny "$@" ;;
  "pr create"* | "pr edit"* | "pr close"* | "pr reopen"* | "pr merge"* | "pr comment"* | "pr review"* | \
  "pr ready"* | "pr checkout"* | "pr lock"* | "pr unlock"* | "pr update-branch"* | "pr revert"*) deny "$@" ;;
  "repo create"* | "repo edit"* | "repo delete"* | "repo fork"* | "repo rename"* | "repo archive"* | \
  "repo unarchive"* | "repo sync"* | "repo set-default"* | "repo deploy-key"* | "repo autolink"*) deny "$@" ;;
  "run rerun"* | "run cancel"* | "run delete"* | "workflow run"* | "workflow enable"* | "workflow disable"* | \
  "release create"* | "release edit"* | "release delete"* | "release upload"* | "label create"* | \
  "label edit"* | "label delete"* | "label clone"* | "gist create"* | "gist edit"* | "gist delete"* | \
  "cache delete"* | "project "* | "codespace "* | "extension "* | "alias "*) deny "$@" ;;
esac

# gh api は GET だけを許す。本文を付ける指定は既定のメソッドが POST になるため拒む。
if [ "$1" = "api" ]; then
  expect_method=""
  for arg in "$@"; do
    if [ -n "$expect_method" ]; then
      [ "$(printf '%s' "$arg" | tr 'a-z' 'A-Z')" = "GET" ] || deny "$@"
      expect_method=""
      continue
    fi
    case "$arg" in
      -X | --method) expect_method=1 ;;
      -X* | --method=*)
        value="${arg#-X}"; value="${value#--method=}"
        [ "$(printf '%s' "$value" | tr 'a-z' 'A-Z')" = "GET" ] || deny "$@"
        ;;
      -f | -F | --field | --raw-field | --input | -f* | -F* | --field=* | --raw-field=* | --input=*) deny "$@" ;;
      graphql) deny "$@" ;;
    esac
  done
  [ -z "$expect_method" ] || deny "$@"
fi

if ! token="$(gh auth token --user "$account" 2>/dev/null)" || [ -z "$token" ]; then
  echo "ERROR: アカウント $account のトークンを取得できない。gh auth status で、ログイン済みのアカウントを確かめる。" >&2
  exit 3
fi
GH_TOKEN="$token" exec gh "$@"
