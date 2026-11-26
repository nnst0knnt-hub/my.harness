#!/bin/bash
# tests/find-missing-claude-setting-case-list.tsvを読み、scripts/find-missing-claude-setting.shの出力と終了コードを確かめ、結果を出す。PCの設定に、勧める設定のうち無いものを見逃さず、ほかの項目を足した設定を誤って出さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-missing-claude-setting.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/find-missing-claude-setting.sh"
readonly RECOMMENDED_SETTING='{"top": {"list": ["x", "<ハーネスの場所>/y"], "flag": true, "off": false, "nested": {"value": "z"}}}'

# 1つのケースの設定のファイルを作ってスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー、設定のファイルの中身、ハーネスの場所
# 出力：標準出力の行を「;」でつないだものと、終了コードを空白で区切った1行
# 戻り値：0
print_case_result() {
  local output status
  mkdir -p "$1"
  printf '%s\n' "${RECOMMENDED_SETTING}" > "$1/recommended.json"
  case "$2" in
    -) ;;
    !) printf '%s\n' '{}' > "$1/settings.json" && chmod 000 "$1/settings.json" ;;
    *) printf '%s\n' "${2//ROOT/$3}" > "$1/settings.json" ;;
  esac
  output="$("${BASH}" "${SCRIPT}" "$1/settings.json" "$1/recommended.json" "$3" 2> /dev/null)"
  status=$?
  output="${output//$3/ROOT}"
  output="${output:-なし}"
  printf '%s %s\n' "${output//$'\n'/;}" "${status}"
}

main() {
  local work_directory description setting expected case_number=0 output
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description setting expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" "$(print_case_result \
      "${work_directory}/case-${case_number}" "${setting}" "${work_directory}/harness")"
  done < "${TEST_DIRECTORY}/find-missing-claude-setting-case-list.tsv"
  # 実際の勧める設定のファイルが読めることを、置き換えたものと比べて確かめる。
  output="$(sed "s|<ハーネスの場所>|${work_directory}/harness|g" \
    "${TEST_DIRECTORY}/../data/recommended-claude-setting.json")"
  printf '%s\n' "${output}" > "${work_directory}/real-settings.json"
  expect '実際の勧める設定を、ハーネスの場所を置き換えて書けば、0で終わる。' '0' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}/real-settings.json" \
      "${TEST_DIRECTORY}/../data/recommended-claude-setting.json" "${work_directory}/harness" \
      > /dev/null 2>&1; printf '%s' "$?")"
  expect '設定のファイルが無く、勧める設定のファイルも読めなければ、1で終わる。' '1' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}/missing.json" "${work_directory}/missing-recommended.json" \
      "${work_directory}/harness" > /dev/null 2>&1; printf '%s' "$?")"
  expect '引数が足りなければ、使い方の誤りの2で終わる。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" > /dev/null 2>&1; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
