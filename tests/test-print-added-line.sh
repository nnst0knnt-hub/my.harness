#!/bin/bash
# tests/print-added-line-case-list.tsvを読み、scripts/print-added-line.shに差分を渡して出力を確かめ、結果を出す。読み方を変えても、足した行と場所を取りこぼさず、消した行とマージで親から来た行を出さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-added-line.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-added-line.sh"

# 差分を渡してスクリプトを動かし、出力を1行にまとめて出す。
# 引数：printfの%bの形で書いた差分
# 出力：タブを空白に変え、行を「|」でつないだ出力の1行（何も出さなければ「-」）
# 戻り値：0
print_case_result() {
  local output
  output="$(printf '%b' "$1" | "${BASH}" "${SCRIPT}" | tr '\t' ' ')"
  if [ -z "${output}" ]; then
    output='-'
  fi
  printf '%s\n' "${output}" | paste -s -d '|' -
}

main() {
  local description diff expected
  while IFS=$'\t' read -r description diff expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    expect "${description}" "${expected}" "$(print_case_result "${diff}")"
  done < "${TEST_DIRECTORY}/print-added-line-case-list.tsv"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
