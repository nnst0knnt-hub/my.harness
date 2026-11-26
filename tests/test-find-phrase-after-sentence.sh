#!/bin/bash
# tests/find-phrase-after-sentence-case-list.tsvを読み、scripts/find-phrase-after-sentence.shの終了コードと報告の行を確かめ、結果を出す。find-phrase-after-sentence.shを変えても、判定が変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-phrase-after-sentence.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly LINTER="${TEST_DIRECTORY}/../scripts/find-phrase-after-sentence.sh"

main() {
  local work_directory
  local description
  local content
  local expected_status
  local expected_line
  work_directory="$(mktemp -d)"
  while IFS=$'\t' read -r description content expected_status expected_line; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    expect "${description}" "${expected_status} ${expected_line}" \
      "$(print_file_case_result "${LINTER}" "${work_directory}/case.md" "${content}")"
  done < "${TEST_DIRECTORY}/find-phrase-after-sentence-case-list.tsv"
  "${BASH}" "${LINTER}" > /dev/null 2>&1
  expect 'ファイルを渡さないと、使い方の誤りで終わる。' '2' "$?"
  "${BASH}" "${LINTER}" "${work_directory}/missing.md" > /dev/null 2>&1
  expect '無いファイルを渡すと、使い方の誤りで終わる。' '2' "$?"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
