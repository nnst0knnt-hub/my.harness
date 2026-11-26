#!/bin/bash
# tests/print-markdown-body-case-list.tsvを読み、scripts/print-markdown-body.shの終了コードと出した行の番号を確かめ、結果を出す。本文の読み方を変えても、どの行を本文とするかが変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-markdown-body.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-markdown-body.sh"

# 中身のファイルを作ってスクリプトに渡し、終了コードと、標準出力の行の番号を出す。
# 引数：作るファイルのパス、printfの%bの形で書いた中身（「-」は空のファイル、「!」は読めないファイル）
# 出力：「終了コード 行番号…」の1行（行が無ければ行番号は「-」）
# 戻り値：0
print_body_case_result() {
  local file="$1"
  local content="$2"
  local output
  local status
  local lines
  rm -f "${file}"
  case "${content}" in
    '-') : > "${file}" ;;
    '!') : > "${file}" && chmod 000 "${file}" ;;
    *) printf '%b' "${content}" > "${file}" ;;
  esac
  output="$("${BASH}" "${SCRIPT}" "${file}" 2> /dev/null)"
  status=$?
  lines="$(printf '%s' "${output}" | awk -F '\t' 'NF { printf "%s%s", separator, $1; separator = " " }')"
  printf '%s %s\n' "${status}" "${lines:--}"
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
      "$(print_body_case_result "${work_directory}/case.md" "${content}")"
  done < "${TEST_DIRECTORY}/print-markdown-body-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
