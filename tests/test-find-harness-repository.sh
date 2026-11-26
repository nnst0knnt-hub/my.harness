#!/bin/bash
# scripts/find-harness-repository.shを、ハーネスのリポジトリの中、worktree、ほかのリポジトリ、gitの外、補助のスクリプトの無いコピーで動かし、終了コードを確かめる。確かめる語を止める場所の見分けが、worktreeでも変わらず、補助のスクリプトが欠けても外として黙って通らないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-harness-repository.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/find-harness-repository.sh"

# スクリプトにフォルダーを渡して動かし、終了コードを出す。
# 引数：スクリプトのパス、渡すフォルダー
# 出力：終了コードの1行
# 戻り値：0
print_status() {
  "${BASH}" "$1" "$2" > /dev/null 2>&1
  printf '%s\n' "$?"
}

# 一時のリポジトリにスクリプトをコピーしてworktreeを作り、メインのクローンのスクリプトをworktreeで動かした終了コードを出す。
# 引数：ケースのフォルダー
# 出力：終了コードの1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_worktree_status() {
  if ! create_case_repository "$1" worktree > /dev/null \
    || ! mkdir -p "$1/project/scripts" \
    || ! cp "${SCRIPT}" "${TEST_DIRECTORY}/../scripts/print-main-worktree-path.sh" "$1/project/scripts/"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  print_status "$1/project/scripts/find-harness-repository.sh" "$1/worktree"
}

# print-main-worktree-path.shを置かないコピーを一時のリポジトリに作って動かし、終了コードと、決められない文の数を出す。補助のスクリプトが欠けたときに、外として黙って通さないことを確かめるためである。
# 引数：ケースのフォルダー
# 出力：「終了コード 文の数」の1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_missing_helper_result() {
  local output status
  if ! run_test_git "$1" init -q "$1/project" || ! mkdir -p "$1/project/scripts" \
    || ! cp "${SCRIPT}" "$1/project/scripts/"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  output="$("${BASH}" "$1/project/scripts/find-harness-repository.sh" "$1/project" 2>&1 > /dev/null)"
  status=$?
  printf '%s %s\n' "${status}" "$(printf '%s\n' "${output}" | grep -c '^find-harness-repository.sh: ')"
}

main() {
  local work_directory
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  # ケースは、渡すフォルダーの作り方（ハーネスのリポジトリ、worktree、ほかのリポジトリ）が1件ずつ違い、CONTRIBUTING.mdの節「テスト」がデータのファイルに分けると決めた判定の一覧ではないので、ここに書く。
  expect 'ハーネスのリポジトリの一番上を渡すと、0で終わる。' '0' "$(print_status "${SCRIPT}" "${TEST_DIRECTORY}/..")"
  expect 'ハーネスのリポジトリのサブフォルダーを渡すと、0で終わる。' '0' "$(print_status "${SCRIPT}" "${TEST_DIRECTORY}")"
  expect 'メインのクローンのスクリプトにworktreeを渡すと、0で終わる。' '0' \
    "$(print_worktree_status "${work_directory}/worktree-case")"
  create_case_repository "${work_directory}/other" git > /dev/null
  expect 'ほかのgitのリポジトリを渡すと、1で終わる。' '1' "$(print_status "${SCRIPT}" "${work_directory}/other/project")"
  mkdir -p "${work_directory}/outside"
  expect 'gitの外のフォルダーを渡すと、1で終わる。' '1' "$(print_status "${SCRIPT}" "${work_directory}/outside")"
  expect 'フォルダーを渡さないと、使い方の誤りの2で終わる。' '2' \
    "$("${BASH}" "${SCRIPT}" > /dev/null 2>&1; printf '%s' "$?")"
  expect 'print-main-worktree-path.shの無いコピーでは、決められない文を出し、2で終わる。' '2 1' \
    "$(print_missing_helper_result "${work_directory}/missing-helper")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
