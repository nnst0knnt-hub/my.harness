#!/bin/bash
# tests/print-command-without-trailing-redirect-case-list.tsvを読み、scripts/print-command-without-trailing-redirect.shの出力を確かめ、結果を出す。全体の最後の2>&1だけを外し、本文の途中の行末の2>&1を残すことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-command-without-trailing-redirect.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-command-without-trailing-redirect.sh"

main() {
  local description input expected command
  while IFS=$'\t' read -r description input expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    # 末尾の改行を比べられるよう、出力と期待の後ろに終了コードを付ける。
    command="$(printf '%b.' "${input}")" && command="${command%.}"
    [ "${expected}" != '=' ] || expected="${input}"
    expect "${description}" "$(printf '%b' "${expected}") 0" \
      "$("${BASH}" "${SCRIPT}" "${command}" 2> /dev/null; printf ' %s' "$?")"
  done < "${TEST_DIRECTORY}/print-command-without-trailing-redirect-case-list.tsv"
  expect '引数が無ければ、使い方の誤りの2で終わる。' '2' "$("${BASH}" "${SCRIPT}" > /dev/null 2>&1; printf '%s' "$?")"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
