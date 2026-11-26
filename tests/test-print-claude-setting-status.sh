#!/bin/bash
# tests/print-claude-setting-status-case-list.tsvを読み、scripts/print-claude-setting-status.shが出す行の状態と項目を確かめ、結果を出す。導入先の設定と、ハーネスの外の処理が足した設定のうち、保護を止める値と、保護を緩めるかサンドボックスの外で動く項目を、見逃さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-claude-setting-status.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-fake-command.sh
source "${TEST_DIRECTORY}/create-fake-command.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-claude-setting-status.sh"

# 1つの設定のファイルを、ケースの列の書き方で作る。
# 引数：作るファイルのパス、列の中身
# 出力：なし
# 戻り値：0
create_setting_file() {
  mkdir -p "$(dirname "$1")"
  case "$2" in
    -) ;;
    0) : > "$1" ;;
    !) printf '%s\n' '{}' > "$1" && chmod 000 "$1" ;;
    d) mkdir -p "$1" ;;
    *) printf '%s\n' "$2" > "$1" ;;
  esac
}

# スクリプトを動かし、行ごとの「状態の字:項目」を「;」でつないで出す。ファイルのパスは、短い名前に置き換える。
# 引数：ケースのフォルダー、作業フォルダー、メインの作業フォルダー（ほかの引数は、そのままスクリプトに渡す）
# 出力：結果の1行
# 戻り値：0
print_case_result() {
  local output
  output="$(env -u CLAUDE_CONFIG_DIR HOME="$1/home" PATH="${PATH}" "${BASH}" "${SCRIPT}" "${@:2}" 2> /dev/null)"
  output="${output//$1\/home\/.claude\/settings.json/pc}"
  output="${output//$2\/.claude\/settings.json/shared}"
  output="${output//$3\/.claude\/settings.local.json/local}"
  output="${output//$2\/.mcp.json/mcp}"
  printf '%s\n' "${output}" | awk -F '\t' '
    { mark = $1 == "働く" ? "o" : $1 == "働かない" ? "x" : $1 == "確かめる" ? "!" : "?"
      line = line separator mark ":" $2
      separator = ";" }
    END { print line }'
}

main() {
  local work_directory description pc shared local_setting mcp expected case_directory
  local case_number=0
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description pc shared local_setting mcp expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    case_directory="${work_directory}/case-${case_number}"
    create_setting_file "${case_directory}/home/.claude/settings.json" "${pc}"
    create_setting_file "${case_directory}/project/.claude/settings.json" "${shared}"
    create_setting_file "${case_directory}/project/.claude/settings.local.json" "${local_setting}"
    create_setting_file "${case_directory}/project/.mcp.json" "${mcp}"
    expect "${description}" "${expected}" "$(print_case_result "${case_directory}" \
      "${case_directory}/project" "${case_directory}/project")"
  done < "${TEST_DIRECTORY}/print-claude-setting-status-case-list.tsv"
  # worktreeでは、.claude/settings.local.jsonをメインの作業フォルダーから読み、.claude/settings.jsonを作業フォルダーから読む。
  case_directory="${work_directory}/worktree"
  create_setting_file "${case_directory}/work/.claude/settings.json" '{"apiKeyHelper": "work.sh"}'
  create_setting_file "${case_directory}/work/.claude/settings.local.json" '{"apiKeyHelper": "ignored.sh"}'
  create_setting_file "${case_directory}/main/.claude/settings.local.json" '{"disableAllHooks": true}'
  expect 'worktreeでは、.claude/settings.local.jsonをメインの作業フォルダーから読む。' \
    'x:localのdisableAllHooks（true）;!:sharedのapiKeyHelper（"work.sh"）' \
    "$(print_case_result "${case_directory}" "${case_directory}/work" "${case_directory}/main")"
  create_fake_command "${work_directory}/no-jq" linux jq
  expect 'jqが動かなければ、わからないにする。' '?:Claude Codeの設定（jqが動きません）' \
    "$(PATH="${work_directory}/no-jq/bin:${PATH}" print_case_result "${work_directory}/no-jq" \
      "${work_directory}/no-jq" "${work_directory}/no-jq")"
  expect '引数が足りなければ、使い方の誤りの2で終わる。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" > /dev/null 2>&1; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
