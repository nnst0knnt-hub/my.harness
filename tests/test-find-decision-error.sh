#!/bin/bash
# tests/find-decision-error-case-list.tsvと字数の境界のケースで、linters/find-decision-error.shの終了コードと報告の行を確かめ、結果を出す。find-decision-error.shを変えても、判定が変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-decision-error.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly LINTER="${TEST_DIRECTORY}/../linters/find-decision-error.sh"

# 字数の境界を確かめる。上限は改行を含めて数えるので、1,499字と改行で通り、1,500字と改行で止まる。
# 引数：作るファイルのパス
# 出力：ok・ngの行
# 戻り値：0
expect_character_limit() {
  local characters
  characters="$(printf '%1499s' '' | LC_ALL=C sed 's/ /あ/g')"
  printf '%s\n' "${characters}" > "$1"
  "${BASH}" "${LINTER}" "$1" 2> /dev/null
  expect '改行を含めて1,500字の記録を渡すと、通す。' 0 "$?"
  printf '%sあ\n' "${characters}" > "$1"
  "${BASH}" "${LINTER}" "$1" 2> /dev/null
  expect '改行を含めて1,501字の記録を渡すと、止める。' 1 "$?"
  printf '%s\n\n## 出典\n\n- %s\n' "${characters}" "${characters}" > "$1"
  "${BASH}" "${LINTER}" "$1" 2> /dev/null
  expect '出典の前が1,501字の記録を渡すと、止める。' 1 "$?"
  printf '%s\n## 出典\n\n- %s\n' "${characters}" "${characters}" > "$1"
  "${BASH}" "${LINTER}" "$1" 2> /dev/null
  expect '出典の節は数えないので、出典の前が1,500字の記録を渡すと、通す。' 0 "$?"
}

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
  done < "${TEST_DIRECTORY}/find-decision-error-case-list.tsv"
  rm -f "${work_directory}/case.md"
  expect_character_limit "${work_directory}/case.md"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
