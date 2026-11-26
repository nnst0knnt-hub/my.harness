#!/bin/bash
# tests/expect-case-list.tsvを読み、expect.shの関数の戻り値を確かめ、結果を出す。expect.shを変えても、比べ方が変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もexpect.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"

# 1つのケースの関数を、このテストのケースの数と失敗の数を変えないよう、0件から別のシェルで動かす。
# 引数：関数（expect、summary、expect_then_summaryのどれか）、引数1、引数2
# 出力：最後に動かした関数の戻り値
# 戻り値：0
print_case_status() {
  (
    case_count=0
    failure_count=0
    case "$1" in
      expect) expect '確かめる値' "$2" "$3" > /dev/null ;;
      summary)
        case_count="$2"
        failure_count="$3"
        print_expect_summary > /dev/null
        ;;
      expect_then_summary)
        expect '確かめる値' "$2" "$3" > /dev/null
        print_expect_summary > /dev/null
        ;;
    esac
    printf '%s\n' "$?"
  )
}

main() {
  local description
  local function_name
  local first
  local second
  local expected
  local actual
  local own_failure_count=0
  while IFS=$'\t' read -r description function_name first second expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    actual="$(print_case_status "${function_name}" "${first}" "${second}")"
    expect "${description}" "${expected}" "${actual}"
    # 確かめる相手のexpectが壊れても気づけるよう、成否はexpectに頼らずに数える。
    if [ "${expected}" != "${actual}" ]; then
      own_failure_count=$((own_failure_count + 1))
    fi
  done < "${TEST_DIRECTORY}/expect-case-list.tsv"
  print_expect_summary
  if [ "${own_failure_count}" -gt 0 ]; then
    exit 1
  fi
  exit 0
}

main "$@"
