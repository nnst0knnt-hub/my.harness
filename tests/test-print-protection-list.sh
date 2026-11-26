#!/bin/bash
# tests/print-protection-list-case-list.tsvを読み、scripts/print-protection-list.shの終了コードと出した一覧を確かめ、結果を出す。読み方を変えても、既定の一覧を外さず、足した値を読み、読めない設定で黙って進まないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-protection-list.shか既定の一覧を変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-protection-list.sh"

# 導入先の.harness/configを作ってスクリプトを動かし、結果を出す。
# 引数：導入先のフォルダー、printfの%bの形で書いた.harness/configの中身（「-」は置かない、「!」は読めないファイル、「@」は文字デバイスの/dev/nullを指すシンボリックリンク）、一覧のキー
# 出力：「終了コード 一覧」の1行（一覧は、出した行を空白でつないだもの、何も出さなければ「-」）
# 戻り値：0
print_case_result() {
  local config="$1/.harness/config" output status
  rm -rf "$1/.harness"
  mkdir -p "$1/.harness"
  case "$2" in
    '-') rm -rf "$1/.harness" ;;
    '!') : > "${config}" && chmod 000 "${config}" ;;
    # サンドボックスが無い.harness/configの場所に置く文字デバイスは作れないので、同じ-cに当たる形で試す。
    '@') ln -s /dev/null "${config}" ;;
    *) printf '%b' "$2" > "${config}" ;;
  esac
  output="$("${BASH}" "${SCRIPT}" "$1" "$3" 2> /dev/null)"
  status=$?
  if [ -z "${output}" ]; then
    output='-'
  fi
  printf '%s %s\n' "${status}" "$(printf '%s\n' "${output}" | paste -s -d ' ' -)"
}

main() {
  local work_directory description content key expected_status expected_list
  work_directory="$(mktemp -d)"
  while IFS=$'\t' read -r description content key expected_status expected_list; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    expect "${description}" "${expected_status} ${expected_list}" \
      "$(print_case_result "${work_directory}" "${content}" "${key}")"
  done < "${TEST_DIRECTORY}/print-protection-list-case-list.tsv"
  print_case_result "${work_directory}" '@' branch > /dev/null
  expect '.harness/configが文字デバイスなら、理由の文で、Claude Codeの外で動かすよう示す。' '1' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" branch 2>&1 > /dev/null | grep -c 'Claude Codeの外のシェルで動かして')"
  expect 'フォルダーとキーを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" 2> /dev/null; printf '%s' "$?")"
  expect '知らないキーを渡すと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" other 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
