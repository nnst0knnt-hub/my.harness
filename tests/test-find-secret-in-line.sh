#!/bin/bash
# tests/find-secret-in-line-case-list.tsvを読み、scripts/find-secret-in-line.shに行を渡して、終了コードと報告の数を確かめ、結果を出す。比べ方か秘密情報のパターンの一覧を変えても、次の2つが変わらないことを確かめるためである。秘密情報を見逃さないこと、ふつうの行とファイルで止めないことである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-secret-in-line.shか秘密情報のパターンの一覧を変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/find-secret-in-line.sh"

# 1つのケースの行を作ってスクリプトに渡し、結果を出す。
# 引数：種類、渡す行
# 出力：「終了コード 報告の数」の1行
# 戻り値：0
print_case_result() {
  local line output status
  line="$(print_repeated_text "$2")"
  if [ "$1" = 'content' ]; then
    line="app.txt:1"$'\t'"${line}"
  fi
  output="$(printf '%s\n' "${line}" | "${BASH}" "${SCRIPT}" "$1" 2>&1 > /dev/null)"
  status=$?
  printf '%s %s\n' "${status}" "$(printf '%s\n' "${output}" | grep -c '秘密情報（')"
}

# スクリプトを一時のフォルダーにコピーし、そこの一覧を中身に変えて動かし、終了コードを出す。一覧が壊れていても、黙って通さないことを確かめるためである。
# 引数：一時のフォルダー、printfの%bの形で書いた一覧の中身（「-」は置かない）
# 出力：終了コードの1行
# 戻り値：0
print_list_case_result() {
  rm -rf "$1" && mkdir -p "$1/scripts" "$1/data" && cp "${SCRIPT}" "$1/scripts/"
  if [ "$2" != '-' ]; then
    printf '%b' "$2" > "$1/data/secret-pattern-list.txt"
  fi
  printf 'app.txt:1\tx\n' | "${BASH}" "$1/scripts/find-secret-in-line.sh" content 2> /dev/null
  printf '%s\n' "$?"
}

main() {
  local description kind line expected output work_directory
  while IFS=$'\t' read -r description kind line expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    expect "${description}" "${expected}" "$(print_case_result "${kind}" "${line}")"
  done < "${TEST_DIRECTORY}/find-secret-in-line-case-list.tsv"
  output="$(printf 'config/app.txt:2\t%s\n' "$(print_repeated_text 'token: ghp_[a*36]')" |
    "${BASH}" "${SCRIPT}" content 2>&1)"
  expect '見つけたときは、場所と種類を示し、値を出さない。' '1 0' \
    "$(printf '%s\n' "${output}" | grep -c '^find-secret-in-line.sh: config/app\.txt:2: 秘密情報（GitHub') $(printf '%s\n' "${output}" | grep -c 'aaaaaaaaaa')"
  work_directory="$(mktemp -d)"
  expect '一覧が無いと、止める。' '2' "$(print_list_case_result "${work_directory}" '-')"
  expect '一覧のパターンをgrepが読めないと、止める。' '2' "$(print_list_case_result "${work_directory}" 'content\tname\t(\n')"
  expect '一覧に知らない種類の行があると、止める。' '2' "$(print_list_case_result "${work_directory}" 'content\tname\tx\npath\tname\tx\n')"
  expect '一覧に渡した種類の行が無いと、止める。' '2' "$(print_list_case_result "${work_directory}" 'file-name\tname\tx\n')"
  expect '一覧の最後の行に改行が無くても、その行で止める。' '1' "$(print_list_case_result "${work_directory}" 'content\tname\tx')"
  rm -rf "${work_directory}"
  expect '種類を渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" < /dev/null 2> /dev/null; printf '%s' "$?")"
  expect '知らない種類を渡すと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" path < /dev/null 2> /dev/null; printf '%s' "$?")"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
