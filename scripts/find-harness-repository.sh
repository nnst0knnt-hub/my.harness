#!/bin/bash
# 渡したフォルダーが、このスクリプトを置いたハーネスのリポジトリかそのworktreeの中かを、メインの作業フォルダーどうしを比べて決め、終了コードで返す。worktreeの中でメインのクローンのスクリプトを動かしても、同じリポジトリと見分けるためである。
# 終了コードは、0がハーネスのリポジトリの中、1がほかのリポジトリかgitの外、2が使い方の誤りか、scripts/print-main-worktree-path.shが動かず決められない、である。
# scripts/print-word-list.shが確かめる語を止めるかを決めるために呼び、エージェントがadd-ruleとconfigure-repositoryの手順で、ハーネスのリポジトリかを見分けるために呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 渡したフォルダーのメインの作業フォルダーを、scripts/print-main-worktree-path.shで求めて出す。
# 引数：フォルダーのパス
# 出力：メインの作業フォルダーのパス。決められないときの誤りは標準エラーに
# 戻り値：求められたら0、gitの外かメインの作業フォルダーを求められなければ1、print-main-worktree-path.shが動かなければ2
print_main_path() {
  local status
  "${BASH}" "${SCRIPT_DIRECTORY}/print-main-worktree-path.sh" "$1" 2> /dev/null
  status=$?
  # 1のほかの失敗（例：ファイルが無く127）を外と分ける。外とすると、ハーネスのリポジトリで確かめる語が黙って止まらなくなるためである。
  if [ "${status}" -gt 1 ]; then
    printf 'find-harness-repository.sh: scripts/print-main-worktree-path.shが終了コード%sで終わり、%sがハーネスのリポジトリの中かを決められませんでした。ハーネスのscripts/に、print-main-worktree-path.shがあり読めるかを確かめてください。\n' "${status}" "$1" >&2
    return 2
  fi
  return "${status}"
}

main() {
  local here harness
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'find-harness-repository.sh: フォルダーを1つだけ渡してください。ハーネスのリポジトリの中かを決めるフォルダーを、引数に渡してください。' >&2
    exit 2
  fi
  # gitの外と、メインの作業フォルダーを求められないリポジトリ（例：bareのリポジトリ）は、ハーネスのリポジトリの外とする。
  here="$(print_main_path "$1")" || exit "$?"
  harness="$(print_main_path "${SCRIPT_DIRECTORY}/..")" || exit "$?"
  if [ "${here}" != "${harness}" ]; then
    exit 1
  fi
  exit 0
}

main "$@"
