#!/bin/bash
# tests/find-unverified-or-pc-specific-word-case-list.tsvを読み、linters/find-unverified-or-pc-specific-word.shの終了コードと報告の行を確かめ、結果を出す。find-unverified-or-pc-specific-word.shか語の一覧を変えても、判定が変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-unverified-or-pc-specific-word.shか語の一覧を変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly LINTER="${TEST_DIRECTORY}/../linters/find-unverified-or-pc-specific-word.sh"

# linterを一時のフォルダーにコピーし、そこの語の一覧を中身に変えて、ファイルを渡して動かす。一覧が壊れていても黙って通さないことと、除く形を確かめるためである。
# 引数：一時のフォルダー、printfの%bの形で書いた一覧の中身（「-」は置かない）、printfの%bの形で書いたファイルの中身
# 出力：「終了コード 行番号…」の1行
# 戻り値：0
print_list_case_result() {
  rm -rf "$1" && mkdir -p "$1/linters" "$1/scripts" "$1/data"
  cp "${LINTER}" "$1/linters/"
  cp "${TEST_DIRECTORY}/../scripts/print-markdown-body.sh" "$1/scripts/"
  if [ "$2" != '-' ]; then
    printf '%b' "$2" > "$1/data/unverified-or-pc-specific-word-list.txt"
  fi
  print_file_case_result "$1/linters/find-unverified-or-pc-specific-word.sh" "$1/case.md" "$3"
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
  done < "${TEST_DIRECTORY}/find-unverified-or-pc-specific-word-case-list.tsv"
  "${BASH}" "${LINTER}" > /dev/null 2>&1
  expect 'ファイルを渡さないと、使い方の誤りで終わる。' '2' "$?"
  "${BASH}" "${LINTER}" "${work_directory}/missing.md" > /dev/null 2>&1
  expect '無いファイルを渡すと、使い方の誤りで終わる。' '2' "$?"
  expect '一覧が無いと、使い方の誤りで終わる。' '2 -' \
    "$(print_list_case_result "${work_directory}/copy" '-' 'a\n')"
  expect '一覧が空だと、使い方の誤りで終わる。' '2 -' \
    "$(print_list_case_result "${work_directory}/copy" '' 'a\n')"
  expect '除く形に当たる所は、語を探す前に消すので、通す。' '0 -' \
    "$(print_list_case_result "${work_directory}/copy" '語\t代わり\t語句\n' '語句を書く。\n')"
  expect '除く形と同じ行の語は、止める。' '1 1' \
    "$(print_list_case_result "${work_directory}/copy" '語\t代わり\t語句\n' '語句と語を書く。\n')"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
